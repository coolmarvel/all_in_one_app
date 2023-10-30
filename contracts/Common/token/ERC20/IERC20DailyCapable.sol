// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../../../openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface IERC20DailyCapable is IERC20 {
    event CapChanged(bytes32 column, uint amount);

    function dailyCap() external view returns (uint);

    function dailyUserCap() external view returns (uint);

    function remainAmount() external view returns (uint);

    function getUserStatus(
        address account
    ) external view returns (uint endTime, uint amount);
}
