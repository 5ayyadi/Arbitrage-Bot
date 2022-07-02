// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IWETH is IERC20 {
    function withdraw(uint256 amount) external returns (uint256);

    function deposit() external payable returns (uint256);
}
