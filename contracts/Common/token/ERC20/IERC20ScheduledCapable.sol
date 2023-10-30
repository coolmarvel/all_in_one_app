// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../../../openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IERC20ScheduledCapable is IERC20 {
    event CapChanged(bytes32 column, uint amount);

    // function totalStage() external view returns (uint);
    function getSchedule(
        uint index
    ) external view returns (uint stage, uint cap, uint userCap);

    function periodCap() external view returns (uint);

    function periodUserCap() external view returns (uint);

    function remainAmount() external view returns (uint);

    function getUserStatus(
        address account
    ) external view returns (uint endTime, uint amount);
}
