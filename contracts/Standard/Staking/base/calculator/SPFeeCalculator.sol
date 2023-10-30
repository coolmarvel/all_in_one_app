// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../../interface/ISPError.sol";
import "../../../../../projects/RecipientRole/contracts/IRecipientRole.sol";
import "../../../../openzeppelin-contracts/utils/Address.sol";
import "../../../../openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title SPFeeCalculator
 * @author Wemade Pte, Ltd
 * @dev This contract manage fee of staking, unstaking, and claim.
 */
abstract contract SPFeeCalculator is ISPError {
    using Address for address;
    using SafeERC20 for IERC20;

    //===== VARIABLES =====//
    uint public constant DENOMINATOR = 1 ether;
    bytes32 public service; // service name ex) MIRM_DIVINE_STAKING
    address public recipientRole; // RecipientRole address
    mapping(bytes32 => uint) public feePercent; // fee percent of column ex) feePercenct["forced-stake-coolTime"]

    event EnforcedWithFee(
        address user,
        address token,
        bytes32 indexed column,
        uint amount,
        uint fee
    );

    constructor(bytes32 _service, address _recipientRole) {
        if (!_recipientRole.isContract()) revert InvalidAddress(_recipientRole);
        recipientRole = _recipientRole;
        service = _service;
    }

    //===== INTERNAL FUNCTIONS =====//
    /**
     * @dev Set the fee percent of the column
     * @param column column to set fee percent
     * @param value value of fee percent
     */
    function _setFeePercent(bytes32 column, uint value) internal {
        if (value > DENOMINATOR) revert OverValue(value, value);
        feePercent[column] = value;
    }

    /**
     * @dev Add fee column to array of fee columns
     * @param percent fee percent of the column to add
     * @param column column to add
     * @param columns array of columns add the column
     */
    function _addFee(
        uint percent,
        bytes32 column,
        bytes32[] memory columns
    ) internal pure returns (bytes32[] memory) {
        if (percent > 0) {
            uint len = columns.length;
            bytes32[] memory newColumns = new bytes32[](len + 1);
            for (uint i = 0; i < len; i++) {
                newColumns[i] = columns[i];
            }
            newColumns[len] = column;
            columns = newColumns;
        }
        return columns;
    }

    /** @dev Internal function called when incomes are generated
     *  Send tokens to recipients of wemix and service
     *  Emit a log with the given content.
     *  @param amount origin amount
     *  @param user address of user to pay commission
     *  @param token address of the income token
     *  @param columns kinds of income
     */
    function _addIncome(
        uint amount,
        address user,
        address token,
        bytes32[] memory columns
    ) internal returns (uint, uint) {
        uint totalFee;
        for (uint i = 0; i < columns.length; i++) {
            uint fee = (amount * feePercent[columns[i]]) / DENOMINATOR;
            IERC20(token).safeApprove(recipientRole, fee);
            require(
                IRecipientRole(recipientRole).addIncome(
                    token,
                    service,
                    columns[i],
                    fee
                )
            );
            totalFee = totalFee + fee;
            emit EnforcedWithFee(user, token, columns[i], amount, fee);
        }
        if (amount < totalFee) revert UnderValue(amount, totalFee);
        amount = amount - totalFee;

        return (amount, totalFee);
    }

    /**
     * @dev To get fee percent of staking of the user
     * @param user user's address
     */
    function _stakeFeePercents(
        address user
    ) internal view virtual returns (bytes32[] memory columns) {}

    /**
     * @dev To get fee percent of unstaking of the user
     * @param user user's address
     */
    function _unstakeFeePercents(
        address user
    ) internal view virtual returns (bytes32[] memory columns) {}

    /**
     * @dev To get fee percent of claim of the user
     * @param user user's address
     */
    function _claimFeePercents(
        address user
    ) internal view virtual returns (bytes32[] memory columns) {}
}
