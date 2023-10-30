// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../base/SPBase.sol";
import "../interface/ISPMultiPoint.sol";

/**
 * @title SPMultiPoint
 * @author Wemade Pte, Ltd
 * @dev This contract pays MultiPoint (MP) according to the user's staking period and the amount of tokens staking,
 * and when staking compensation (claim) adds MP to pay compensation.
 */
abstract contract SPMultiPoint is ISPMultiPoint, SPBase {
    //===== VARIABLES =====//
    struct MP {
        uint totalMP; // total MP
        uint criteria; // increasing MP per block
        uint lastBlock; // block where MP was last updated
    }

    bool public override useMP; // switch to use MP
    uint public constant year = 365 days; // 31536000

    MP private _allMPInfo; // MP information of all
    mapping(address => MP) private _userMPInfo; // MP information of the user

    //===== EXTERNAL FUNCTIONS =====//
    /**
     * @dev Change useMP
     */
    function changeUseMP() external onlyOwner {
        useMP = useMP ? false : true;
    }

    /**
     * @dev Update MP
     */
    function updateMP() external {
        if (stakedAmount(msg.sender) == 0)
            revert StakedAmountIsZero(msg.sender);
        _updateMP(msg.sender);
    }

    //===== PUBLIC FUNCTIONS =====//
    /**
     * @dev To get MP information of all
     */
    function getAllMPInfo()
        public
        view
        override
        returns (uint totalMP, uint criteria, uint lastBlock)
    {
        totalMP = _allMPInfo.totalMP;
        criteria = _allMPInfo.criteria;
        lastBlock = _allMPInfo.lastBlock;
    }

    /**
     * @dev To get MP information of the user
     * @param user user's address
     */
    function getUserMPInfo(
        address user
    )
        public
        view
        override
        returns (uint totalMP, uint criteria, uint lastBlock)
    {
        totalMP = _userMPInfo[user].totalMP;
        criteria = _userMPInfo[user].criteria;
        lastBlock = _userMPInfo[user].lastBlock;
    }

    /**
     * @dev To get total all MP
     */
    function totalAllMP() public view override returns (uint) {
        return calcAllMP(block.number) / year;
    }

    /**
     * @dev To get total user MP
     * @param user user's address
     */
    function totalUserMP(address user) public view override returns (uint) {
        return calcUserMP(user, block.number) / year;
    }

    /**
     * @dev To get last updated all MP
     */
    function lastAllMP() public view override returns (uint) {
        return _allMPInfo.totalMP / year;
    }

    /**
     * @dev To get last updated user MP
     * @param user user's address
     */
    function lastUserMP(address user) public view override returns (uint) {
        return _userMPInfo[user].totalMP / year;
    }

    /**
     * @dev To get current all MP
     */
    function currentAllMP() public view override returns (uint) {
        return totalAllMP() - lastAllMP();
    }

    /**
     * @dev To get current user MP
     * @param user user's address
     */
    function currentUserMP(address user) public view override returns (uint) {
        return totalUserMP(user) - lastUserMP(user);
    }

    /**
     * @dev To get total stake point
     */
    function totalSP() public view virtual override returns (uint) {
        return totalStakedAmount() + lastAllMP();
    }

    /**
     * @dev To stake point of the user
     * @param user user's address
     */
    function userSP(address user) public view virtual override returns (uint) {
        return stakedAmount(user) + lastUserMP(user);
    }

    /**
     * @dev Calculate all MP by block number
     * @param bn block number
     */
    function calcAllMP(uint bn) public view returns (uint totalMP) {
        totalMP =
            _allMPInfo.totalMP +
            ((bn - _allMPInfo.lastBlock) * _allMPInfo.criteria);
    }

    /**
     * @dev Calculate user MP by bn block number
     * @param user user's address
     * @param bn block number
     */
    function calcUserMP(
        address user,
        uint bn
    ) public view returns (uint totalMP) {
        totalMP =
            _userMPInfo[user].totalMP +
            ((bn - _userMPInfo[user].lastBlock) * _userMPInfo[user].criteria);
    }

    /**
     * @dev Update MP
     */
    function _updateMP(address user) internal {
        if (useMP) {
            _allMPInfo.totalMP = calcAllMP(block.number);
            _allMPInfo.criteria = totalStakedAmount();
            _allMPInfo.lastBlock = block.number;

            _userMPInfo[user].totalMP = calcUserMP(user, block.number);
            _userMPInfo[user].criteria = stakedAmount(user);
            _userMPInfo[user].lastBlock = block.number;
        }
    }

    function _afterStake(
        address user,
        uint amount,
        uint totalFee
    ) internal virtual override {
        super._afterStake(user, amount, totalFee);
        _updateMP(user);
    }

    function _afterUnstake(
        address user,
        uint amount,
        uint totalFee
    ) internal virtual override {
        super._afterUnstake(user, amount, totalFee);
        _updateMP(user);
    }
}
