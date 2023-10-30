// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../openzeppelin-contracts/access/Ownable.sol";
import "./ISenderRoleV2.sol";

/**
 * This smart contract code is Copyright 2023 WEMADETREE Ltd. For more information see https://wemixnetwork.com/
 *
 */

// SenderRole has the authority to change the storage of a contract that inherits it
// owner has admin role

contract SenderRoleV2 is Ownable, ISenderRoleV2 {
    mapping(address => mapping(bytes32 => bool)) private bearersMap; // address => service => is sender
    mapping(bytes32 => address[]) private bearersList; // service => sender addr list

    function isSender(
        address addr,
        bytes32 service
    ) external view override returns (bool) {
        return bearersMap[addr][service] || msg.sender == owner();
    }

    function addSender(
        address addr,
        bytes32 service
    ) public override onlyOwner {
        require(addr != address(0), "SenderRoleV2: address(0)");
        require(
            !bearersMap[addr][service],
            "SenderRoleV2: Already exists address"
        );
        bearersMap[addr][service] = true;
        bearersList[service].push(addr);

        emit AddSender(addr, service);
    }

    function removeSender(
        address addr,
        bytes32 service
    ) public override onlyOwner {
        require(addr != address(0), "SenderRoleV2: address(0)");
        require(
            bearersMap[addr][service],
            "SenderRoleV2: Invalid sender address"
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

        emit RemoveSender(addr, service);
    }

    function sendersNum(bytes32 service) external view override returns (uint) {
        return bearersList[service].length;
    }

    function senders(
        bytes32 service
    ) external view override returns (address[] memory) {
        return bearersList[service];
    }
}
