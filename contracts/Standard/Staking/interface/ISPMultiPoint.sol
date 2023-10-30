// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ISPMultiPoint {
    error StakedAmountIsZero(address user);

    function useMP() external view returns (bool);

    function getAllMPInfo()
        external
        view
        returns (uint totalMP, uint lastMP, uint lastBlock);

    function getUserMPInfo(
        address user
    ) external view returns (uint totalMP, uint lastMP, uint lastBlock);

    function currentAllMP() external view returns (uint);

    function currentUserMP(address user) external view returns (uint);

    function totalAllMP() external view returns (uint);

    function totalUserMP(address user) external view returns (uint);

    function lastAllMP() external view returns (uint);

    function lastUserMP(address user) external view returns (uint);
}
