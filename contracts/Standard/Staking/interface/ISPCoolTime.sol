// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ISPCoolTime {
    // ============== COOL-TIME ERROR ==============
    error NotPassedCoolTime(bytes32 func, address user);

    function stakeCoolTime() external view returns (uint);

    function unstakeCoolTime() external view returns (uint);

    function claimCoolTime() external view returns (uint);

    function isPassedStakeCoolTime(address user) external view returns (bool);

    function isPassedUnstakeCoolTime(address user) external view returns (bool);

    function isPassedClaimCoolTime(address user) external view returns (bool);

    function remainStakeCoolTime(address user) external view returns (uint);

    function remainUnstakeCoolTime(address user) external view returns (uint);

    function remainClaimCoolTime(address user) external view returns (uint);
}
