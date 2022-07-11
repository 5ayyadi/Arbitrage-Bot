// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IERC20.sol";

contract Price {
    address public WETH;

    constructor(address _WETH) {
        WETH = _WETH;
    }

    function ethPrice
    (address[] calldata _pairs)
    external view returns (uint){
        address stable_coin;
        IUniswapV2Pair pair;
        uint8 decimal;
        uint denominator;
        uint numerator;
        uint reserveStable;
        uint reserveETH;
        for (uint256 i = 0; i < _pairs.length; i++) {
            pair = IUniswapV2Pair(_pairs[i]);
            stable_coin = pair.token0 == WETH
            ? pair.token1
            : pair.token0;

            decimal = IERC20(stable_coin).decimals();
            

            if (WETH < stable_coin){
                (reserveETH, reserveStable, ) = pair.getReserves();
            }
            else {
                (reserveStable, reserveETH, ) = pair.getReserves();
            }

            reserveStable *= (10 ** (18 - decimal));
            
            numerator += reserveETH * (10 ** 3);
            denominator += reserveStable;
        }
        return numerator / denominator;
    }
}