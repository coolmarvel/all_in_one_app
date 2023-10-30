// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../ExchangerBase.sol";
import "./IWemixExchanger.sol";

abstract contract WemixExchanger is ExchangerBase, IWemixExchanger {
    using InitializationLibrary for address;

    //===== RECEIVE =====//
    receive() external payable {
        if (msg.sender != address(token)) revert NotWWEMIX(msg.sender);
    }

    //===== CONSTRUCTOR =====//
    constructor(
        address _token, // token = wwemix
        address _treasury,
        bytes32 _service,
        bytes32 _validatorRole,
        bytes32 _setterRole,
        address _roleManager,
        address _executeManager,
        address _blackList,
        address _recipientRole
    )
        ExchangerBase(
            _token,
            _treasury,
            _service,
            _validatorRole,
            _setterRole,
            _roleManager,
            _executeManager,
            _blackList,
            _recipientRole
        )
    {
        _registFunctionSelector("trade", IWemixExchanger.trade.selector);
    }

    //===== FUNCTIONS =====//
    /**
     *  @dev trade item to pay tokens
     *  @param buyer address of buyer
     *  @param exchanger name of exchanger
     *  @param index item index
     *  @param userSig user signature
     *  @param validatorSig validator signature
     */
    function trade(
        address buyer,
        bytes32 exchanger,
        uint index,
        bytes calldata userSig,
        bytes calldata validatorSig
    )
        external
        payable
        virtual
        nonReentrant
        onlyExecutable(this.trade.selector)
        isNotBlackList(msg.sender)
    {
        super._trade(
            IWemixExchanger.trade.selector,
            buyer,
            exchanger,
            index,
            userSig,
            validatorSig
        );
    }

    //===== INTERNAL FUNCTIONS =====//
    function _isAllSettleFunctionsLocked()
        internal
        virtual
        override
        returns (bool)
    {
        return
            executeManager.isExecutable(this.settle.selector) ||
            executeManager.isExecutable(this.trade.selector);
    }

    function _receiveFunds(
        address from,
        uint amount
    ) internal virtual override returns (uint) {
        if (msg.sender != from) revert SenderNotMatch(msg.sender, from);
        if (msg.value != amount) revert ReceiveValueNotMatch(amount, msg.value);

        try IWWEMIX(address(token)).deposit{value: amount}() {
            return msg.value;
        } catch Error(string memory reason) {
            revert RevertMsg(reason);
        } catch Panic(uint errCode) {
            revert PanicMsg(errCode);
        } catch (bytes memory reason) {
            revert ErrMsg(reason);
        }
    }

    function _transferFunds(address to, uint amount) internal virtual override {
        try IWWEMIX(address(token)).withdraw(amount) {
            (bool status, ) = to.call{value: amount}("");
            if (!status) revert TransferWemixFail(to, amount);
        } catch Error(string memory reason) {
            revert RevertMsg(reason);
        } catch Panic(uint errCode) {
            revert PanicMsg(errCode);
        } catch (bytes memory reason) {
            revert ErrMsg(reason);
        }
    }
}
