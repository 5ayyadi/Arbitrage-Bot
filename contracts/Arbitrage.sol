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
    struct BestPair {
        address pair;
        uint256 amount;
        uint16 fee;
    }

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
        require(
            _percentage < 1000 && _percentage > 0,
            "Percentage must be between 0 and 1000"
        );
        gasPercent = _percentage;
    }

    function addFactories(
        address[] calldata _factories,
        uint16[] calldata _fees
    ) public onlyOwner {
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
    function swapOnWETH(
        address _stableCoin,
        uint256 _amountIn,
        uint256 _gas
    ) external {
        // (address firstPair, uint256 middleAmount, uint16 firstFee)
        BestPair memory first_best_pair = _bestPair(
            WETH,
            _stableCoin,
            _amountIn
        );
        // (address secondPair, uint256 amountOut, uint16 secondFee)
        BestPair memory second_best_pair = _bestPair(
            _stableCoin,
            WETH,
            first_best_pair.amount
        );
        require(
            second_best_pair.amount > _amountIn,
            "Amount Out less than amount in"
        );
        uint256 difference = second_best_pair.amount - _amountIn;
        // spend 50% of difference as gas.
        uint256 gas = (gasPercent * difference) / 1000;
        require(gas >= _gas, "Gas is higher than difference, no benefits.");
        // call _swap function
        SwapTokensSupportingFee(
            first_best_pair.fee,
            first_best_pair.pair,
            WETH,
            _stableCoin,
            address(this)
        );
        SwapTokensSupportingFee(
            second_best_pair.fee,
            second_best_pair.pair,
            _stableCoin,
            WETH,
            address(this)
        );
        emit Swap(WETH, _stableCoin, _amountIn, second_best_pair.amount);
    }

    // gas must be passed in dollars.
    // TODO: Fix don't use a pair twice.
    function swapOnStableCoin(
        address _tokenIn,
        address _tokenOut,
        address _midToken,
        uint256 _amountIn,
        uint256 _gas
    ) external {
        // find best pair between token0 and native token
        BestPair memory first_best_pair = _bestPair(_tokenIn, _midToken, _amountIn);
        BestPair memory second_best_pair = _bestPair(
            _midToken,
            _tokenOut,
            first_best_pair.amount
        );

        require(
            second_best_pair.amount > _amountIn,
            "Amount Out less than amount in"
        );
        // calculate difference in native token.
        uint256 difference = second_best_pair.amount - _amountIn;
        // spend 50% of difference as gas.
        uint256 gas = (gasPercent * difference) / 1000;
        require(gas >= _gas, "Gas is higher than difference, no benefits.");

        // call _swap function
        SwapTokensSupportingFee(
            first_best_pair.fee,
            first_best_pair.pair,
            _tokenIn,
            _midToken,
            address(this)
        );
        SwapTokensSupportingFee(
            second_best_pair.fee,
            second_best_pair.pair,
            _midToken,
            _tokenOut,
            address(this)
        );

        emit Swap(_tokenIn, _tokenOut, _amountIn, second_best_pair.amount);
    }

    function _bestPair(
        address _token0,
        address _token1,
        uint256 _amountIn
    ) internal view returns (BestPair memory) {
        uint256 bestAmount = uint256(0);
        address bestPair = address(0);
        uint16 bestFee = 0;
        uint256 _reserve0;
        uint256 _reserve1;
        address pair;
        address bestfactory;
        // uint16 fee;
        uint256 _aOut;
        for (uint256 i = 0; i < factories.length; i++) {
            pair = IUniswapV2Factory(factories[i]).getPair(_token0, _token1);
            // fee = getFee(factories[i]);
            uint256 _aIn = (_amountIn * getFee(factories[i])) / (10**4);
            console.log(pair);
            if (pair == address(0)) {
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
                // console.log(pair);
                bestAmount = _aOut;
                bestPair = pair;
                bestFee = getFee(factories[i]);
                bestfactory = factories[i];
            }
        }
        // console.log(_token0, _token1, bestPair, bestAmount);
        return BestPair(bestPair, bestAmount, bestFee);
    }

    function _calculate_amount_out(
        uint256 _reserve0,
        uint256 _reserve1,
        uint256 _amountIn
    ) internal pure returns (uint256) {
        uint256 K = _reserve0 * _reserve1;
        return _reserve1 - (K / (_reserve0 + _amountIn));
    }

    function _calculate_amount_out_fee(
        uint16 fee,
        uint256 _reserve0,
        uint256 _reserve1,
        uint256 _amountIn
    ) internal pure returns (uint256) {
        return
            _calculate_amount_out(
                _reserve0,
                _reserve1,
                ((_amountIn * fee) / 10**4)
            );
    }

    function Withdraw(address _token) public onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (balance > 0) {
            require(IERC20(_token).transfer(owner(), balance));
        }
    }

    function find_best_result_with_eth(
        address[] calldata tokens,
        uint256 amountIn
    ) public view returns (BestPair[] memory) {
        return find_best_result(tokens, WETH, amountIn);
    }

    function find_best_result(
        address[] memory tokens,
        address tokenIn,
        uint256 amountIn
    ) public view returns (BestPair[] memory best_pairs) {
        best_pairs = new BestPair[](tokens.length);
        for (uint256 j = 0; j < tokens.length; j++) {
            best_pairs[j] = _bestPair(tokenIn, tokens[j], amountIn);
        }
        return best_pairs;
    }
}
