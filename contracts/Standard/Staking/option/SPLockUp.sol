// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../base/SPBase.sol";
import "../interface/ISPLockUp.sol";

/**
 * @title SPLockUp
 * @author Wemade Pte, Ltd
 * @dev This contract sets the lock-up for users to use unstaking.
 */
abstract contract SPLockUp is ISPLockUp, SPBase {
    //===== VARIABLES =====//
    uint public override globalLu; // global lock-up d-day
    uint public override userLu; // user's lock-up period

    bytes32 private constant FORCE_UNSTAKE = "forced-unstake-lockup"; // column of forced unstaking before cool-time

    mapping(address => uint) public override firstStakedBlock; // user's first staked block number

    //===== EXTERNAL FUNCTIONS =====//
    /**
     * @dev Set lock-up
     * @param _globalLu global lock-up
     * @param _userLu user lock-up
     */
    function setLockUp(uint _globalLu, uint _userLu) external onlyOwner {
        globalLu = _globalLu;
        userLu = _userLu;
    }

    /**
     * @dev Set fee percent of forces unstaking before user's lock-up period
     * @param value value of the fee perecent
     */
    function setUserLockUpFeePercent(uint value) external onlyOwner {
        _setFeePercent(FORCE_UNSTAKE, value);
    }

    //===== PUBLIC FUNCTIONS =====//
    /**
     * @dev To get remain block number until the global lock-up is over
     */
    function remainGlobalLockUp() public view override returns (uint) {
        return isPassedGlobalLockUp() ? 0 : globalLu - block.number;
    }

    /**
     * @dev To get remain block number until the user's lock-up is over
     * @param user user's address
     */
    function remainUserLockUp(
        address user
    ) public view override returns (uint) {
        return
            isPassedUserLockUp(user)
                ? 0
                : (firstStakedBlock[user] + userLu) - block.number;
    }

    /**
     * @dev Check the global lock-up is over
     */
    function isPassedGlobalLockUp() public view override returns (bool) {
        return globalLu <= block.number;
    }

    /**
     * @dev Check the user's lock-up is over
     * @param user user's address
     */
    function isPassedUserLockUp(
        address user
    ) public view override returns (bool) {
        return (firstStakedBlock[user] + userLu) <= block.number;
    }

    //===== INTERNAL FUNCTIONS =====//
    function _afterStake(
        address user,
        uint amount,
        uint totalFee
    ) internal virtual override {
        super._afterStake(user, amount, totalFee);

        if (firstStakedBlock[user] == 0) firstStakedBlock[user] = block.number;
    }

    function _beforeUnstake(
        address user,
        uint amount
    ) internal view virtual override {
        if (!isPassedGlobalLockUp())
            revert NotPassGlobalLockUp(block.number, globalLu);
        if (
            !(isPassedUserLockUp(user) ||
                (!isPassedUserLockUp(user) && feePercent[FORCE_UNSTAKE] > 0))
        )
            revert NotPassUserLockUp(
                user,
                firstStakedBlock[user],
                (firstStakedBlock[user] + userLu)
            );

        super._beforeUnstake(user, amount);
    }

    function _unstakeFeePercents(
        address user
    ) internal view virtual override returns (bytes32[] memory columns) {
        columns = super._unstakeFeePercents(user);
        if (!isPassedUserLockUp(user) && feePercent[FORCE_UNSTAKE] > 0)
            columns = _addFee(
                feePercent[FORCE_UNSTAKE],
                FORCE_UNSTAKE,
                columns
            );
    }
}
