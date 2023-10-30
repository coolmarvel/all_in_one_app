// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * This smart contract code is Copyright 2020 WEMADETREE Ltd. For more information see https://wemixnetwork.com/
 *
 */
// MinterRole has the authority to mint balance of a token contract that inherits it
interface IMinterRoleV2 {
    function isMinter(address account) external view returns (bool);

    function addMinter(address account) external;

    function removeMinter(address account) external;

    function minters() external view returns (address[] memory);

    event AddMinter(address account);
    event RemoveMinter(address account);
}
