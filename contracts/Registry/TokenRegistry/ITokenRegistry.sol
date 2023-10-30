// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ITokenRegistry {
    function CA(bytes32 name) external view returns (address);
}
