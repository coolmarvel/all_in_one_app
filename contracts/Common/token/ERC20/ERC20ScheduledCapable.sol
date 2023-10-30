// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../../../openzeppelin-contracts/token/ERC20/ERC20.sol";
import "../../../openzeppelin-contracts/utils/Address.sol";
import "../../Periodic.sol";
import "./IERC20ScheduledCapable.sol";

/**
 * @title ERC20ScheduledCapable
 * @author Wemade Pte, Ltd
 * @dev ERC20ScheduledCapable contract to be deployed in wemix.
 * Limit the period transfer amount of tokens.
 * - Limit the total amount transfered per period.
 * - Limit the total amount that one user can receive per period.
 *
 * Can schedule the periodCap and userCap differently depending on the period
 */
abstract contract ERC20ScheduledCapable is
    IERC20ScheduledCapable,
    ERC20,
    Periodic
{
    using Address for address;

    uint private _startTime; // The timestamp when this contract started.
    uint private _remainAmount; // This value is initialized to the same value as the value of the periodCap, and is the amount of token exchange remaining in the period.
    uint private _periodcap; // Total exchange limit in the period
    uint private _periodUserCap; // Exchange limits per user within a period
    uint private _totalStage; // Total number of schedules
    uint private _position; // The index of the schedule to which the current timestamp belongs

    // This structure manages the state of the user
    struct Status {
        uint endTime; // The time at which the last token exchange time base period ends
        uint amount; // Token exchange volume based on last token exchange time
    }

    // This structure manages the state of the schedule
    struct Schedule {
        uint stage; // The timestamp of the period you want to schedule
        uint cap; // The periodCap applied to the stage period
        uint userCap; // The userCap applied to the stage period
    }

    Schedule[] private _schedules; // Schedule table
    mapping(address => Status) private _userStatus; // It maps the address to the Status structure

    event OptionChanged(bytes32 indexed option, uint value);
    event ScheduleChanged(
        uint time,
        uint[] stageTable,
        uint[] capTable,
        uint[] userCapTable
    );

    constructor(uint start, uint period) {
        _startTime = start;
        initPeriodic(start, period);
    }

    // function totalStage() external override view returns (uint) {
    //     return _totalStage;
    // }

    function getSchedule(
        uint index
    ) external view override returns (uint stage, uint cap, uint userCap) {
        require(index < _totalStage, "ERC20ScheduledCapable: invalid index");

        Schedule memory schedule = _schedules[index];
        stage = schedule.stage;
        cap = schedule.cap;
        userCap = schedule.userCap;
    }

    function getUserStatus(
        address user
    ) external view override returns (uint endTime, uint amount) {
        if (_periodUserCap > 0) {
            Status memory _elem = _userStatus[user];
            if (_elem.endTime < block.timestamp) {
                endTime = super.endTime();
                uint round = round();
                require(
                    block.timestamp >= endTime,
                    "ERC20ScheduledCapable: endTime exceeds timestamp"
                );
                unchecked {
                    endTime += (((block.timestamp - endTime) / round + 1) *
                        round);
                }
                amount = 0;
            } else {
                endTime = _elem.endTime;
                amount = _elem.amount;
            }
        }
    }

    function initSchedule(
        uint total,
        uint[] memory stage,
        uint[] memory cap,
        uint[] memory userCap
    ) public onlyOwner {
        require(
            total > 0,
            "ScheduledCap: failed initSchedule, totalStage is 0"
        );
        require(
            stage.length == total &&
                cap.length == total &&
                userCap.length == total,
            "ScheduledCap: failed initSchedule, differ in length between stageTable and capTable and userCapTable"
        );

        _totalStage = total;
        _position = 0;
        if (_schedules.length > 0) delete (_schedules);

        uint beforeStage;
        for (uint i = 0; i < _totalStage; i++) {
            require(
                stage[i] > beforeStage,
                "ScheduledCap: stage should be an increasing value"
            );
            beforeStage = stage[i];

            _schedules.push(
                Schedule({stage: stage[i], cap: cap[i], userCap: userCap[i]})
            );
        }
        emit ScheduleChanged(block.timestamp, stage, cap, userCap);
    }

    function remainAmount() public view override returns (uint cap) {
        if (_isRenewable()) {
            (cap, , ) = _scheduledCap();
        } else {
            cap = _remainAmount;
        }
    }

    function periodCap() public view override returns (uint cap) {
        if (_isRenewable()) {
            (cap, , ) = _scheduledCap();
        } else {
            cap = _periodcap;
        }
    }

    function periodUserCap() public view override returns (uint userCap) {
        if (_isRenewable()) {
            (, userCap, ) = _scheduledCap();
        } else {
            userCap = _periodUserCap;
        }
    }

    // Verify that the quantity to be transmitted exceeds the set cap.
    function _checkCap(address from, address to, uint256 amount) internal {
        if (
            from == _treasury() &&
            _isCapAccount(to) &&
            from != address(0) &&
            to != address(0)
        ) {
            _renew();

            if (_periodcap > 0) {
                require(
                    _remainAmount >= amount,
                    "ScheduledCap: period cap exceeds"
                );
                unchecked {
                    _remainAmount -= amount;
                }
            }
            if (_periodUserCap > 0) {
                if (_userStatus[to].endTime != endTime()) {
                    _userStatus[to] = Status({endTime: endTime(), amount: 0});
                }
                Status storage _elem = _userStatus[to];
                _elem.amount += amount;
                require(
                    _elem.amount <= _periodUserCap,
                    "ScheduledCap: period user cap exceeds"
                );
            }
        }
    }

    function _renew() internal virtual override returns (bool pass) {
        pass = super._renew();
        if (pass) {
            uint balance = balanceOf(_treasury());
            (uint cap, uint userCap, uint position) = _scheduledCap();
            if (_position < position) {
                _position = position;
            }

            if (_periodcap != cap) {
                _periodcap = cap;
                emit CapChanged("cap", _periodcap);
            }

            if (_periodUserCap != userCap) {
                _periodUserCap = userCap;
                emit CapChanged("userCap", _periodUserCap);
            }

            _remainAmount = _periodcap > balance ? balance : _periodcap;
        }
    }

    function _treasury() internal view virtual returns (address);

    function _isCapAccount(
        address account
    ) internal view virtual returns (bool);

    function _scheduledCap() private view returns (uint, uint, uint) {
        require(
            block.timestamp >= _startTime,
            "ScheduledCap: startTime exceeds timestamp"
        );
        unchecked {
            uint since = block.timestamp - _startTime;
            uint lastStage = _totalStage - 1;
            for (uint i = _position; i < lastStage; i++) {
                if (since < _schedules[i].stage)
                    return (_schedules[i].cap, _schedules[i].userCap, i);
            }
            return (
                _schedules[lastStage].cap,
                _schedules[lastStage].userCap,
                lastStage
            );
        }
    }
}
