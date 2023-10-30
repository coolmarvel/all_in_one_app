// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IVerifyKey {
    function getVerifyKey(
        address user,
        bytes32 functionName
    ) external view returns (bytes32);
}
