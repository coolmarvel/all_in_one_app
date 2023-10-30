// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../../openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IERC20MultiFreeCapable is IERC20 {
    event CapChanged(bytes32 indexed game, bytes32 indexed column, uint amount);

    function periodCap(bytes32 game) external view returns (uint);

    function periodUserCap(bytes32 game) external view returns (uint);

    function remainAmount(bytes32 game) external view returns (uint);

    function capAppliedTime(bytes32 game) external view returns (uint);

    function getUserStatus(
        bytes32 game,
        address account
    ) external view returns (uint endTime, uint amount);
}
