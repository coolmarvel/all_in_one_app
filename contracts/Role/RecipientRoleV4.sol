// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "../openzeppelin-contracts/access/Ownable.sol";
import "../openzeppelin-contracts/utils/Address.sol";
import "../openzeppelin-contracts/utils/Counters.sol";
import "./IRecipientRoleV4.sol";

/**
 * @title RecipientRoleV4
 * @author Wemade Pte, Ltd
 * @dev RecipientRoleV4 contract to be deployed in wemix.
 * RecipientRole V4 is a contract that records incomes by wallets.
 *
 * Set the recipient and fee for each wallet and
 *    immediately send tokens to the recipient of the wemix and the recipient of the wallet
 *    whenever incomes are made.
 */
contract RecipientRoleV4 is IRecipientRoleV4, Ownable {
    using Address for address;
    using Counters for Counters.Counter;
    struct Wallet {
        address account;
        uint fee;
        bytes32 name;
    }
    struct WalletInfo {
        bool isAllAdded;
        Wallet[] wallets;
    }
    address private _recipient; // wemix recipient
    uint public incomeToPlatformPercent;
    uint public constant DENOMINATOR = 1000;
    mapping(bytes32 => WalletInfo) private _walletInfos; // Wallet info

    constructor(address recipient, uint percent) {
        require(recipient != address(0), "RecipientRoleV4: invalid address");
        require(percent < DENOMINATOR, "RecipientRoleV4: invalid percent");

        _recipient = recipient;
        incomeToPlatformPercent = percent;
    }

    /** @dev External functions called when incomes are generated
     *  Send tokens to recipients of wemix and wallet
     *  Emit a log with the given content.
     *  @param service name of service
     *  @param token address of the income token
     *  @param column kind of income
     *  @param amount income amount
     */
    function addIncome(
        bytes32 service,
        address token,
        bytes32 column,
        uint amount
    ) external override returns (bool) {
        require(
            _walletInfos[service].isAllAdded,
            "RecipientRoleV4: the all wallets of game must be added"
        );
        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            "RecipientRoleV4: transferFrom error to owner"
        );

        uint toOwner;
        unchecked {
            for (uint i = 0; i < _walletInfos[service].wallets.length; i++) {
                Wallet memory _elem = _walletInfos[service].wallets[i];
                if (i == 0) {
                    toOwner = (amount * _elem.fee) / DENOMINATOR;
                }
                uint toWallet = (amount * _elem.fee) / DENOMINATOR;

                if (toWallet > 0) {
                    require(
                        IERC20(token).transfer(_elem.account, toWallet),
                        "RecipientRoleV4: transfer error to wallet"
                    );

                    emit IncomeAddedV4(
                        service,
                        _elem.name,
                        token,
                        column,
                        toWallet
                    );
                }
            }
            // amount always bigger than toOwner
            emit AllIncomeAdded(
                service,
                token,
                column,
                toOwner,
                amount - toOwner
            );
        }

        return true;
    }

    /** @dev External functions called when incomes of minting are generated
     *  Send tokens to recipients of wemix
     *  Emit a log with the given content.
     *  @param token address of the income token
     *  @param amount income amount
     */
    function addMintIncome(
        address token,
        uint amount
    ) external override returns (bool) {
        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            "RecipientRoleV4: transferFrom error to owner"
        );
        require(
            IERC20(token).transfer(_recipient, amount),
            "RecipientRoleV4: transfer error to owner"
        );

        emit MintIncomeAdded(token, amount);
        return true;
    }

    /** @dev External function that registers the recipient of the wallet
     *  @param service name of service
     *  @param names name of the wallet
     *  @param accounts recipient of the wallet
     *  @param fees fee the wallet deserves
     */
    function addWallet(
        bytes32 service,
        bytes32[] memory names,
        address[] memory accounts,
        uint[] memory fees
    ) external onlyOwner {
        require(
            _walletInfos[service].wallets.length == 0,
            "RecipientRoleV4: the game's wallets already registered"
        );
        _initWallet(service);
        uint size = names.length;
        require(
            size == accounts.length && size == fees.length,
            "RecipientRoleV4: all array's length must be same"
        );
        uint totalFee = _walletInfos[service].wallets[0].fee;
        for (uint i = 0; i < size; i++) {
            require(
                accounts[i] != address(0),
                "RecipientRoleV4: invalid address"
            );
            require(
                fees[i] < DENOMINATOR,
                "RecipientRoleV4: invalid fee percent"
            );
            Wallet[] memory wallets = _walletInfos[service].wallets;
            for (uint j = 0; j < wallets.length; j++) {
                require(
                    accounts[i] != wallets[j].account,
                    "RecipientRoleV4: already added address"
                );
            }
            _walletInfos[service].wallets.push(
                Wallet({name: names[i], account: accounts[i], fee: fees[i]})
            );
            totalFee += fees[i];
        }
        require(
            totalFee == DENOMINATOR,
            "RecipientRoleV4: the sum of fee must be 1000"
        );

        _walletInfos[service].isAllAdded = true;
    }

    /** @dev External function to remove registered wallet
     *  @param service name of service
     */
    function removeAll(bytes32 service) external onlyOwner {
        if (_walletInfos[service].wallets.length > 0) {
            delete _walletInfos[service];
        }
    }

    /** @dev External function that changes the wemix's recipient of a registered wallet
     *  @param account The address of the wallet
     */
    function changeRecipient(address account) external onlyOwner {
        require(
            account != address(0) && !account.isContract(),
            "RecipientRoleV4: invalid address"
        );
        _recipient = account;
        emit RecipientChanged("RecipientRoleV4", _recipient);
    }

    /** @dev External function that changes the wemix's fee percentage
     *  @param percent The percentage of fee for wemix wallet
     */
    function changeIncomeToPlatformPercent(uint percent) external onlyOwner {
        require(percent < DENOMINATOR, "RecipientRoleV4: invalid percent");
        incomeToPlatformPercent = percent;
        emit OptiongChanged("IncomeToPlatformPercent", incomeToPlatformPercent);
    }

    /** @dev External function to get registered wallet
     *  @param service name of service
     *  @param index The index of the wallet
     */
    function getWallet(
        bytes32 service,
        uint index
    ) external view override returns (bytes32 name, address account, uint fee) {
        Wallet memory _elem = _walletInfos[service].wallets[index];
        name = _elem.name;
        account = _elem.account;
        fee = _elem.fee;
    }

    /** @dev External function that checks whether the address is registered as wemix's recipient
     *  @param account check if it's recipients
     *  @return _ Whether it's the recipient or not
     */
    function isRecipient(
        address account
    ) external view override returns (bool) {
        return account == _recipient;
    }

    /** @dev External function that checks whether the address is registered as wemix's recipient
     *  @param service service name
     *  @return _ Whether the service's wallets all added or not
     */
    function isWalletAdded(
        bytes32 service
    ) external view override returns (bool) {
        return _walletInfos[service].isAllAdded;
    }

    function _initWallet(bytes32 service) private {
        _walletInfos[service].wallets.push(
            Wallet({
                name: "wemix",
                account: _recipient,
                fee: incomeToPlatformPercent
            })
        );
    }
}
