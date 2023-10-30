// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "../Role/EditorRole.sol";
import "../openzeppelin-contracts/utils/Address.sol";

/**
 * This smart contract code is Copyright 2020 WEMADETREE Ltd. For more information see https://wemixnetwork.com/
 *
 */
// RouterRole has the authority to change the storage of a contract that inherits it
// owner has admin role
contract RouterRole is EditorRole {
    using Address for address;
    mapping(address => bool) private routers;

    modifier onlyRouter() {
        require(isRouter(_msgSender()), "RR-001: msg sender is not Router");
        _;
    }

    function isRouter(address router) public view returns (bool) {
        return (routers[router] || _msgSender() == owner());
    }

    function addRouter(address router) external onlyEditor {
        require(router.isContract(), "RR-000: address is EOA");
        _addRouter(router);
    }

    function removeRouter(address router) external onlyEditor {
        routers[router] = false;
    }

    function _addRouter(address router) internal {
        routers[router] = true;
    }
}
