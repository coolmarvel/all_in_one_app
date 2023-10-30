// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../ExchangerBase.sol";
import "./IGameExchanger.sol";

abstract contract GameExchanger is ExchangerBase, IGameExchanger {
    using SafeERC20 for IERC20;
    using InitializationLibrary for address;

    //===== CONSTRUCTOR =====//
    constructor(
        address _token,
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
        _registFunctionSelector("trade", IGameExchanger.trade.selector);
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
        virtual
        nonReentrant
        onlyExecutable(this.trade.selector)
        isNotBlackList(msg.sender)
    {
        super._trade(
            IGameExchanger.trade.selector,
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
        uint beforeTransfer = token.balanceOf(address(this));
        token.safeTransferFrom(from, address(this), amount);
        return token.balanceOf(address(this)) - beforeTransfer;
    }

    function _transferFunds(address to, uint amount) internal virtual override {
        token.safeTransfer(to, amount);
    }
}
