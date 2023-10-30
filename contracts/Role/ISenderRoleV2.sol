// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * This smart contract code is Copyright WEMIX PTE. LTD. For more information see https://wemixnetwork.com/
 */

interface ISenderRoleV2 {
    event AddSender(address addr, bytes32 service);
    event RemoveSender(address addr, bytes32 service);

    function isSender(
        address addr,
        bytes32 service
    ) external view returns (bool);

    function addSender(address addr, bytes32 service) external;

    function removeSender(address addr, bytes32 service) external;

    function sendersNum(bytes32 service) external view returns (uint);

    function senders(bytes32 service) external view returns (address[] memory);
}
