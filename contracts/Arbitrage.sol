// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IWETH.sol";
import "../libraries/Ownable.sol";
import "hardhat/console.sol";


import "./amm_exchange.sol";


contract Arbitrage is Ownable, UniswapAmm {
    uint16 public gasPercent;
    address[] public factories;
    mapping(address => uint16) lpFees;

    address public WETH;

    event Swap(
        address indexed fromToken,
        address indexed toToken,
        uint256 amountIn,
        uint256 amountOut
    );

    constructor(address _WETH) {
        WETH = _WETH;
    }

    function setGasPercent(uint16 _percentage) external onlyOwner {
        require(_percentage < 1000 && _percentage >0, "Percentage must be between 0 and 1000");
        gasPercent = _percentage;
    }

    function addFactories(address[] calldata _factories, uint16[] calldata _fees)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _factories.length; i++) {
            factories.push(_factories[i]);
            lpFees[_factories[i]] = _fees[i];
        }
    }

    function allFactories() public view returns (address[] memory) {
        return factories;
    }

    function getFee(address _factory) public view returns (uint16) {
        return lpFees[_factory];
    }
        
    /// @dev this function uses stable coin as middle token 
    /// to increase WETH. (WETH -> Stable -> WETH)
    function swapUsingStableCoin(address _stableCoin, uint256 _amountIn, uint256 _gas)
        external
    {
        (address firstPair, uint256 middleAmount, uint16 firstFee) = _bestPair(
            WETH,
            _stableCoin,
            _amountIn
        );
        (address secondPair, uint256 amountOut, uint16 secondFee) = _bestPair(
            _stableCoin,
            WETH,
            middleAmount
        );
        require(amountOut > _amountIn, "Amount Out less than amount in");
         uint256 difference = amountOut - _amountIn;
        // spend 50% of difference as gas.
        uint256 gas = (gasPercent * difference) / 1000;
        require(gas >= _gas, "Gas is higher than difference, no benefits.");
        // call _swap function
        SwapTokensSupportingFee(firstFee, firstPair, WETH, _stableCoin, address(this));
        SwapTokensSupportingFee(secondFee, secondPair, _stableCoin, WETH, address(this));
        emit Swap(WETH, _stableCoin, _amountIn, amountOut);
    }

    // gas must be passed in dollars.
    // TODO: Fix don't use a pairs twice.
    function swapUsingEth(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _gas
    ) external {
        // find best pair between token0 and native token
        (address firstPair, uint256 middleAmount, uint16 firstFee) = _bestPair(
            _tokenIn,
            WETH,
            _amountIn
        );
        (address secondPair, uint256 amountOut, uint16 secondFee) = _bestPair(
            WETH,
            _tokenOut,
            middleAmount
        );
        require(amountOut > _amountIn, "Amount Out less than amount in");
        // calculate difference in native token.
        uint256 difference = amountOut - _amountIn;
        // spend 50% of difference as gas.
        uint256 gas = (gasPercent * difference) / 1000;
        require(gas >= _gas, "Gas is higher than difference, no benefits.");

        // call _swap function
        SwapTokensSupportingFee(firstFee, firstPair, _tokenIn, WETH, address(this));
        SwapTokensSupportingFee(secondFee, secondPair, WETH, _tokenOut, address(this));

        emit Swap(_tokenIn, _tokenOut, _amountIn, amountOut);
    }

    function _bestPair(
        address _token0,
        address _token1,
        uint256 _amountIn
    ) internal view returns (address, uint256,uint16) {
        uint256 bestAmount = uint256(0);
        address bestPair = address(0);
        uint16 bestFee = 0;
        uint256 _reserve0;
        uint256 _reserve1;
        address pair;
        // uint16 fee;
        uint256 _aOut;
        for (uint256 i = 0; i < factories.length; i++) {
            pair = IUniswapV2Factory(factories[i]).getPair(_token0, _token1);
            // fee = getFee(factories[i]);
            uint256 _aIn = (_amountIn * getFee(factories[i])) / (10**4);
            if (pair == address(0)){
                continue;
            }
            (_reserve0, _reserve1, ) = IUniswapV2Pair(pair).getReserves();
            if (_token0 == IUniswapV2Pair(pair).token0()) {
                /// @dev should always pass starting token as first parameter
                _aOut = _calculate_amount_out(_reserve0, _reserve1, _aIn);
            } else {
                _aOut = _calculate_amount_out(_reserve1, _reserve0, _aIn);
            }
            if (_aOut >= bestAmount) {
                console.log(pair);
                bestAmount = _aOut;
                bestPair = pair;
                bestFee = getFee(factories[i]);
            }
        }
        return (bestPair, bestAmount, bestFee);
    }

    function _calculate_amount_out(
        uint256 _reserve0,
        uint256 _reserve1,
        uint256 _amountIn
    ) internal pure returns (uint256) {
        uint256 K = _reserve0 * _reserve1;
        return _reserve1 - (K / (_reserve0 + _amountIn));
    }

    function Withdraw(address _token) public onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (balance > 0) {
            require(IERC20(_token).transfer(owner(), balance));
        }
    }

}
