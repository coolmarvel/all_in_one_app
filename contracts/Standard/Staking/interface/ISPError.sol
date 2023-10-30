// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ISPError {
    // ============== COMMON ERROR ==============
    error InvalidAddress(address addr);
    error OverValue(uint value, uint criteria);
    error UnderValue(uint value, uint criteria);
    error OverEndBlock(uint endBlock);
}
