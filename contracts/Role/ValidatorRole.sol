// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "../../contracts/openzeppelin-contracts/access/Ownable.sol";
import "../../contracts/openzeppelin-contracts/utils/cryptography/ECDSA.sol";

/**
 * This smart contract code is Copyright 2020 WEMADETREE Ltd. For more information see https://wemixnetwork.com/
 *
 */
// ValidatorRole is used when a specific EOA's signature is required when an unspecified address calls a specific method of a contract.
// owner has admin role.
abstract contract ValidatorRole is Ownable {
    using ECDSA for bytes32;
    address private bearer;

    constructor(address account) {
        setValidator(account);
    }

    modifier onlyValidatorSig(bytes memory _message, bytes memory _signature) {
        address _recover = keccak256(_message).recover(_signature);
        require(isValidator(_recover), "role:recover");
        _;
    }
    modifier onlyValidator() {
        require(isValidator(msg.sender), "role:msg.sender");
        _;
    }

    function isValidator(address account) public view returns (bool) {
        return (bearer == account || msg.sender == owner());
    }

    function setValidator(address _account) public onlyOwner {
        require(_account != address(0), "role:address");
        bearer = _account;
    }

    function validator() public view returns (address) {
        return bearer;
    }
}
