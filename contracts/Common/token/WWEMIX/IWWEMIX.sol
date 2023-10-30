// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "../../../openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IWWEMIX is IERC20 {
    /* =========== FUNCTIONS ===========*/

    function deposit() external payable;

    function withdraw(uint256 _amount) external;

    /* =========== EVENTS ===========*/

    event Deposit(address indexed dst, uint256 amount);
    event Withdraw(address indexed src, uint256 amount);
}
