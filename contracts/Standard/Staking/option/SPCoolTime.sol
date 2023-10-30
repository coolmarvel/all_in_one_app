// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../base/SPBase.sol";
import "../interface/ISPCoolTime.sol";

/**
 * @title SPCoolTime
 * @author Wemade Pte, Ltd
 * @dev This contract sets the cool-time for users to use staking, unstaking, and claim.
 */
abstract contract SPCoolTime is ISPCoolTime, SPBase {
    //===== VARIABLES =====//
    uint public override stakeCoolTime; // cool-time of stkaing
    uint public override unstakeCoolTime; // cool-time of unstaking
    uint public override claimCoolTime; // cool-time of claim

    bytes32 private constant FORCE_STAKE = "forced-stake-cooltime"; // column of forced staking before cool-time
    bytes32 private constant FORCE_UNSTAKE = "forced-unstake-cooltime"; // column of forced unstaking before cool-time
    bytes32 private constant FORCE_CLAIM = "forced-claim-cooltime"; // column of forced claim before cool-time

    //===== EXTERNAL FUNCTIONS =====//
    /**
     * @dev Set cool-time of staking
     */
    function setStakeCoolTime(uint coolTime) external onlyOwner {
        stakeCoolTime = coolTime;
    }

    /**
     * @dev Set cool-time of unstaking
     */
    function setUnstakeCoolTime(uint coolTime) external onlyOwner {
        unstakeCoolTime = coolTime;
    }

    /**
     * @dev Set cool-time of claim
     */
    function setClaimCoolTime(uint coolTime) external onlyOwner {
        claimCoolTime = coolTime;
    }

    /**
     * @dev Set fee percents of forced enoforce before cool-time
     * @param stakeVal value of the fee perecent of staking
     * @param unstakeVal value of the fee perecent of unstaking
     * @param claimVal value of the fee perecent of claim
     */
    function setCoolTimeForceFeePercent(
        uint stakeVal,
        uint unstakeVal,
        uint claimVal
    ) external onlyOwner {
        _setFeePercent(FORCE_STAKE, stakeVal);
        _setFeePercent(FORCE_UNSTAKE, unstakeVal);
        _setFeePercent(FORCE_CLAIM, claimVal);
    }

    //===== PUBLIC FUNCTIONS =====//
    /**
     * @dev To get the user's cool-time of staking has passed
     * @param user user's address
     */
    function isPassedStakeCoolTime(
        address user
    ) public view override returns (bool) {
        return
            stakedBlock(user) == 0
                ? true
                : stakedBlock(user) + stakeCoolTime <= block.number;
    }

    /**
     * @dev To get the user's cool-time of unstaking has passed
     * @param user user's address
     */
    function isPassedUnstakeCoolTime(
        address user
    ) public view override returns (bool) {
        return
            unstakedBlock(user) == 0
                ? true
                : unstakedBlock(user) + unstakeCoolTime <= block.number;
    }

    /**
     * @dev To get the user's cool-time of claim has passed
     * @param user user's address
     */
    function isPassedClaimCoolTime(
        address user
    ) public view override returns (bool) {
        return
            claimedBlock(user) == 0
                ? true
                : claimedBlock(user) + claimCoolTime <= block.number;
    }

    /**
     * @dev To get the user's remain cool-time of stake
     * @param user user's address
     */
    function remainStakeCoolTime(
        address user
    ) public view override returns (uint) {
        return
            isPassedStakeCoolTime(user)
                ? 0
                : stakedBlock(user) + stakeCoolTime - block.number;
    }

    /**
     * @dev To get the user's remain cool-time of unstake
     * @param user user's address
     */
    function remainUnstakeCoolTime(
        address user
    ) public view override returns (uint) {
        return
            isPassedUnstakeCoolTime(user)
                ? 0
                : unstakedBlock(user) + unstakeCoolTime - block.number;
    }

    /**
     * @dev To get the user's remain cool-time of claim
     * @param user user's address
     */
    function remainClaimCoolTime(
        address user
    ) public view override returns (uint) {
        return
            isPassedClaimCoolTime(user)
                ? 0
                : claimedBlock(user) + claimCoolTime - block.number;
    }

    //===== INTERNAL FUNCTIONS =====//
    function _beforeStake(
        address user,
        uint amount
    ) internal view virtual override {
        if (
            !(isPassedStakeCoolTime(user) ||
                (!isPassedStakeCoolTime(user) && feePercent[FORCE_STAKE] > 0))
        ) revert NotPassedCoolTime("stake", user);
        if (
            !(isPassedClaimCoolTime(user) ||
                (!isPassedClaimCoolTime(user) && feePercent[FORCE_CLAIM] > 0))
        ) revert NotPassedCoolTime("claim", user);

        super._beforeStake(user, amount);
    }

    function _beforeUnstake(
        address user,
        uint amount
    ) internal view virtual override {
        if (
            !(isPassedUnstakeCoolTime(user) ||
                (!isPassedUnstakeCoolTime(user) &&
                    feePercent[FORCE_UNSTAKE] > 0))
        ) revert NotPassedCoolTime("unstake", user);
        if (
            !(isPassedClaimCoolTime(user) ||
                (!isPassedClaimCoolTime(user) && feePercent[FORCE_CLAIM] > 0))
        ) revert NotPassedCoolTime("claim", user);

        super._beforeUnstake(user, amount);
    }

    function _beforeClaim(address user) internal view virtual override {
        if (
            !(isPassedClaimCoolTime(user) ||
                (!isPassedClaimCoolTime(user) && feePercent[FORCE_CLAIM] > 0))
        ) revert NotPassedCoolTime("claim", user);

        super._beforeClaim(user);
    }

    function _stakeFeePercents(
        address user
    ) internal view virtual override returns (bytes32[] memory columns) {
        columns = super._stakeFeePercents(user);
        if (!isPassedStakeCoolTime(user) && feePercent[FORCE_STAKE] > 0)
            columns = _addFee(feePercent[FORCE_STAKE], FORCE_STAKE, columns);
    }

    function _unstakeFeePercents(
        address user
    ) internal view virtual override returns (bytes32[] memory columns) {
        columns = super._unstakeFeePercents(user);
        if (!isPassedUnstakeCoolTime(user) && feePercent[FORCE_UNSTAKE] > 0)
            columns = _addFee(
                feePercent[FORCE_UNSTAKE],
                FORCE_UNSTAKE,
                columns
            );
    }

    function _claimFeePercents(
        address user
    ) internal view virtual override returns (bytes32[] memory columns) {
        columns = super._claimFeePercents(user);
        if (!isPassedClaimCoolTime(user) && feePercent[FORCE_CLAIM] > 0)
            columns = _addFee(feePercent[FORCE_CLAIM], FORCE_CLAIM, columns);
    }
}
