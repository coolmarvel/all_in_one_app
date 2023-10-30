// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../InitializationBase.sol";

abstract contract TokenInitialization is InitializationBase {
    using Address for address;

    //===== VARIABLES =====//
    bytes32 public immutable setterRole;

    address public navigator; // address of navigator

    //===== MODIFIERS =====//
    modifier onlySetter() {
        require(
            _verifyAccountHasRole(setterRole, msg.sender),
            "TI: sender is not setter"
        );
        _;
    }

    modifier isNotBlackList(address account) override {
        require(!_isBlackList(account), "TI: account is blackList");
        _;
    }

    //===== EVENTS =====//
    event NavigatorChanged(address newNavigator);

    //===== CONSTRUCTOR =====//
    constructor(
        address navigator_,
        address roleManager_,
        address blackList_,
        bytes32 setterRole_
    ) InitializationBase(roleManager_, blackList_) {
        require(navigator_.isContract(), "TI: invalid navigator");

        navigator = navigator_;
        setterRole = setterRole_;
    }

    //===== FUNCTIONS =====//
    function changeNavigator(address newNavigator) external virtual onlySetter {
        _changeNavigator(newNavigator);
    }

    function changeRoleManager(address newManager) external virtual onlySetter {
        super._changeRoleManager(newManager);
    }

    function changeBlackList(address newBlackList) external virtual onlySetter {
        super._changeBlackList(newBlackList);
    }

    //===== INTERNAL FUNCTIONS =====//
    function _changeNavigator(address newNavigator) internal virtual {
        address _navigator = newNavigator;
        require(_navigator.isContract(), "TI: invalid navigator");

        navigator = _navigator;

        emit NavigatorChanged(_navigator);
    }
}
