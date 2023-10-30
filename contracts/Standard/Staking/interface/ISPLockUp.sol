// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ISPLockUp {
    // ============== LOCK-UP ERROR ==============
    error NotPassGlobalLockUp(uint current, uint globalLu);
    error NotPassUserLockUp(address user, uint firstBlock, uint userLu);

    function globalLu() external view returns (uint);

    function userLu() external view returns (uint);

    function firstStakedBlock(address user) external view returns (uint);

    function remainGlobalLockUp() external view returns (uint);

    function remainUserLockUp(address user) external view returns (uint);

    function isPassedGlobalLockUp() external view returns (bool);

    function isPassedUserLockUp(address user) external view returns (bool);
}
