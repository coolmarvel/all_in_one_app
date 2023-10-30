// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * This smart contract code is Copyright WEMIX PTE. LTD. For more information see https://wemixnetwork.com/
 */
interface ISenderRole {
    event AddSender(address account);
    event RemoveSender(address account);

    function isSender(address account) external view returns (bool);

    function addSender(address account) external;

    function removeSender(address account) external;
}
