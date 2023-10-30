// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title IPteRegistry
 * @author Wemade Pte, Ltd
 * @dev interface of the PteRegistry
 */
interface IPteRegistry {
    struct Pte {
        address pte;
        uint256 feeRatio;
    }

    function getRegisteredPte(bytes32 name) external view returns (Pte memory);

    function isRegistered(address pte) external view returns (bool);
}
