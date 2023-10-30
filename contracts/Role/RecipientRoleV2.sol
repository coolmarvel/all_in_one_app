// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "../../contracts/openzeppelin-contracts/access/Ownable.sol";
import "../../contracts/openzeppelin-contracts/token/ERC20/IERC20.sol";
import "../../contracts/openzeppelin-contracts/utils/Address.sol";
import "./IRecipientRoleV2.sol";

/**
 * @title RecipientRoleV2
 * @author Wemade Pte, Ltd
 * @dev RecipientRoleV2 contract to be deployed in wemix.
 * RecipientRole V2 is a contract that records incomes by service.
 *
 * Set the recipient for each service and
 *    immediately send tokens to the recipient of the wemix and the recipient of the service
 *    whenever incomes are made.
 */
contract RecipientRoleV2 is IRecipientRoleV2, Ownable {
    using Address for address;
    address private _recipient; // wemix recipient
    mapping(bytes32 => address) public services; // service's address => recipient

    constructor(address recipient) {
        _recipient = recipient;
    }

    /** @dev External function that checks whether the address is registered as wemix's recipient
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
        require(
            services[service] == address(0),
            "RecipientRoleV2: already added"
        );
        services[service] = account;
    }

    /** @dev External function to remove registered service
     *  @param service The address of the service
     */
    function removeService(bytes32 service) external override onlyOwner {
        require(
            services[service] != address(0),
            "RecipientRoleV2: invalid service"
        );
        delete (services[service]);
    }

    /** @dev External function that changes the wemix's recipient of a registered service
     *  @param account The address of the service
     */
    function changeRecipient(address account) external override onlyOwner {
        _recipient = account;
        emit RecipientChanged("RecipientRoleV2", account);
    }

    /** @dev External function that changes the service's recipient of a registered service
     *  @param service The address of the service
     *  @param account Recipient of the service
     */
    function changeServiceRecipient(
        bytes32 service,
        address account
    ) external override onlyOwner {
        require(account != address(0), "RecipientRoleV2: invalid account");
        require(
            services[service] != address(0),
            "RecipientRoleV2: invalid service"
        );
        services[service] = account;
        emit RecipientChanged(service, account);
    }

    /** @dev External functions called when incomes are generated
     *  Send tokens to recipients of wemix and service
     *  Emit a log with the given content.
     *  @param token address of the income token
     *  @param column kind of income
     *  @param amount income amount
     *  @param percentToOwner ratio of wemix recipients to income.
     */
    function addIncome(
        bytes32 service,
        address token,
        bytes32 column,
        uint256 amount,
        uint256 percentToOwner
    ) external override returns (bool) {
        require(percentToOwner <= 100, "RecipientRoleV2: invalid percent data");
        require(
            _recipient != address(0) && services[service] != address(0),
            "RecipientRoleV2: invalid service"
        );
        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            "RecipientRoleV2: transferFrom error to owner"
        );
        unchecked {
            uint256 toOwner = (amount * percentToOwner) / 100;
            if (toOwner > 0) {
                require(
                    IERC20(token).transfer(_recipient, toOwner),
                    "RecipientRoleV2: transferFrom error to owner"
                );
            }
            require(
                amount >= toOwner,
                "RecipientRoleV2: toOwner exceeds amount"
            );

            uint256 toService = amount - toOwner;
            if (toService > 0) {
                require(
                    IERC20(token).transfer(services[service], amount - toOwner),
                    "RecipientRoleV2: transferFrom error to service"
                );
            }
            emit IncomeAddedV2(service, token, column, toOwner, toService);
        }
        return true;
    }
}
