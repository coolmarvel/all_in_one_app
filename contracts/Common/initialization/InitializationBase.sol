// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./Library/InitializationLibrary.sol";

abstract contract InitializationBase {
    using Address for address;
    using InitializationLibrary for address;

    //===== VARIABLES =====//
    address public roleManager;
    address public blackList;

    //===== EVENTS =====//
    event RoleManagerChanged(address roleManager);
    event BlackListChanged(address blackList);

    //===== ERRORS =====//
    error InvalidAddress(bytes32 name, address input);
    error BlackList(address sender);

    //===== MODIFIERS =====//
    modifier isNotBlackList(address account) virtual {
        if (_isBlackList(account)) revert BlackList(account);
        _;
    }

    //===== CONSTRUCTOR =====//
    constructor(address _roleManager, address _blackList) {
        if (!_roleManager.isContract())
            revert InvalidAddress("roleManager", _roleManager);
        if (!_blackList.isContract())
            revert InvalidAddress("blackList", _blackList);

        roleManager = _roleManager;
        blackList = _blackList;
    }

    //===== FUNCTIONS =====//
    function _verifyAccountHasRole(
        bytes32 role,
        address account
    ) internal view virtual returns (bool) {
        return roleManager.hasRole(role, account);
    }

    //===== INTERNAL FUNCTIONS =====//
    function _isBlackList(
        address account
    ) internal view virtual returns (bool) {
        return blackList.isBlacklist(address(this), account);
    }

    function _changeRoleManager(address newManager) internal virtual {
        if (!newManager.isContract())
            revert InvalidAddress("roleManager", newManager);

        roleManager = newManager;
        emit RoleManagerChanged(newManager);
    }

    function _changeBlackList(address newBlackList) internal virtual {
        if (!newBlackList.isContract())
            revert InvalidAddress("blackList", newBlackList);

        blackList = newBlackList;
        emit BlackListChanged(newBlackList);
    }
}
