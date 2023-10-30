// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "../openzeppelin-contracts/access/Ownable.sol";
import "./IMinterRoleV2.sol";

// MinterRoleV2 has the authority to mint balance of a token contract that inherits it
// owner has admin role
contract MinterRoleV2 is Ownable, IMinterRoleV2 {
    mapping(address => bool) private bearersMap;
    address[] private bearersArray;

    constructor(address account) {
        addMinter(account);
    }

    function isMinter(address account) external view override returns (bool) {
        return (bearersMap[account] == true || msg.sender == owner());
    }

    function addMinter(address account) public override onlyOwner {
        require(account != address(0), "MinterRoleV2: address(0)");
        require(
            bearersMap[account] == false,
            "MinterRoleV2: Already exists address"
        );
        bearersMap[account] = true;
        bearersArray.push(account);
        emit AddMinter(account);
    }

    function removeMinter(address account) public override onlyOwner {
        require(account != address(0), "MinterRoleV2: address(0)");
        require(
            bearersMap[account] == true,
            "MinterRoleV2: Invalid editor address"
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
        emit RemoveMinter(account);
    }

    function minters() external view override returns (address[] memory) {
        return bearersArray;
    }
}
