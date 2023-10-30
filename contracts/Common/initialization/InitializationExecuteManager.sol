// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./InitializationBase.sol";
import "../../openzeppelin-contracts/utils/cryptography/ECDSA.sol";

/**
 *  Initialized RoleManager, ExecuteManager, BlackOrWhiteList
 */
abstract contract InitializationExecuteManager is InitializationBase {
    using InitializationLibrary for address;
    using Address for address;
    using ECDSA for bytes32;

    //===== VARIABLES =====//
    bytes32 public immutable setterRole;
    bytes32 public immutable validatorRole;

    address public executeManager;

    //===== EVENTS =====//
    event ExecuteManagerChanged(address executeManager);

    //===== ERRORS =====//
    error NotExecutable(bytes4 selector);
    error InvalidRoleName(bytes32 role, bytes32 name);
    error InvalidRecoveredAddress(address account, address recovered);
    error AccountNotHasRole(bytes32 role, address account);
    error NotValidator(address account);

    //===== MODIFIERS =====//
    modifier onlyExecutable(bytes4 selector) {
        if (!_canExecutable(selector)) revert NotExecutable(selector);
        _;
    }

    modifier onlyValidator() {
        address sender = msg.sender;
        if (!roleManager.hasRole(validatorRole, sender))
            revert NotValidator(sender);
        _;
    }

    modifier onlySetter(address account) {
        if (!_verifyAccountHasRole(setterRole, account))
            revert AccountNotHasRole(setterRole, account);
        _;
    }

    //===== CONSTRUCTOR =====//
    constructor(
        bytes32 _validatorRole,
        bytes32 _setterRole,
        address _roleManager,
        address _executeManager,
        address _blackList
    ) InitializationBase(_roleManager, _blackList) {
        if (_validatorRole == bytes32(0))
            revert InvalidRoleName("validatorRole", _validatorRole);
        if (_setterRole == bytes32(0))
            revert InvalidRoleName("setterRole", _setterRole);
        if (!_executeManager.isContract())
            revert InvalidAddress("executeManager", _executeManager);

        validatorRole = _validatorRole;
        setterRole = _setterRole;
        executeManager = _executeManager;
    }

    //===== FUNCTIONS =====//
    function changeRoleManager(
        address newManager
    )
        external
        onlySetter(msg.sender)
        onlyExecutable(this.changeRoleManager.selector)
    {
        super._changeRoleManager(newManager);
    }

    function changeExecuteManager(
        address newManager
    )
        external
        onlySetter(msg.sender)
        onlyExecutable(this.changeExecuteManager.selector)
    {
        if (!newManager.isContract())
            revert InvalidAddress("executeManager", newManager);

        executeManager = newManager;
        emit ExecuteManagerChanged(newManager);
    }

    function changeBlackList(
        address newBlackList
    )
        external
        onlySetter(msg.sender)
        onlyExecutable(this.changeBlackList.selector)
    {
        super._changeBlackList(newBlackList);
    }

    //===== INTERNAL VIEW FUNCTIONS =====//
    function _getValidatorRole() internal view virtual returns (bytes32) {}

    function _canExecutable(
        bytes4 selector
    ) internal view virtual returns (bool) {
        return executeManager.isExecutable(selector);
    }

    function _verifySignature(
        address compare,
        bytes memory message,
        bytes memory userSig,
        bytes memory validatorSig
    ) internal view returns (address user, address validator) {
        if (userSig.length == 0) {
            /**
             *  tx send by user
             *  verify validator signature by message
             */
            if (msg.sender != compare)
                revert InvalidRecoveredAddress(msg.sender, compare);
            user = msg.sender;
            validator = keccak256(message).recover(validatorSig);
        } else {
            user = keccak256(message).recover(userSig);
            if (compare != user) revert InvalidRecoveredAddress(user, compare);
            validator = keccak256(userSig).recover(validatorSig);
        }

        if (!_verifyAccountHasRole(_getValidatorRole(), validator))
            revert NotValidator(validator);

        // check blackList
        if (_isBlackList(user)) revert BlackList(user);
        if (_isBlackList(validator)) revert BlackList(validator);
    }
}
