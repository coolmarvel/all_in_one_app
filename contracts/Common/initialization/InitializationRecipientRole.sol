// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./InitializationExecuteManager.sol";
import "../../../projects/RecipientRole/contracts/IRecipientRole.sol";

/**
 *  Inherit InitializationExecuteManager
 *  Initialized RoleManager, ExecuteManager, BlackOrWhiteList and RecipientRole
 *  Must override _getSetterRole() function to setting setter role
 */
abstract contract InitializationRecipientRole is InitializationExecuteManager {
    using Address for address;

    //===== VARIABLES =====//
    IRecipientRole public recipientRole;

    //===== EVENTS =====//
    event RecipientRoleChanged(address recipientRole);

    //===== CONSTRUCTOR =====//
    constructor(
        bytes32 _validatorRole,
        bytes32 _setterRole,
        address _roleManager,
        address _executeManager,
        address _blackList,
        address _recipientRole
    )
        InitializationExecuteManager(
            _validatorRole,
            _setterRole,
            _roleManager,
            _executeManager,
            _blackList
        )
    {
        if (!_recipientRole.isContract())
            revert InvalidAddress("recipientRole", _recipientRole);

        recipientRole = IRecipientRole(_recipientRole);
    }

    //===== FUNCTIONS =====//
    function changeRecipientRole(
        address newRecipientRole
    )
        external
        virtual
        onlySetter(msg.sender)
        onlyExecutable(this.changeRecipientRole.selector)
    {
        if (!newRecipientRole.isContract())
            revert InvalidAddress("recipientRole", newRecipientRole);

        recipientRole = IRecipientRole(newRecipientRole);
        emit RecipientRoleChanged(newRecipientRole);
    }
}
