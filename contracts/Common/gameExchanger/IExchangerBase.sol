// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../token/WWEMIX/IWWEMIX.sol";
import "../../openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IExchangerBase {
    //===== STRUCTS =====//
    struct Item {
        address seller; // address of seller
        uint price; // item price for sale
        bytes32 id; // id for mapping off-chain db
        bytes32 product; // product name for mapping off-chain db
    }

    struct Wallet {
        address account; // fee distribution account
        uint fee; // fee ratio
        bytes32 name; // name of distribution account
    }

    struct ExchangerInfo {
        bool isSettleImmediately; // flag that check settle immediately
        uint tradeFee; // trade fee
        Wallet[] wallets; // array of distribution accounts
        Item[] sellingItems; // array of selling items
        mapping(bytes32 => bool) isRegisteredItem; // check item id already registered
        mapping(address => bool) isRegisteredWallet; // check wallet address already registered
    }

    /**
     *  only for view function
     *  ExchangerInfo has mapping data structure
     *  Mapping data structure can not be memory/calldata type
     *  So it can not be returned by external functions
     */
    struct ExchangerInfoView {
        bool isSettleImmediately; // flag that check settle immediately
        uint tradeFee; // trade fee
        Wallet[] wallets; // array of distribution accounts
        Item[] sellingItems; // array of selling items
    }

    struct Receipt {
        bool isReceived; // seller receive status
        bytes32 exchanger; // exchanger name
        uint sellerRevenue; // seller revenue
        uint tradeTime; // timestamp of traded
        Item item; // traded item
    }

    //===== FUNCTIONS =====//
    function registExchangerInfo(
        bytes32 exchanger,
        bool isSettleImmediately,
        uint tradeFee,
        Wallet[] calldata wallets
    ) external;

    function removeExchanger(bytes32 exchanger) external;

    function changeWallets(
        bytes32 exchanger,
        Wallet[] calldata wallets
    ) external;

    function registItem(
        Item calldata item,
        bytes32 exchanger,
        bytes calldata userSig,
        bytes calldata validatorSig
    ) external;

    function removeItem(
        bytes32 exchanger,
        uint index,
        bytes calldata userSig,
        bytes calldata validatorSig
    ) external;

    function settle(
        address user,
        uint[] memory tradeIDs,
        bytes calldata userSig,
        bytes calldata validatorSig
    ) external;

    //===== VIEW FUNCTIONS =====//
    function getExchangerInfo(
        bytes32 exchanger
    ) external view returns (ExchangerInfoView memory);

    function getWallets(
        bytes32 exchanger
    ) external view returns (Wallet[] memory);

    function getItemList(
        bytes32 exchanger
    ) external view returns (Item[] memory);

    function getReceipt() external view returns (Receipt[] memory);

    //===== EVENTS =====//
    event Traded(bytes32 indexed service, Receipt receipt);
    event ExchangerRegistered(
        bytes32 indexed service,
        bytes32 indexed exchanger,
        uint tradeFee
    );
    event Settled(address indexed user, uint indexed tradeID, Receipt receipt);
    event IncomeDistributed(
        bytes32 indexed exchanger,
        bytes32 indexed name,
        address indexed account,
        uint share
    );
    event ItemRegistered(bytes32 indexed exchanger, uint index, Item item);
    event ArrayMaxSizeChanged(uint newSize);
    event ItemRemoved(Item item);

    //===== ERRORS =====//
    error InvalidArraySize(uint maxSize, uint inputSize);
    error SettleStillExecutable();
    error NotRegistered(bytes32 exchanger);
    error NotSeller(address seller, address account);
    error StillSellingItems(bytes32 exchanger);
    error AlreadyRegistered(bytes32 exchanger);
    error AlreadyRegisteredWallet(address wallet);
    error AlreadyRegisteredItem(bytes32 id);
    error AlreadySettled(uint tradeId);
    error SellerMissMatch(uint tradeId, address seller, address input);
    error InvalidSumOfFees(uint sum);
    error InvalidFee(uint fee);
    error InvalidItemIndex(uint index);
    error SellerNotMatch(address input, address seller);
    error PriceNotMatch(uint expected, uint actual);
    error ZeroArray();
    error ZeroAddress();
}
