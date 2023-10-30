// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * This smart contract code is Copyright WEMIX PTE. LTD. For more information see https://wemixnetwork.com/
 */

interface IValidatorRoleV3 {
    event AddValidator(address addr, bytes32 service);
    event RemoveValidator(address addr, bytes32 service);

    function isValidator(
        address addr,
        bytes32 service
    ) external view returns (bool);

    function isValidatorSig(
        bytes32 service,
        bytes memory message,
        bytes memory signature
    ) external view returns (bool);

    function addValidator(address account, bytes32 service) external;

    function removeValidator(address account, bytes32 service) external;

    function validatorsNum(bytes32 service) external view returns (uint);

    function validators(
        bytes32 service
    ) external view returns (address[] memory);
}
