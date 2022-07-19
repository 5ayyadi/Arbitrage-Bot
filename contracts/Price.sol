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

    /// @notice Performs Weighted Avg on pairs
    /// @dev token decimals can be different but ETH is always 18 so we added reserveStable *= (10**(18 - decimal));
    /// @param _pairs list of pairs of ETH - StableCoin
    /// @return  EthPrice
    function ethPrice(address[] calldata _pairs)
        external
        view
        returns (uint256)
    {
        address stable_coin;
        uint8 decimal;
        uint256 denominator = 0;
        uint256 numerator = 0;
        uint256 reserveStable;
        uint256 reserveETH;
        for (uint256 i = 0; i < _pairs.length; i++) {
            stable_coin = IUniswapV2Pair(_pairs[i]).token0() == WETH
                ? IUniswapV2Pair(_pairs[i]).token1()
                : IUniswapV2Pair(_pairs[i]).token0();

            decimal = IERC20(stable_coin).decimals();
            if (WETH < stable_coin) {
                (reserveETH, reserveStable, ) = IUniswapV2Pair(_pairs[i])
                    .getReserves();
            } else {
                (reserveStable, reserveETH, ) = IUniswapV2Pair(_pairs[i])
                    .getReserves();
            }

            reserveStable *= (10**(18 - decimal));

            numerator += reserveStable * (10**3);
            denominator += reserveETH;
        }
        return numerator / denominator;
    }
}
