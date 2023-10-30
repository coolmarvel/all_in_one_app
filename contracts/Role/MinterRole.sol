// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "../../contracts/openzeppelin-contracts/access/Ownable.sol";
import "../../contracts/openzeppelin-contracts/utils/Address.sol";

/**
 * This smart contract code is Copyright 2020 WEMADETREE Ltd. For more information see https://wemixnetwork.com/
 *
 */
// MinterRole has the authority to mint balance of a token contract that inherits it
// owner has admin role
abstract contract MinterRole is Ownable {
    mapping(address => bool) private accounts;
    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole : msg sender is not minter");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return (accounts[account] == true || msg.sender == owner());
    }

    function addMinter(address account) public onlyOwner {
        accounts[account] = true;
    }

    function removeMinter(address account) public onlyOwner {
        accounts[account] = false;
    }
}
