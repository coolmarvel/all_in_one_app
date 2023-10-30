// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "../openzeppelin-contracts/access/Ownable.sol";
import "../openzeppelin-contracts/utils/math/SafeMath.sol";
import "../openzeppelin-contracts/token/ERC20/IERC20.sol";
import "../openzeppelin-contracts/utils/Address.sol";
import "./IRecipientRoleV3.sol";

/**
 * @title RecipientRoleV3
 * @author Wemade Tree Pte, Ltd
 * @dev RecipientRoleV3 contract to be deployed in wemix.
 * RecipientRole V3 is a contract that records incomes by service.
 *
 * Set the recipient for each service and
 *    immediately send tokens or coin to the recipient of the wemix or klay and the recipient of the service
 *    whenever incomes are made.
 */
contract RecipientRoleV3 is IRecipientRoleV3, Ownable {
    using SafeMath for uint;
    using Address for address;
    address private _recipient; // wemix, klay recipient
    mapping(bytes32 => address) public services; // service's address => recipient

    constructor(address recipient) {
        _recipient = recipient;
    }

    /** @dev External function that checks whether the address is registered as wemix's and klay's recipient
     *  @param account check if it's recipients
     *  @return Whether it's the recipient or not
     */
    function isRecipient(
        address account
    ) external view override returns (bool) {
        return account == _recipient;
    }

    /** @dev External function that registers the recipient of the service
     *  @param service The address of the service
     *  @param account Recipient of the service
     */
    function addService(
        bytes32 service,
        address account
    ) external override onlyOwner {
        require(account != address(0), "RecipientRoleV3: invalid account");
        require(
            services[service] == address(0),
            "RecipientRoleV3: already added"
        );
        services[service] = account;
    }

    /** @dev External function to remove registered service
     *  @param service The address of the service
     */
    function removeService(bytes32 service) external override onlyOwner {
        require(
            services[service] != address(0),
            "RecipientRoleV3: invalid service"
        );
        delete (services[service]);
    }

    /** @dev External function that changes the wemix's recipient of a registered service
     *  @param account The address of the service
     */
    function changeRecipient(address account) external override onlyOwner {
        _recipient = account;
        emit RecipientChanged("RecipientRoleV3", account);
    }

    /** @dev External function that changes the service's recipient of a registered service
     *  @param service The address of the service
     *  @param account Recipient of the service
     */
    function changeServiceRecipient(
        bytes32 service,
        address account
    ) external override onlyOwner {
        require(account != address(0), "RecipientRoleV3: invalid account");
        require(
            services[service] != address(0),
            "RecipientRoleV3: invalid service"
        );
        services[service] = account;
        emit RecipientChanged(service, account);
    }

    /** @dev External functions called when incomes are generated
     *  Send tokens to recipients of wemix and service
     *  Emit a log with the given content.
     *  @param token address of the income token. address(0) is klay coin
     *  @param column kind of income
     *  @param amount income amount
     *  @param percentToOwner ratio of token/klay recipients to income.
     */
    function addIncome(
        bytes32 service,
        address token,
        bytes32 column,
        uint amount,
        uint percentToOwner
    ) external payable override returns (bool) {
        require(percentToOwner <= 100, "RecipientRoleV3: invalid percent data");
        require(
            _recipient != address(0) && services[service] != address(0),
            "RecipientRoleV3: invalid service"
        );
        uint toOwner = amount.mul(percentToOwner).div(100);
        uint toService = amount.sub(toOwner);
        if (token == address(0)) {
            require(
                msg.value == amount,
                "RecipientRoleV3: transfer error to owner"
            );
            if (toOwner > 0) {
                (bool success, ) = payable(_recipient).call{value: toOwner}("");
                require(success, "RecipientRoleV3: transfer error to owner");
            }

            if (toService > 0) {
                (bool success, ) = payable(services[service]).call{
                    value: toService
                }("");
                require(success, "RecipientRoleV3: transfer error to service");
            }
        } else {
            require(
                IERC20(token).transferFrom(msg.sender, address(this), amount),
                "RecipientRoleV3: transferFrom error to owner"
            );
            if (toOwner > 0) {
                require(
                    IERC20(token).transfer(_recipient, toOwner),
                    "RecipientRoleV3: transfer error to owner"
                );
            }

            if (toService > 0) {
                require(
                    IERC20(token).transfer(services[service], toService),
                    "RecipientRoleV3: transfer error to service"
                );
            }
        }
        emit IncomeAddedV3(service, token, column, toOwner, toService);
        return true;
    }
}
