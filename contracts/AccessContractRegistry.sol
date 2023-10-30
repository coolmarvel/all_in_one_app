// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./Registry.sol";
import "./openzeppelin-contracts/access/Ownable.sol";
import "./openzeppelin-contracts/utils/Address.sol";

//AccessContractRegistry allows to access the address of contracts through CA method by inheriting this contract
//if there is a contract that needs to access the contract stored in the ContractRegistry.

contract AccessContractRegistry is Ownable {
    ContractRegistry public contractRegistry;

    constructor() {}

    //first, set the address of contractRegistry once.
    function setRegistry(address _address) public onlyOwner {
        contractRegistry = ContractRegistry(_address);
    }

    //address of another contract deployed by the same address is fetched during runtime.
    function CA(bytes32 _bytesName) public view returns (address) {
        address _addr = contractRegistry.contractsAddress(_bytesName);
        require(
            _addr != address(0),
            "AccessContractRegistry : _addr is the zero address"
        );
        return _addr;
    }
}
