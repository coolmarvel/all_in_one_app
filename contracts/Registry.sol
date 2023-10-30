// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./openzeppelin-contracts/access/Ownable.sol";
import "./openzeppelin-contracts/utils/Address.sol";

/**
 * This smart contract code is Copyright 2020 WEMADETREE Ltd. For more information see https://wemixnetwork.com/
 *
 */

//ContractRegistry records information such as contract's address, name, tx hash.. and provides methods to find the stored information.
//It is recommended to deploy when the nonce of the owner address is 0.
//The reason is that the address of the contract is made of from and nonce of the deploy transaction.

// data, _ := rlp.EncodeToBytes(struct {
//	Addr  common.Address
// 	Nonce uint64
// }{b, nonce})
// return common.BytesToAddress(Keccak256(data)[12:])

//it is easy to find the contracts deployed by the owner.

contract ContractRegistry is Ownable {
  using Address for address;

  mapping(bytes32 => address) public contractsAddress;
  mapping(address => uint256) public deployedAtBlock;
  mapping(address => bytes32) public deployedTx;
  mapping(bytes32 => address) public contractsAddressPrevious;

  constructor() {}

  //register the newly deployed contract.
  function contractDeployed(bytes32 _name, address _address, uint256 _block, bytes32 _tx) external onlyOwner {
    require(_address.isContract(), "ContractRegistry: Only CA can be registered.");
    require(contractsAddress[_name] != _address, "ContractRegistry: same address already exists");

    contractsAddressPrevious[_name] = contractsAddress[_name];

    contractsAddress[_name] = _address;
    if (_block == 0) {
      _block = block.number;
    }
    deployedAtBlock[_address] = _block;
    deployedTx[_address] = _tx;
  }
}
