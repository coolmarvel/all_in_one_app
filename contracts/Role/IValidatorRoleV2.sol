// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * This smart contract code is Copyright WEMIX PTE. LTD. For more information see https://wemixnetwork.com/
 */
interface IValidatorRoleV2 {
    event AddValidator(address account);
    event RemoveValidator(address account);

    function isValidator(address account) external view returns (bool);

    function isValidatorSig(
        bytes memory message,
        bytes memory signature
    ) external view returns (bool);

    function addValidator(address account) external;

    function removeValidator(address account) external;

    function numberValidators() external view returns (uint);

    function validators() external view returns (address[] memory);
}
