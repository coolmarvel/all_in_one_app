// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../../../../contracts/openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IMSWExecuteImmediatelyStruct {
  //===== STRUCTS =====//
  struct Transaction {
    address to;
    uint value;
    bytes data;
    TransactionStatus status;
  }

  struct TransactionStatus {
    bool immediatelyExecute;
    bool executed;
    uint currentNumberOfConfirmations;
  }
}

interface IMSWExecuteImmediately is IMSWExecuteImmediatelyStruct {
  //===== FUNCTIONS =====//
  function submitTransaction(address _to, uint _value, bool immediatelyExecute, bytes memory _data) external;

  function confirmTransaction(uint _txIndex) external payable;

  function executeTransaction(uint _txIndex) external payable;

  function revokeConfirmation(uint _txIndex) external;

  function addOwner(address _newOwner) external;

  function removeOwner(address _owner) external;

  function replaceOwner(address _owner, address _newOwner) external;

  function changeQuorum(uint _quorum) external;

  //===== VIEW FUNCTION =====//
  function getOwners() external view returns (address[] memory);

  function getOwnerCount() external view returns (uint);

  function getTransaction(uint _txIndex) external view returns (Transaction memory);

  function getTransactionCount() external view returns (uint);

  //===== EVENTS =====//
  event Deposit(address indexed sender, uint amount, uint balance);
  event SubmitTransaction(address indexed owner, uint indexed txIndex, address indexed to, uint value, bytes data);
  event ConfirmTransaction(address indexed owner, uint indexed txIndex);
  event RevokeConfirmation(address indexed owner, uint indexed txIndex);
  event ExecuteTransaction(address indexed owner, uint indexed txIndex);

  event AddOwner(address indexed newOwner);
  event RemoveOwner(address indexed owner);
  event ChangeQuorum(uint indexed quorum);
}
