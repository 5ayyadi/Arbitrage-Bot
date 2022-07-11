// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IERC20.sol";
import "hardhat/console.sol";


contract Price {
    address public WETH;

    constructor(address _WETH) {
        WETH = _WETH;
    }

    function ethPrice
    (address[] calldata _pairs)
    external view returns (uint){
        address stable_coin;
        uint8 decimal;
        uint denominator = 0;
        uint numerator = 0;
        uint reserveStable;
        uint reserveETH;
        for (uint256 i = 0; i < _pairs.length; i++) {
            stable_coin = IUniswapV2Pair(_pairs[i]).token0() == WETH
            ? IUniswapV2Pair(_pairs[i]).token1()
            : IUniswapV2Pair(_pairs[i]).token0();

            decimal = IERC20(stable_coin).decimals();
            

            if (WETH < stable_coin){
                (reserveETH, reserveStable, ) = IUniswapV2Pair(_pairs[i]).getReserves();
            }
            else {
                (reserveStable, reserveETH, ) = IUniswapV2Pair(_pairs[i]).getReserves();
            }
            

            reserveStable *= (10 ** (18 - decimal));
            
            numerator += reserveStable * (10 ** 3);
            denominator += reserveETH;
        }
        return numerator / denominator;
    }
}