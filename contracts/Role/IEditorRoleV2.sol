// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * This smart contract code is Copyright WEMIX PTE. LTD. For more information see https://wemixnetwork.com/
 */
interface IEditorRoleV2 {
    event AddEditor(address account);
    event RemoveEditor(address account);

    function isEditor(address account) external view returns (bool);

    function addEditor(address account) external;

    function removeEditor(address account) external;
}
