// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "../openzeppelin-contracts/access/Ownable.sol";
import "../openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import "./IValidatorRoleV2.sol";

/**
 * This smart contract code is Copyright 2022 WEMADETREE Ltd. For more information see https://wemixnetwork.com/
 *
 */
// ValidatorRole is used when a specific EOA's signature is required when an unspecified address calls a specific method of a contract.
// owner has admin role.
contract ValidatorRoleV2 is Ownable, IValidatorRoleV2 {
    using ECDSA for bytes32;
    mapping(address => bool) private bearersMap;
    address[] private bearersArray;

    constructor(address[] memory accounts) {
        for (uint i = 0; i < accounts.length; i++) {
            addValidator(accounts[i]);
        }
    }

    function isValidator(address account) public view override returns (bool) {
        return (bearersMap[account] == true || msg.sender == owner());
    }

    function isValidatorSig(
        bytes memory message,
        bytes memory signature
    ) public view override returns (bool) {
        address recover = keccak256(message).recover(signature);
        return isValidator(recover) == true;
    }

    function addValidator(address account) public override onlyOwner {
        require(account != address(0), "ValidatorRoleV2: address(0)");
        require(
            bearersMap[account] == false,
            "ValidatorRoleV2: Already exists address"
        );
        bearersMap[account] = true;
        bearersArray.push(account);
        emit AddValidator(account);
    }

    function removeValidator(address account) external override onlyOwner {
        require(account != address(0), "ValidatorRoleV2: address(0)");
        require(
            bearersMap[account] == true,
            "ValidatorRoleV2: Invalid validator address"
        );
        bearersMap[account] = false;
        for (uint i = 0; i < bearersArray.length; i++) {
            if (bearersArray[i] == account) {
                for (uint j = i; j < bearersArray.length - 1; j++) {
                    bearersArray[j] = bearersArray[j + 1];
                }
                break;
            }
        }
        bearersArray.pop();
        emit RemoveValidator(account);
    }

    function numberValidators() external view override returns (uint) {
        return bearersArray.length;
    }

    function validators() external view override returns (address[] memory) {
        return bearersArray;
    }
}
