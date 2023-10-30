// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "../openzeppelin-contracts/access/Ownable.sol";
import "./IEditorRoleV2.sol";

/**
 * This smart contract code is Copyright 2020 WEMADETREE Ltd. For more information see https://wemixnetwork.com/
 *
 */
// EditorRole has the authority to change the storage of a contract that inherits it
// owner has admin role
contract EditorRoleV2 is Ownable, IEditorRoleV2 {
    mapping(address => bool) private bearers;

    constructor(address account) {
        addEditor(account);
    }

    function isEditor(address account) external view override returns (bool) {
        return (bearers[account] == true || msg.sender == owner());
    }

    function addEditor(address account) public override onlyOwner {
        require(account != address(0), "EditorRoleV2: address(0)");
        require(
            bearers[account] == false,
            "EditorRoleV2: Already exists address"
        );
        bearers[account] = true;
        emit AddEditor(account);
    }

    function removeEditor(address account) public override onlyOwner {
        require(account != address(0), "EditorRoleV2: address(0)");
        require(
            bearers[account] == true,
            "EditorRoleV2: Invalid editor address"
        );
        bearers[account] = false;
        emit RemoveEditor(account);
    }
}
