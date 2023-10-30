// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../base/SPBase.sol";
import "../interface/ISPLimit.sol";

/**
 * @title SPLimit
 * @author Wemade Pte, Ltd
 * @dev This contract sets the limit for users to use staking and unstaking.
 */
abstract contract SPLimit is ISPLimit, SPBase {
    //===== VARIABLES =====//
    uint public override stakeUnit; // unit amount of staking
    uint public override unstakeUnit; // unit amount of unstaking

    uint public override stakeMaxLimit; // maximum amount of staking once
    uint public override stakeMinLimit; // minimum amount of staking once
    uint public override unstakeMinLimit; // minimum amount of unstaking once

    uint public override stakeUserMaxLimit; // maximum amount user can stake
    uint public override stakeTotalMaxLimit; // maximum total amount user can stake

    //===== EXTERNAL FUNCTIONS =====//
    /**
     * @dev Set unit of staking
     */
    function setStakeUnit(uint amount) external onlyOwner {
        stakeUnit = amount;
    }

    /**
     * @dev Set unit of unstaking
     */
    function setUnstakeUnit(uint amount) external onlyOwner {
        unstakeUnit = amount;
    }

    /**
     * @dev Set limit maximum amount of staking
     */
    function setStakeMaxLimit(uint amount) external onlyOwner {
        if (amount < stakeMinLimit) revert UnderValue(amount, stakeMinLimit);
        stakeMaxLimit = amount;
    }

    /**
     * @dev Set limit minimum amount of staking
     */
    function setStakeMinLimit(uint amount) external onlyOwner {
        if (amount > stakeMaxLimit) revert OverValue(amount, stakeMaxLimit);
        stakeMinLimit = amount;
    }

    /**
     * @dev Set limit minimum amount of unstaking
     */
    function setUnstakeMinLimit(uint amount) external onlyOwner {
        unstakeMinLimit = amount;
    }

    /**
     * @dev Set limit maximum amount of total staking
     */
    function setStakeUserMaxLimit(uint amount) external onlyOwner {
        stakeUserMaxLimit = amount;
    }

    /**
     * @dev Set limit maximum amount of total staking
     */
    function setStakeTotalMaxLimit(uint amount) external onlyOwner {
        stakeTotalMaxLimit = amount;
    }

    //===== INTERNAL FUNCTIONS =====//
    function _beforeStake(
        address user,
        uint amount
    ) internal view virtual override {
        if (!(stakeUnit == 0 ? true : amount % stakeUnit == 0))
            revert InvalidUnit("stake", amount, stakeUnit);
        if (!(stakeMaxLimit == 0 ? true : amount <= stakeMaxLimit))
            revert OverStakeMaxLimit(amount, stakeMaxLimit);
        if (!(stakeMinLimit == 0 ? true : amount >= stakeMinLimit))
            revert UnderMinLimit("stake", amount, stakeMinLimit);
        _checkTotalLimit(user, amount);

        super._beforeStake(user, amount);
    }

    function _beforeUnstake(
        address user,
        uint amount
    ) internal view virtual override {
        if (!(unstakeUnit == 0 ? true : amount % unstakeUnit == 0))
            revert InvalidUnit("unstake", amount, unstakeUnit);
        if (!(unstakeMinLimit == 0 ? true : amount >= unstakeMinLimit))
            revert UnderMinLimit("unstake", amount, unstakeMinLimit);

        super._beforeUnstake(user, amount);
    }

    function _afterStake(
        address user,
        uint amount,
        uint totalFee
    ) internal virtual override {
        _checkTotalLimit(user, amount);

        super._afterStake(user, amount, totalFee);
    }

    function _checkTotalLimit(address user, uint amount) private view {
        if (
            !(
                stakeUserMaxLimit == 0
                    ? true
                    : (stakedAmount(user) + amount) <= stakeUserMaxLimit
            )
        ) {
            revert OverUserStakeMax(
                user,
                amount,
                stakedAmount(user),
                stakeUserMaxLimit
            );
        }
        if (
            !(
                stakeTotalMaxLimit == 0
                    ? true
                    : (totalStakedAmount() + amount) <= stakeTotalMaxLimit
            )
        ) {
            revert OverTotalStakeMax(
                user,
                amount,
                totalStakedAmount(),
                stakeTotalMaxLimit
            );
        }
    }
}
