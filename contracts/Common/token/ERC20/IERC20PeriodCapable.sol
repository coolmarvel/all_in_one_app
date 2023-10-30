// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../../openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IERC20PeriodCapable is IERC20 {
    event CapChanged(bytes32 column, uint256 amount);

    // function periodCap() external view returns (uint256);
    // function periodUserCap() external view returns (uint256);
    function remainAmount() external view returns (uint256);

    function getUserStatus(
        address account
    ) external view returns (uint256 endTime, uint256 amount);
}
