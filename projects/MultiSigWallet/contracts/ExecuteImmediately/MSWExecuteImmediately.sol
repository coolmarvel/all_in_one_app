// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IMSWExecuteImmediately.sol";
import "../../../../contracts/openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

contract MSWExecuteImmediately is IMSWExecuteImmediately {
  using SafeERC20 for IERC20;

  //===== VARIABLES =====//
  // number of max owner
  uint public constant MAX_OWNER_COUNT = 50;

  // minimum required confirmation number
  uint public quorum;

  // transaction struct set
  Transaction[] public transactions;

  // owners address set
  address[] public owners;

  // mapping from owner => bool
  mapping(address => bool) public isOwner;

  // mapping from transaction id => owner => bool
  mapping(uint => mapping(address => bool)) public isConfirmed;

  //===== MODIFIER =====//
  modifier onlyOwner() {
    require(isOwner[msg.sender], "MSWEI: Only Owner can access.");
    _;
  }

  modifier isOneOfOwner(address _owner) {
    require(isOwner[_owner], "MSWEI: Only Owner can access.");
    _;
  }

  modifier isNotOneOfOwner(address _owner) {
    require(!isOwner[_owner], "MSWEI: Owner can not access.");
    _;
  }

  modifier onlyWallet() {
    require(msg.sender == address(this), "MSWEI: Only Wallet can access.");
    _;
  }

  modifier isTransactionExist(uint _transactionId) {
    require(_transactionId < transactions.length, "MSWEI: Transaction does not exist.");
    _;
  }

  modifier notExecuted(uint _transactionId) {
    require(!transactions[_transactionId].status.executed, "MSWEI: Transaction is already executed.");
    _;
  }

  modifier notConfirmed(uint _transactionId) {
    require(!isConfirmed[_transactionId][msg.sender], "MSWEI: Transaction is already confirmed");
    _;
  }

  modifier validRequirement(uint _ownerCount, uint _quorum) {
    require(_ownerCount <= MAX_OWNER_COUNT && _quorum <= _ownerCount && _quorum != 0 && _ownerCount != 0, "MSWEI: Invalid Requirement.");
    _;
  }

  //===== CONSTRUCTOR =====//
  constructor(address[] memory _owners, uint _quorum) {
    require(_owners.length > 1, "MSWEI: Number of owners must be greater than 1 to guarantee it is a voting system.");
    require(_quorum > 1 && _quorum <= _owners.length, "MSWEI: Number of confirmations does not satisfy quorum.");

    for (uint i = 0; i < _owners.length; i++) {
      address owner = _owners[i];

      require(owner != address(0), "MSWEI: Owner cannot be 0.");
      require(!isOwner[owner], "MSWEI: Owner Address is duplicated.");

      isOwner[owner] = true;
      owners.push(owner);
    }

    quorum = _quorum;
  }

  receive() external payable {
    emit Deposit(msg.sender, msg.value, address(this).balance);
  }

  /* =========== FUNCTIONS ===========*/
  /**
   * @notice Send a transaction.
   * Only owner can access.
   * @param to Target address.
   * @param value Ether value.
   * @param data Transaction data.
   */
  function submitTransaction(address to, uint value, bool immediatelyExecute, bytes memory data) public virtual onlyOwner {
    uint transactionId = transactions.length;

    transactions.push(
      Transaction({
        to: to,
        value: value,
        data: data,
        status: TransactionStatus({immediatelyExecute: immediatelyExecute, executed: false, currentNumberOfConfirmations: 0})
      })
    );

    emit SubmitTransaction(msg.sender, transactionId, to, value, data);
  }

  /**
   * @notice Confirm a transaction.
   * Only owner can access.
   * @param transactionId Transaction Id.
   */
  function confirmTransaction(
    uint transactionId
  ) public payable virtual onlyOwner isTransactionExist(transactionId) notExecuted(transactionId) notConfirmed(transactionId) {
    Transaction storage transaction = transactions[transactionId];
    transaction.status.currentNumberOfConfirmations += 1;
    isConfirmed[transactionId][msg.sender] = true;

    if (transaction.status.immediatelyExecute && _isPermitted(transactionId)) {
      _executeTransaction(transactionId);
    }

    emit ConfirmTransaction(msg.sender, transactionId);
  }

  /**
   * @notice Execute a transaction.
   * Only owner can access.
   * @param transactionId Transaction Id.
   */
  function executeTransaction(uint transactionId) public payable virtual onlyOwner isTransactionExist(transactionId) notExecuted(transactionId) {
    require(_isPermitted(transactionId), "MSWEI: Current Number Of Confirmations must be greater than or equal to quorum.");

    _executeTransaction(transactionId);
  }

  /**
   * @notice Revoke a transaction.
   * Only owner can access.
   * @param transactionId Transaction Id.
   */
  function revokeConfirmation(uint transactionId) public virtual onlyOwner isTransactionExist(transactionId) notExecuted(transactionId) {
    Transaction storage transaction = transactions[transactionId];

    require(isConfirmed[transactionId][msg.sender], "MSWEI: Transaction is not confirmed.");

    transaction.status.currentNumberOfConfirmations -= 1;
    isConfirmed[transactionId][msg.sender] = false;

    emit RevokeConfirmation(msg.sender, transactionId);
  }

  /**
   * @notice Add Owner.
   * Owner addresses can access WUDC Treasury.
   * @param newOwner Owner address to add.
   */
  function addOwner(address newOwner) external virtual onlyWallet isNotOneOfOwner(newOwner) validRequirement(owners.length + 1, quorum) {
    require(newOwner != address(0), "MSWEI: Owner cannot be 0.");
    isOwner[newOwner] = true;
    owners.push(newOwner);

    emit AddOwner(newOwner);
  }

  /**
   * @notice Remove Owner.
   * Owner addresses can access WUDC Treasury.
   * @param owner Owner address to remove.
   */
  function removeOwner(address owner) external virtual onlyWallet isOneOfOwner(owner) {
    isOwner[owner] = false;

    unchecked {
      for (uint i = 0; i < owners.length; i++) {
        if (owners[i] == owner) {
          owners[i] = owners[owners.length - 1];
          owners.pop();
          break;
        }
      }
    }

    if (quorum > owners.length) {
      // changeQuorum(owners.length);
      quorum = owners.length;
      emit ChangeQuorum(owners.length);
    }

    emit RemoveOwner(owner);
  }

  /**
   * @notice Replace Owner.
   * Owner addresses can access WUDC Treasury.
   * @param owner Owner address to remove.
   * @param newOwner Owner address to add.
   */
  function replaceOwner(address owner, address newOwner) external virtual onlyWallet isOneOfOwner(owner) isNotOneOfOwner(newOwner) {
    unchecked {
      for (uint i = 0; i < owners.length; i++) {
        if (owners[i] == owner) {
          owners[i] = newOwner;
          break;
        }
      }
    }

    isOwner[owner] = false;
    isOwner[newOwner] = true;

    emit RemoveOwner(owner);
    emit AddOwner(newOwner);
  }

  /**
   * @notice Minimum required confirmation number .
   * @param _quorum Minimum number of confirmation.
   */
  function changeQuorum(uint _quorum) external virtual onlyWallet validRequirement(owners.length, _quorum) {
    quorum = _quorum;

    emit ChangeQuorum(_quorum);
  }

  /* ========== VIEW FUNCTION ========== */
  /**
   * @notice Get Owners.
   */
  function getOwners() public view returns (address[] memory) {
    return owners;
  }

  /**
   * @notice Get Owners Count.
   */
  function getOwnerCount() public view returns (uint) {
    return owners.length;
  }

  /**
   */
  function getTransaction(uint transactionId) public view returns (Transaction memory) {
    return transactions[transactionId];
  }

  /**
   * @notice Get Transaction Count.
   */
  function getTransactionCount() public view returns (uint) {
    return transactions.length;
  }

  //===== INTERNAL FUNCTIONS =====//
  function _isPermitted(uint transactionId) internal virtual returns (bool) {
    return transactions[transactionId].status.currentNumberOfConfirmations >= quorum;
  }

  function _executeTransaction(uint _transactionId) internal virtual {
    Transaction storage transaction = transactions[_transactionId];

    transaction.status.executed = true;

    (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
    require(success, "MSWEI: Transaction failed.");

    emit ExecuteTransaction(msg.sender, _transactionId);
  }
}
