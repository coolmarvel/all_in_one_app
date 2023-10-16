// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IRoleManager.sol";
import "../../../contracts/openzeppelin-contracts/access/AccessControl.sol";

/**
 *  RoleManager contract by WEMADE
 *  Inherit AccessControl contract by openzeppelin
 *  Manage role of contract that WEMADE provied
 */
contract RoleManager is AccessControl, IRoleManager {
  //===== VERIABLE =====//
  mapping(bytes32 => address[]) private _roleList;
  mapping(bytes32 => mapping(address => uint)) private _registIndex;

  //===== CONSTRUCTOR =====//
  constructor() {
    // owner
    super._setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  //===== FUNCTIONS =====//
  function setRoleAdmin(bytes32 role, bytes32 adminRole) external override onlyRole(getRoleAdmin(role)) {
    super._setRoleAdmin(role, adminRole);
  }

  function grantRole(
    bytes32 role,
    address account
  ) public virtual override(AccessControl, IAccessControl) onlyRole(getRoleAdmin(role)) {
    bytes32 _role = role;
    address _account = account;

    if (!hasRole(_role, _account)) {
      _roleList[_role].push(_account);
      _registIndex[_role][_account] = _roleList[_role].length - 1;
      super._grantRole(_role, _account);
    }
  }

  function revokeRole(
    bytes32 role,
    address account
  ) public virtual override(AccessControl, IAccessControl) onlyRole(getRoleAdmin(role)) {
    bytes32 _role = role;
    address _account = account;

    _revokeRole(_role, _account);
  }

  function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
    bytes32 _role = role;
    address _account = account;

    require(account == _msgSender(), "AccessControl: can only renounce roles for self");

    _revokeRole(_role, _account);
  }

  //===== VIEW FUNCTIONS =====//
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IRoleManager).interfaceId || super.supportsInterface(interfaceId);
  }

  function getRoleList(bytes32 role) external view returns (address[] memory) {
    return _roleList[role];
  }

  //===== INTERNAL FUNCTIONS =====//
  function _revokeRole(bytes32 role, address account) internal virtual override {
    bytes32 _role = role;
    address _account = account;

    if (hasRole(_role, _account)) {
      address[] storage list = _roleList[_role];

      uint lastIndex = list.length - 1;
      uint index = _registIndex[_role][_account];
      address swapAddress = list[lastIndex];

      list[index] = list[lastIndex];
      _registIndex[_role][swapAddress] = index;

      list.pop();

      super._revokeRole(_role, _account);
    }
  }
}
