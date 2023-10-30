// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../VerifyKey.sol";
import "./IExchangerBase.sol";
import "../utils/Converter.sol";
import "../initialization/InitializationRecipientRole.sol";
import "../../openzeppelin-contracts/security/ReentrancyGuard.sol";
import "../../openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import "../../openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract ExchangerBase is
    InitializationRecipientRole,
    VerifyKey,
    ReentrancyGuard,
    IExchangerBase
{
    using Address for address;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    //===== VARIABLES =====//
    uint public constant DENOMINATOR = 1 ether;
    bytes32 public constant INCOME_EXCHANGE = "exchange";
    bytes32 private constant EMPTY_ITEM = "empty item";

    IERC20 public immutable token;
    bytes32 public immutable service;
    address public immutable treasury;

    uint public arrayMaxSize = 500;
    Receipt[] internal _receiptInfo; // receipt informations

    mapping(bytes32 => ExchangerInfo) internal _exchangerInfos; // exchanger name => exchanger info
    mapping(bytes32 => mapping(address => Item[])) internal _userSellingItems;

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
        InitializationRecipientRole(
            _validatorRole,
            _setterRole,
            _roleManager,
            _executeManager,
            _blackList,
            _recipientRole
        )
    {
        if (!_token.isContract()) revert InvalidAddress("token", _token);
        if (_treasury == address(0))
            revert InvalidAddress("treasury", _treasury);

        token = IERC20(_token);
        service = _service;
        treasury = _treasury;

        _registFunctionSelector(
            "registItem",
            IExchangerBase.registItem.selector
        );
        _registFunctionSelector(
            "removeItem",
            IExchangerBase.removeItem.selector
        );
        _registFunctionSelector("settle", IExchangerBase.settle.selector);
    }

    //===== FUNCTIONS =====//
    /** @dev External function to regist exchanger
     *  @param exchanger name of exchanger
     *  @param tradeFee fee of exchanger
     *  @param wallets informations of income wallets
     */
    function registExchangerInfo(
        bytes32 exchanger,
        bool isSettleImmediately,
        uint tradeFee,
        Wallet[] calldata wallets
    )
        external
        virtual
        override
        onlyValidator
        onlyExecutable(this.registExchangerInfo.selector)
        isNotBlackList(msg.sender)
    {
        Wallet[] memory _wallets = wallets;
        bytes32 _exchanger = exchanger;

        if (_wallets.length == 0) revert ZeroArray();

        ExchangerInfo storage info = _exchangerInfos[_exchanger];

        if (info.wallets.length != 0) revert AlreadyRegistered(_exchanger);
        info.isSettleImmediately = isSettleImmediately;
        info.tradeFee = tradeFee;

        // push empty element to make itemIdx starts 1
        info.sellingItems.push(
            Item({
                seller: address(0),
                price: 0,
                id: EMPTY_ITEM,
                product: EMPTY_ITEM
            })
        );

        _registerWallets(_wallets, info);

        emit ExchangerRegistered(service, _exchanger, tradeFee);
    }

    /** @dev External function to remove registered wallet
     *  @param exchanger name of exchanger
     */
    function removeExchanger(
        bytes32 exchanger
    )
        external
        virtual
        override
        onlyValidator
        onlyExecutable(this.removeExchanger.selector)
        isNotBlackList(msg.sender)
    {
        bytes32 _exchanger = exchanger;
        ExchangerInfo storage info = _exchangerInfos[_exchanger];

        if (info.wallets.length == 0) revert NotRegistered(_exchanger);
        /**
         *  can remove exchanger when any items are not registered
         *  sellingItems must have empty element in index 0
         *  itemIdxs already delete all elements
         */
        if (info.sellingItems.length > 1) revert StillSellingItems(_exchanger);

        // remove wallet
        Wallet[] memory wallets = info.wallets;

        for (uint i = 0; i < wallets.length; ) {
            info.isRegisteredWallet[wallets[i].account] = false;
            unchecked {
                i += 1;
            }
        }

        delete _exchangerInfos[_exchanger];
    }

    /**
     *  @dev External function to change wallet informations of exchangers.
     *  Can change wallets when settle and trade functions were lost function executable.
     *  @param exchanger target exchanger key
     *  @param wallets new wallet informations
     */
    function changeWallets(
        bytes32 exchanger,
        Wallet[] calldata wallets
    )
        external
        virtual
        override
        onlyValidator
        onlyExecutable(this.changeWallets.selector)
        isNotBlackList(msg.sender)
    {
        bytes32 _exchanger = exchanger;
        ExchangerInfo storage info = _exchangerInfos[_exchanger];
        if (_isAllSettleFunctionsLocked()) revert SettleStillExecutable();
        // can remove exchanger when any items are not registered
        if (info.wallets.length == 0) revert NotRegistered(_exchanger);

        // remove wallet
        Wallet[] memory _wallets = info.wallets;

        for (uint i = 0; i < _wallets.length; i++) {
            info.isRegisteredWallet[_wallets[i].account] = false;
        }

        delete info.wallets;

        // register wallet
        _registerWallets(wallets, info);
    }

    /**
     *  @dev regist item for sale
     *  @param item information of item for sale
     *  @param exchanger name of exchanger
     *  @param userSig user signature
     *  @param validatorSig validator signature
     */
    function registItem(
        Item calldata item,
        bytes32 exchanger,
        bytes calldata userSig,
        bytes calldata validatorSig
    )
        external
        virtual
        override
        onlyExecutable(this.registItem.selector)
        isNotBlackList(msg.sender)
    {
        Item memory _item = item;
        bytes32 _exchanger = exchanger;
        ExchangerInfo storage info = _exchangerInfos[_exchanger];

        if (info.wallets.length == 0) revert NotRegistered(_exchanger);
        if (info.isRegisteredItem[_item.id])
            revert AlreadyRegisteredItem(_item.id);

        _verifySignature(
            _item.seller,
            abi.encodePacked(
                _getVerifyKey(_item.seller, IExchangerBase.registItem.selector),
                _item.seller,
                _item.price,
                _item.id,
                _item.product,
                _exchanger
            ),
            userSig,
            validatorSig
        );
        _renewSeed(_item.seller);

        // insert selling item
        info.sellingItems.push(_item);
        info.isRegisteredItem[_item.id] = true;

        emit ItemRegistered(_exchanger, info.sellingItems.length - 1, _item);
    }

    /**
     *   @dev remove item from exchager
     *   @param exchanger name of exchagner
     *   @param index item index
     *   @param userSig user signature
     *   @param validatorSig validator signature
     */
    function removeItem(
        bytes32 exchanger,
        uint index,
        bytes calldata userSig,
        bytes calldata validatorSig
    )
        external
        virtual
        override
        onlyExecutable(this.removeItem.selector)
        isNotBlackList(msg.sender)
    {
        uint _index = index;
        bytes32 _exchanger = exchanger;
        ExchangerInfo storage info = _exchangerInfos[_exchanger];

        if (_index == 0 || _index >= info.sellingItems.length)
            revert InvalidItemIndex(_index);

        Item memory item = info.sellingItems[_index];

        _verifySignature(
            item.seller,
            abi.encodePacked(
                _getVerifyKey(item.seller, IExchangerBase.removeItem.selector),
                item.seller,
                item.price,
                item.id,
                item.product,
                _exchanger
            ),
            userSig,
            validatorSig
        );
        _renewSeed(item.seller);

        _removeItem(info, _index);
    }

    /** @dev External function to settle to user
     *  @param user address of seller
     *  @param indexes array of receipt indexes
     *  @param userSig sign of seller
     *  @param validatorSig sign of registered validator (userSig)
     */
    function settle(
        address user,
        uint[] memory indexes,
        bytes calldata userSig,
        bytes calldata validatorSig
    )
        external
        virtual
        nonReentrant
        onlyExecutable(this.settle.selector)
        isNotBlackList(msg.sender)
    {
        address _user = user;
        uint size = indexes.length;
        if (size == 0 || size > arrayMaxSize)
            revert InvalidArraySize(arrayMaxSize, size);

        _verifySignature(
            _user,
            abi.encodePacked(
                _getVerifyKey(_user, IExchangerBase.settle.selector),
                _user,
                indexes
            ),
            userSig,
            validatorSig
        );
        _renewSeed(_user);

        uint totalSettleAmount = 0;

        for (uint i = 0; i < size; i++) {
            totalSettleAmount += _receiptInfo[indexes[i]].sellerRevenue;
        }

        token.safeTransferFrom(treasury, address(this), totalSettleAmount);

        for (uint i = 0; i < size; i++) {
            _settle(_user, indexes[i]);
        }
    }

    /**
     *  @dev change settle arrayMaxSize by setter
     *  @param newSize new settle arrayMaxSize
     */
    function changeArrayMaxSize(
        uint newSize
    )
        external
        virtual
        onlySetter(msg.sender)
        onlyExecutable(this.changeArrayMaxSize.selector)
        isNotBlackList(msg.sender)
    {
        arrayMaxSize = newSize;

        emit ArrayMaxSizeChanged(newSize);
    }

    //===== VIEW FUNCTIONS =====//
    function getExchangerInfo(
        bytes32 exchanger
    ) external view virtual override returns (ExchangerInfoView memory) {
        ExchangerInfo storage info = _exchangerInfos[exchanger];
        return
            ExchangerInfoView({
                isSettleImmediately: info.isSettleImmediately,
                tradeFee: info.tradeFee,
                wallets: info.wallets,
                sellingItems: info.sellingItems
            });
    }

    function getWallets(
        bytes32 exchanger
    ) external view virtual override returns (Wallet[] memory) {
        return _exchangerInfos[exchanger].wallets;
    }

    function getItemList(
        bytes32 exchanger
    ) external view virtual override returns (Item[] memory) {
        return _exchangerInfos[exchanger].sellingItems;
    }

    function getReceipt()
        external
        view
        virtual
        override
        returns (Receipt[] memory)
    {
        return _receiptInfo;
    }

    //===== INTERNAL FUNCTIONS =====//
    function _trade(
        bytes4 selector,
        address buyer,
        bytes32 exchanger,
        uint index,
        bytes calldata userSig,
        bytes calldata validatorSig
    ) internal virtual {
        address _buyer = buyer;
        uint _index = index;
        bytes32 _exchanger = exchanger;
        ExchangerInfo storage info = _exchangerInfos[_exchanger];

        if (_index == 0 || _index >= info.sellingItems.length)
            revert InvalidItemIndex(_index);

        Item memory item = info.sellingItems[index];

        _verifySignature(
            _buyer,
            abi.encodePacked(
                _getVerifyKey(_buyer, selector),
                _buyer,
                item.seller,
                item.price,
                item.id,
                item.product,
                _exchanger
            ),
            userSig,
            validatorSig
        );
        _renewSeed(_buyer);

        uint receiveAmount = _receiveFunds(_buyer, item.price);
        if (receiveAmount != item.price)
            revert PriceNotMatch(item.price, receiveAmount);
        uint totalFee = (receiveAmount * _exchangerInfos[_exchanger].tradeFee) /
            DENOMINATOR;

        _distribution(_exchanger, totalFee);

        // after trade
        Receipt memory newReceipit = Receipt({
            isReceived: false,
            exchanger: _exchanger,
            sellerRevenue: receiveAmount - totalFee,
            tradeTime: block.timestamp,
            item: item
        });

        _receiptInfo.push(newReceipit);

        // remove item after selling list
        _removeItem(info, _index);

        if (info.isSettleImmediately) {
            _settle(item.seller, _receiptInfo.length - 1);
        } else {
            token.safeTransfer(treasury, newReceipit.sellerRevenue);
        }

        emit Traded(service, _receiptInfo[_receiptInfo.length - 1]);
    }

    function _settle(address user, uint index) internal virtual {
        address _user = user;
        uint id = index;
        Receipt memory _receipt = _receiptInfo[id];

        if (_user != _receipt.item.seller)
            revert SellerNotMatch(_user, _receipt.item.seller);
        if (_receipt.isReceived) revert AlreadySettled(id);

        _transferFunds(_user, _receipt.sellerRevenue);

        _receiptInfo[id].isReceived = true;

        emit Settled(_user, id, _receipt);
    }

    function _distribution(bytes32 exchange, uint amount) internal virtual {
        ExchangerInfo storage info = _exchangerInfos[exchange];
        uint size = info.wallets.length;
        uint totalWallet = 0;
        // fee policy of wallets[size -1] is for recipient
        for (uint i = 0; i < size - 1; i++) {
            Wallet memory _elem = info.wallets[i];

            uint toWallet = (amount * _elem.fee) / DENOMINATOR;
            if (toWallet > 0) {
                _transferFunds(_elem.account, toWallet);
            }
            totalWallet += toWallet;

            emit IncomeDistributed(
                exchange,
                _elem.name,
                _elem.account,
                toWallet
            );
        }

        uint toRecipient = amount - totalWallet;

        token.safeApprove(address(recipientRole), toRecipient);
        recipientRole.addIncome(
            address(token),
            service,
            INCOME_EXCHANGE,
            toRecipient
        );

        emit IncomeDistributed(
            exchange,
            info.wallets[size - 1].name,
            info.wallets[size - 1].account,
            toRecipient
        );
    }

    function _getValidatorRole()
        internal
        view
        virtual
        override
        returns (bytes32)
    {
        return validatorRole;
    }

    function _isAllSettleFunctionsLocked() internal virtual returns (bool) {}

    function _receiveFunds(
        address from,
        uint amount
    ) internal virtual returns (uint) {}

    function _transferFunds(address to, uint amount) internal virtual {}

    //===== PRIVATE FUNCTIONS =====//
    function _removeItem(ExchangerInfo storage info, uint index) private {
        uint _index = index;

        Item memory targetItem = info.sellingItems[_index];

        // remove item
        uint lastIdx = info.sellingItems.length - 1;
        Item memory lastItem = info.sellingItems[lastIdx];
        info.sellingItems[_index] = lastItem;
        info.sellingItems.pop();

        info.isRegisteredItem[targetItem.id] = false;

        emit ItemRemoved(targetItem);
    }

    function _registerWallets(
        Wallet[] memory wallets,
        ExchangerInfo storage info
    ) private {
        uint totalFee = 0;
        Wallet[] memory _wallets = wallets;
        if (_wallets.length > arrayMaxSize)
            revert InvalidArraySize(arrayMaxSize, _wallets.length);
        for (uint i = 0; i < _wallets.length; i++) {
            if (_wallets[i].account == address(0)) revert ZeroAddress();
            if (info.isRegisteredWallet[_wallets[i].account])
                revert AlreadyRegisteredWallet(_wallets[i].account);
            if (_wallets[i].fee == 0 || _wallets[i].fee > DENOMINATOR)
                revert InvalidFee(_wallets[i].fee);

            info.wallets.push(_wallets[i]);

            info.isRegisteredWallet[_wallets[i].account] = true;

            unchecked {
                totalFee += _wallets[i].fee;
            }
        }

        if (totalFee != DENOMINATOR) revert InvalidSumOfFees(totalFee);
    }
}
