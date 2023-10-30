// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../base/SPBase.sol";
import "../interface/ISPCore.sol";
import "../interface/ISPMineSchedule.sol";

/**
 * @title SPMineSchedule
 * @author Wemade Pte, Ltd
 * @dev This contract schedules the amount of tokens minted per block.
 */
abstract contract SPMineSchedule is ISPCore, ISPMineSchedule, SPBase {
    //===== VARIABLES =====//
    struct Schedule {
        uint stage; // period of schedule
        uint reward; // amount of reward per stage
    }

    struct Pre {
        uint startBlock; // block number pre-staking start
        uint endBlock; // block number pre-staking end
    }

    uint public override startBlock; // block number mining start
    bool public override allowPreStake; // can user stake only after mining has started

    Schedule[] private _schedules; // array of schedule
    Pre private _pre; // information of pre-staking period

    event SetSchedule(uint startBlock, uint[] stage, uint[] reward);

    constructor(
        bytes32 game,
        address rt,
        address st,
        uint amount,
        bytes32 service,
        address recipientRole
    ) SPBase(game, rt, st, amount, service, recipientRole) {}

    //===== EXTERNAL FUNCTIONS =====//
    function mineType() external pure override returns (Core.MineType) {
        return Core.MineType.Schedule;
    }

    /**
     * @dev Set the schedule of mining
     * @param start block number mining start
     * @param stage array of stage
     * @param reward array of reward
     */
    function setSchedule(
        uint start,
        uint[] memory stage,
        uint[] memory reward
    ) external onlyOwner {
        if (start < block.number) revert UnderValue(start, block.number);
        if (!(stage.length > 0 && stage.length == reward.length))
            revert InvalidStage(stage.length, reward.length);

        startBlock = start;

        if (_schedules.length > 0) delete (_schedules);

        uint size = stage.length;
        uint beforeStage;

        for (uint i = 0; i < size; i++) {
            if (stage[i] <= beforeStage)
                revert UnderValue(stage[i], beforeStage);
            beforeStage = stage[i];

            _schedules.push(Schedule({stage: stage[i], reward: reward[i]}));
        }

        emit SetSchedule(startBlock, stage, reward);
    }

    /**
     * @dev Set the information of pre-staking
     * @param start block number pre-staking start
     * @param end block number pre-staking end
     */
    function setPreStakeInfo(uint start, uint end) external onlyOwner {
        if (!allowPreStake) revert NotAllowPreStake(allowPreStake);
        if (!(start < end && end < startBlock))
            revert InvalidPreStakeSet(start, end);

        _pre.startBlock = start;
        _pre.endBlock = end;
    }

    /**
     * @dev Change allowPreStake
     */
    function changeAllowPreStake() external onlyOwner {
        allowPreStake = allowPreStake ? false : true;
    }

    //===== PUBLIC FUNCTIONS =====//
    /**
     * @dev To get current position of the scheduled stage
     */
    function currentPosition() public view override returns (uint pos) {
        pos = calcPosition(block.number);
    }

    /**
     * @dev To get length of the schedule array
     */
    function scheduleSize() public view override returns (uint) {
        return _schedules.length;
    }

    /**
     * @dev To get information of the schedule by index
     * @param index the index of the schedule
     */
    function getSchedule(
        uint index
    ) public view override returns (uint stage, uint reward) {
        if (index >= scheduleSize()) revert OverValue(index, scheduleSize());
        Schedule memory schedule = _schedules[index];
        stage = schedule.stage;
        reward = schedule.reward;
    }

    /**
     * @dev To get the information of pre-staking
     */
    function getPreStakeInfo()
        public
        view
        override
        returns (uint start, uint end)
    {
        start = _pre.startBlock;
        end = _pre.endBlock;
    }

    function totalMinedRT() public view virtual override returns (uint amount) {
        amount = calcMinedRT(startBlock, block.number);
    }

    /**
     * @dev Calculate the amount of rt mined during the period
     * @param start start block number of the period
     * @param end end block number of the period
     */
    function calcMinedRT(
        uint start,
        uint end
    ) public view override returns (uint amount) {
        if (start < startBlock) revert UnderValue(start, startBlock);
        uint criteria = start;

        uint point;
        uint period;

        amount = 0;

        if (end > criteria) {
            for (uint i = calcPosition(start); i <= calcPosition(end); i++) {
                (uint stage, uint reward) = getSchedule(i);

                point = i == calcPosition(end) ? end : startBlock + stage;

                period = point - criteria;
                amount += period * reward;

                criteria = point;
            }
        }

        if (amountMax > 0 && amount > amountMax) amount = amountMax;
    }

    /**
     * @dev Calculate the position(index of schedule array) of the bn(block number)
     * @param bn standard block number
     */
    function calcPosition(uint bn) public view override returns (uint pos) {
        uint size = scheduleSize();
        uint start = startBlock;
        uint lastIndex = size - 1;
        uint end = startBlock + _schedules[lastIndex].stage;

        if (bn >= end) {
            pos = lastIndex;
        } else {
            for (uint i = 0; i < size; i++) {
                if (bn >= start) {
                    pos = i;
                    start = startBlock + _schedules[i].stage;
                } else {
                    break;
                }
            }
        }
    }

    function _beforeStake(
        address user,
        uint amount
    ) internal view virtual override {
        if (!allowPreStake) {
            if (block.number < startBlock)
                revert UnderValue(block.number, startBlock);
        } else {
            if (
                !((_pre.startBlock == 0 && _pre.endBlock == 0) ||
                    (block.number >= _pre.startBlock &&
                        block.number <= _pre.endBlock) ||
                    (block.number >= startBlock))
            )
                revert NotStakePeriod(
                    block.number,
                    _pre.startBlock,
                    _pre.endBlock,
                    startBlock
                );
        }

        super._beforeStake(user, amount);
    }
}
