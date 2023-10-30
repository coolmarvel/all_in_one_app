// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

library Core {
    enum MineType {
        Schedule,
        Revenue
    }
}

interface ISPCore {
    function mineType() external pure returns (Core.MineType);
}
