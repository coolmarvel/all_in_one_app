// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../contracts/openzeppelin-contracts/access/Ownable.sol";
import "../../../contracts/openzeppelin-contracts/utils/Address.sol";

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

    modifier isContractAddress(address _address) {
        require(_address.isContract(), "Registry: Invalid Address");
        _;
    }

    modifier isExistAddress(bytes32 _name, address _address) {
        require(
            contractsAddress[_name] != _address,
            "Registry: Same address already exists"
        );
        _;
    }

    // register the newly deployed contract.
    function contractDeployed(
        bytes32 _name,
        address _address,
        uint256 _block,
        bytes32 _tx
    )
        external
        onlyOwner
        isContractAddress(_address)
        isExistAddress(_name, _address)
    {
        contractsAddressPrevious[_name] = contractsAddress[_name];

        contractsAddress[_name] = _address;
        if (_block == 0) {
            _block = block.number;
        }
        deployedAtBlock[_address] = _block;
        deployedTx[_address] = _tx;
    }

    function CA(bytes32 _bytesName) public view returns (address) {
        return contractsAddress[_bytesName];
    }
}
