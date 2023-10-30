// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../IExchangerBase.sol";

interface IGameExchanger {
    //===== FUCTIONS =====//
    function trade(
        address buyer,
        bytes32 exchanger,
        uint index,
        bytes calldata userSig,
        bytes calldata validatorSig
    ) external;
}
