// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../openzeppelin-contracts/access/Ownable.sol";
import "../openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import "./IValidatorRoleV3.sol";

/**
 * This smart contract code is Copyright 2023 WEMADETREE Ltd. For more information see https://wemixnetwork.com/
 *
 */

// ValidatorRole is used when a specific EOA's signature is required when an unspecified address calls a specific method of a contract.
// owner has admin role.

contract ValidatorRoleV3 is Ownable, IValidatorRoleV3 {
    using ECDSA for bytes32;

    mapping(address => mapping(bytes32 => bool)) private bearersMap; // address => service => is validator
    mapping(bytes32 => address[]) private bearersList; // service => validator addr list

    function isValidator(
        address addr,
        bytes32 service
    ) public view override returns (bool) {
        return bearersMap[addr][service] || msg.sender == owner();
    }

    function isValidatorSig(
        bytes32 service,
        bytes memory message,
        bytes memory signature
    ) public view override returns (bool) {
        address recover = keccak256(message).recover(signature);
        return isValidator(recover, service);
    }

    function addValidator(
        address addr,
        bytes32 service
    ) public override onlyOwner {
        require(addr != address(0), "ValidatorRoleV3: address(0)");
        require(
            !bearersMap[addr][service],
            "ValidatorRoleV3: Already exists address"
        );
        bearersMap[addr][service] = true;
        bearersList[service].push(addr);

        emit AddValidator(addr, service);
    }

    function removeValidator(
        address addr,
        bytes32 service
    ) external override onlyOwner {
        require(addr != address(0), "ValidatorRoleV3: address(0)");
        require(
            bearersMap[addr][service],
            "ValidatorRoleV3: Invalid validator address"
        );
        bearersMap[addr][service] = false;

        for (uint i = 0; i < bearersList[service].length; i++) {
            if (bearersList[service][i] == addr) {
                for (uint j = i; j < bearersList[service].length - 1; j++) {
                    bearersList[service][j] = bearersList[service][j + 1];
                }
                break;
            }
        }
        bearersList[service].pop();

        emit RemoveValidator(addr, service);
    }

    function validatorsNum(
        bytes32 service
    ) external view override returns (uint) {
        return bearersList[service].length;
    }

    function validators(
        bytes32 service
    ) external view override returns (address[] memory) {
        return bearersList[service];
    }
}
