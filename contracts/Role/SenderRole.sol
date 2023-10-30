// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "../openzeppelin-contracts/access/Ownable.sol";
import "./ISenderRole.sol";

/**
 * This smart contract code is Copyright 2020 WEMADETREE Ltd. For more information see https://wemixnetwork.com/
 *
 */
// EditorRole has the authority to change the storage of a contract that inherits it
// owner has admin role
contract SenderRole is Ownable, ISenderRole {
    mapping(address => bool) private bearers;

    constructor(address account) {
        addSender(account);
    }

    function isSender(address account) external view override returns (bool) {
        return (bearers[account] == true || msg.sender == owner());
    }

    function addSender(address account) public override onlyOwner {
        require(account != address(0), "SenderRole: address(0)");
        require(
            bearers[account] == false,
            "SenderRole: Already exists address"
        );
        bearers[account] = true;
        emit AddSender(account);
    }

    function removeSender(address account) public override onlyOwner {
        require(account != address(0), "SenderRole: address(0)");
        require(bearers[account] == true, "SenderRole: Invalid sender address");
        bearers[account] = false;
        emit RemoveSender(account);
    }
}
