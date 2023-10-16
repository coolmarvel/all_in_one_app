// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../../../contracts/openzeppelin-contracts/access/IAccessControl.sol";

interface IRoleManager is IAccessControl {
  //===== FUNCTIONS =====//
  function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

  //===== VIEW FUNCTIONS =====//
  function getRoleList(bytes32 role) external view returns (address[] memory);
}
