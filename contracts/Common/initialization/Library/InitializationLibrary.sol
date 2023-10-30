// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../../../openzeppelin-contracts/utils/Address.sol";
import "../../../openzeppelin-contracts/access/IAccessControl.sol";
import "../../../../projects/Blacklist/contracts/interface/IBlackOrWhiteList.sol";
import "../../../../projects/ExecuteManager/contracts/IExecuteManager.sol";

library InitializationLibrary {
    using Address for address;

    /**
     *  RoleManager
     */
    function hasRole(
        address roleManager,
        bytes32 role,
        address account
    ) internal view returns (bool) {
        require(
            roleManager.isContract(),
            "InitializationLib: invalid roleManager"
        );
        return IAccessControl(roleManager).hasRole(role, account);
    }

    /**
     *  ExecuteManager
     */
    function isExecutable(
        address executeManager,
        bytes4 selector
    ) internal view returns (bool) {
        require(
            executeManager.isContract(),
            "InitializationLib: invalid roleManager"
        );
        return IExecuteManager(executeManager).isExecutable(selector);
    }

    /**
     *  BlackOrWhitelist
     */
    function isBlacklist(
        address blackList,
        address contractAddress,
        address account
    ) internal view returns (bool) {
        require(
            blackList.isContract(),
            "InitializationLib: invalid roleManager"
        );
        return
            IBlackOrWhiteList(blackList).isBlacklist(contractAddress, account);
    }
}
