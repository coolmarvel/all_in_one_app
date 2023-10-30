// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./Rewarder.sol";
import "../../Common/Periodic.sol";

/**
 * @title EventRewarder
 * @author Wemade Pte, Ltd
 * @dev EventRewarder contract to be deployed in wemix(main net).
 *
 * It is a contract that rewards events occurring in the game.
 * This contract must have FT for compensation and limits the amount of compensation by cycle.
 *
 * Users must receive rewards within a certain period of time and cannot receive compensation after the set period.
 *
 * The amount of reward by cycle must be overridden by the contract that inherits this contract.
 * Of the allocated amounts, the handling of quantities that the user has not received must also be overridden by the contract that inherits this contract.
 */
abstract contract EventRewarder is Rewarder, Periodic {
    using Counters for Counters.Counter;

    //===== VARIABLES =====//
    uint public rewardCount; // The maximum number of rewards available per user per event
    uint public historySize; // The criteria for how long a user can receive rewards.
    uint public nextRemoveID; // The id that will be removed at the next round.
    uint public pendingAmount; // The total remaining prize amount for all events.
    uint public totalPrizeAmount; // The maximum amount of rewards available per event

    Counters.Counter private _idCounter;

    // this structure manages the amount of reward and the count of reward for the user
    struct UserInfo {
        uint rewardCount;
        uint rewardAmount;
    }

    // this structure manages the information of rewarding of event id.
    struct RewardInfo {
        uint totalAmount;
        uint remainAmount;
    }

    mapping(uint => RewardInfo) private _rewardInfo; // event id => RewardInfo
    mapping(uint => mapping(address => UserInfo)) private _userInfo; // event id => user address => UserInfo

    //===== EVENTS =====//
    event Rewarded(
        uint indexed eventId,
        bytes32 indexed column,
        address indexed user,
        uint amount
    );
    event Removed(uint indexed eventId, uint pendingAmount);
    event Created(uint indexed eventId, uint prizeAmount);
    event SetOption(bytes32 indexed option, uint value);

    constructor(
        address token,
        address manager,
        address validator,
        bytes32 role,
        uint start,
        uint period,
        uint amount,
        uint count,
        uint size
    ) Periodic(start) Rewarder(token, manager, validator, role) {
        require(amount > 0, "EventRewarder: invalid amount");

        setRewardCount(count);
        setHistorySize(size);
        setTotalPrizeAmount(amount);

        initPeriodic(period);
    }

    modifier onlyValidID(uint id) {
        require(id > 0, "EventRewarder: invalid id");

        if (currentEventID() > 0)
            require(
                _rewardInfo[id].totalAmount > 0,
                "EventRewarder: deleted id"
            );
        _;
    }

    //===== EXTERNAL FUNCTIONS =====//
    /**
     * @dev External function of paying reward to users.
     * @param id           eventId
     * @param user         wemix wallet address of the user who will be rewarded.
     * @param nonce        user nonce
     * @param amount       reward amount
     * @param column       event informaiton
     */
    function reward(
        uint id,
        address user,
        uint nonce,
        uint amount,
        bytes32 column
    ) external whenNotPaused onlyValidID(id) onlyValidator {
        require(
            rewardCount == 0 || _userInfo[id][user].rewardCount < rewardCount,
            "EventRewarder: already received reward"
        );

        checkUserNonce(user, nonce);

        _renew();
        _transfer(user, amount);

        _rewardInfo[id].remainAmount = _rewardInfo[id].remainAmount - amount;
        pendingAmount = pendingAmount - amount;

        _userInfo[id][user].rewardCount++;
        _userInfo[id][user].rewardAmount += amount;

        emit Rewarded(id, column, user, amount);
    }

    /**
     * @dev If it's time to renew, create new Reward data.
     */
    function renew() external {
        _renew();
    }

    /**
     * @param id  event id
     * @param user user address
     */
    function getUserInfo(
        uint id,
        address user
    ) external view onlyValidID(id) returns (UserInfo memory) {
        require(user != address(0), "EventRewarder: invalid address");

        return _userInfo[id][user];
    }

    /**
     * @param id  event id
     */
    function getRewardInfo(
        uint id
    ) external view onlyValidID(id) returns (RewardInfo memory) {
        return _rewardInfo[id];
    }

    /**
     * @return _isRenewable
     * Whether it's time for a new reward to be created or not.
     */
    function isRenewable() external view returns (bool) {
        return _isRenewable();
    }

    //===== PUBLIC FUNCTIONS =====//
    function setRewardCount(uint count) public onlyOwner {
        rewardCount = count;
        emit SetOption("rewardCount", rewardCount);
    }

    function setHistorySize(uint size) public onlyOwner {
        historySize = size;

        emit SetOption("historySize", historySize);
    }

    function setTotalPrizeAmount(uint amount) public onlyOwner {
        require(amount > 0, "EventRewarder: invalid amount");

        totalPrizeAmount = amount;

        uint id = currentEventID();

        if (id > 0) {
            uint totalAmount = _rewardInfo[id].totalAmount;
            uint remainAmount = _rewardInfo[id].remainAmount;
            uint rewardedAmount = totalAmount - remainAmount;

            pendingAmount = pendingAmount - remainAmount;
            remainAmount = amount < rewardedAmount
                ? 0
                : amount - rewardedAmount;
            pendingAmount = pendingAmount + remainAmount;

            _rewardInfo[id].totalAmount = totalPrizeAmount;
            _rewardInfo[id].remainAmount = remainAmount;
        }

        emit SetOption("totalPrizeAmount", totalPrizeAmount);
    }

    /**
     * @return _
     * The ID of the most recently created reward record.
     */
    function currentEventID() public view returns (uint) {
        return _idCounter.current();
    }

    /**
     * @return amount
     * Of the amounts held in the treasury, the amount that can be used as rewards
     */
    function remainBalance()
        public
        view
        virtual
        override
        returns (uint amount)
    {
        uint balance = IERC20(rt).balanceOf(treasury);
        amount = balance >= pendingAmount ? balance - pendingAmount : 0;
    }

    //===== INTERNAL FUNCTIONS =====//
    /**
     * @dev If it's time, create new Reward data.
     * After increasing the _idCounter, it generates new Reward data.
     * If there is Reward data that has passed a certain cycle, remove that data.
     * @return pass is whether a new Reward has been created.
     */
    function _renew() internal virtual override returns (bool pass) {
        pass = super._renew();

        if (pass && remainBalance() > 0) {
            _idCounter.increment();
            uint currentID = currentEventID();
            uint prizeAmount;
            if (!paused()) {
                prizeAmount = remainBalance() < totalPrizeAmount
                    ? remainBalance()
                    : totalPrizeAmount;
            }

            // remove before Reward data
            pendingAmount = pendingAmount + prizeAmount;
            _removeReward(currentID);

            // update new Reward data
            _rewardInfo[currentID] = RewardInfo({
                totalAmount: prizeAmount,
                remainAmount: prizeAmount
            });

            emit Created(currentID, totalPrizeAmount);
        }
    }

    /**
     * @dev If there is Reward data that has passed a certain cycle, remove that data.
     * If there is any remaining reward amount among the removed data, the reward amount must be processed by the inherited contract.
     */
    function _removeReward(uint id) private {
        if (id >= historySize + nextRemoveID) {
            uint removeRemainAmount;
            uint len = id - (historySize + nextRemoveID) + 1;
            uint[] memory removedIds = new uint[](len);

            for (uint i = 0; i < len; i++) {
                uint removeID = nextRemoveID + i;
                uint remainAmount = _rewardInfo[removeID].remainAmount;
                if (remainAmount > 0) {
                    removeRemainAmount = removeRemainAmount + remainAmount;
                }
                delete _rewardInfo[removeID];
                removedIds[i] = removeID;
            }
            nextRemoveID = nextRemoveID + len;
            pendingAmount = pendingAmount - removeRemainAmount;

            emit Removed(id, removeRemainAmount);
        }
    }
}
