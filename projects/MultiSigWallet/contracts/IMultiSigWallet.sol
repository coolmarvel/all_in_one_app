// SPDX-License-Identifier: MIT
pragma solidity >0.8.0 <=0.9.0;

interface IMultiSigWallet {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 currentNumberOfConfirmations;
    }

    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(address indexed owner, uint256 indexed txIndex, address indexed to, uint256 value, bytes data);
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    event AddOwner(address indexed newOwner);
    event RemoveOwner(address indexed owner);
    event ChangeQuorum(uint256 indexed quorum);

    function submitTransaction(address _to, uint256 _value, bytes memory _data) external;
    function confirmTransaction(uint256 _txIndex) external;
    function executeTransaction(uint256 _txIndex) external payable;
    function revokeConfirmation(uint256 _txIndex) external;

    function addOwner(address _newOwner) external;
    function removeOwner(address _owner) external;
    function replaceOwner(address _owner, address _newOwner) external;
    function changeQuorum(uint256 _quorum) external;

    function getOwners() external view returns (address[] memory);
    function getOwnerCount() external view returns (uint256);
    function getTransaction(uint256 _txIndex) external view returns (address to, uint256 value, bytes memory data, bool executed, uint256 numConfirmations);
    function getTransactionCount() external view returns (uint256);
}
