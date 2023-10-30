// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../IExchangerBase.sol";
import "../../token/WWEMIX/IWWEMIX.sol";

interface IWemixExchanger {
    //===== ERRORS =====//
    error NotWWEMIX(address sender);
    error SenderNotMatch(address expected, address actual);
    error ReceiveValueNotMatch(uint expected, uint actual);
    error TransferWemixFail(address to, uint amount);
    error RevertMsg(string reason);
    error PanicMsg(uint errCode);
    error ErrMsg(bytes reason);

    //===== FUCTIONS =====//
    function trade(
        address buyer,
        bytes32 exchanger,
        uint index,
        bytes calldata userSig,
        bytes calldata validatorSig
    ) external payable;
}
