// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ISPMineSchedule {
    // ============== SCHEDULE ERROR ==============
    error InvalidStage(uint stage, uint reward);
    error NotAllowPreStake(bool allowPreStake);
    error InvalidPreStakeSet(uint start, uint end);
    error NotStakePeriod(uint current, uint preStart, uint preEnd, uint start);

    function startBlock() external view returns (uint);

    function allowPreStake() external view returns (bool);

    function scheduleSize() external view returns (uint);

    function currentPosition() external view returns (uint);

    function getSchedule(
        uint index
    ) external view returns (uint stage, uint reward);

    function calcPosition(uint criteria) external view returns (uint pos);

    function calcMinedRT(
        uint start,
        uint end
    ) external view returns (uint amount);

    function getPreStakeInfo() external view returns (uint start, uint end);
}
