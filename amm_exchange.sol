// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import all dependencies and interfaces:
// import "../interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IERC20.sol";

// import "../libraries/safeTransfer.sol";



contract UniswapAmm  {

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // fetches and sorts the reserves for a pair
    //function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function getReserves(
        address pair,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair)
            .getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    //Does The Swap on pair
    function _swap(
        address pair,
        uint256 amountOut,
        address tokenA,
        address tokenB,
        address _to
    ) internal {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 amount0Out, uint256 amount1Out) = tokenA == token0
            ? (uint256(0), amountOut)
            : (amountOut, uint256(0));
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, _to, new bytes(0));
    }

    function SwapTokensSupportingFee(
        uint16 lpFee, address _pair,
        address tokenA,
        address tokenB,
        address to
    ) 
    internal 
    returns (uint256 amountOutput) 
    {
        (address token0, ) = sortTokens(tokenA, tokenB);
        // IUniswapV2Pair pair = IUniswapV2Pair(_pair);
        // uint256 intialBalance = IERC20(tokenB).balanceOf(to);
        uint256 amountInput;
        {
            // scope to avoid stack too deep errors
            (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_pair).getReserves();
            (uint256 reserveInput, uint256 reserveOutput) = tokenA == token0
                ? (reserve0, reserve1)
                : (reserve1, reserve0);
            amountInput =
                IERC20(tokenA).balanceOf(_pair) -
                reserveInput;
            amountOutput = getAmountOut(
                amountInput,
                reserveInput,
                reserveOutput,
                lpFee
            );
        }
        (uint256 amount0Out, uint256 amount1Out) = tokenA == token0
            ? (uint256(0), amountOutput)
            : (amountOutput, uint256(0));
            
        IUniswapV2Pair(_pair).swap(amount0Out, amount1Out, to, new bytes(0));
        // return IERC20(tokenB).balanceOf(to) - intialBalance;
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint16 lpFee
    ) internal pure returns (uint256 amountOut) {
        require(
            reserveIn > 10 && reserveOut > 10,
            "Bad Pair Found, Where the hell is its LIQUIDITY"
        );
        require(amountIn > 0, "Why There is no input in this route");
        uint256 amountInWithFee = amountIn * lpFee;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 10000) + amountInWithFee;
        amountOut = numerator / denominator;
        require(amountOut > 0, "You What Happend To Tokens no amount OUT");
    }


}
