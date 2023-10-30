// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "../../contracts/openzeppelin-contracts/access/Ownable.sol";
import "../../contracts/openzeppelin-contracts/utils/Address.sol";

/**
 * This smart contract code is Copyright 2020 WEMADETREE Ltd. For more information see https://wemixnetwork.com/
 *
 */
// SignerRole has the authority to transfer balance of a token contract that inherits it
// owner has admin role
abstract contract SignerRole is Ownable {
    using Address for address;
    mapping(address => bool) private accounts;
    modifier onlySigner() {
        require(isSigner(msg.sender), "SignerRole : msg sender is not signer");
        _;
    }

    function isSigner(address account) public view returns (bool) {
        return (accounts[account] == true || msg.sender == owner());
    }

    function addSigner(address account) public onlyOwner {
        require(account.isContract(), "SignerRole: signer can only be CA");
        accounts[account] = true;
    }

    function removeSigner(address account) public onlyOwner {
        accounts[account] = false;
    }
}
