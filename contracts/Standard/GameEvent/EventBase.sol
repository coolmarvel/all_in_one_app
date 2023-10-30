//  SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./EventFeePolicy.sol";
import "../../Common/WemixFeeVault.sol";
import "../../Role/IRecipientRoleV2.sol";
import "../../openzeppelin-contracts/utils/Address.sol";

contract EventBase is EventFeePolicy, WemixFeeVault {
    using RecipientLib for RecipientLib.Recipient;
    using Address for address;

    bytes32 public constant UNPAID_COLUMN = "unpaid";

    enum Status {
        NONE,
        ENTERED,
        REWARDED,
        REFUNDED
    }
    enum PaymentType {
        WATING,
        REWARDING,
        REFUNDING
    }

    struct GameEvent {
        bool isAllowedCancel; // is event allowed user can cancel
        uint totalAmount; // total stored amount
        uint remainAmount; // reward remain amount
        uint enterAmount; // total enter amount
        uint start; // start time
        uint end; // end time
        uint enterAllowed; // enter limit time
        uint cancelAllowed; // cancel limit time
        uint enteredUser; // number of users who enter the event
        PaymentType paymentType; // state of event payment type
    }

    IERC20 internal _token;

    mapping(uint => GameEvent) internal _eventInfos; // events

    uint public totalPendingAmount; // pending amount
    uint internal aliveTime = 4 weeks; // event alive time
    uint[] internal _toBeDelete; // event list that reward finished

    event Created(
        uint indexed eventId,
        uint start,
        uint end,
        uint enterAllowed,
        uint cancelAllowed
    );
    event Deleted(uint indexed eventId, bytes32 indexed column);
    event Entered(
        uint indexed eventId,
        address indexed user,
        bytes32 indexed column,
        uint amount
    );
    event Added(uint indexed eventId, address indexed user, uint amount);
    event Canceled(uint indexed eventId, address indexed user, uint amount);
    event Rewarded(
        uint indexed eventId,
        address indexed user,
        bytes32 indexed column,
        uint amount
    );
    event Refunded(uint indexed eventId, address indexed user, uint amount);
    event TokenChanged(address newToken);
    event ShutDown(address indexed recipient, uint balance);
    event AliveTimeChanged(uint newTime);

    constructor(address token, address recipientRoleV2, bytes32 service) {
        require(
            recipientRoleV2 != address(0) && recipientRoleV2.isContract(),
            "EventBase: invalid recipient address"
        );
        require(
            token != address(0) && token.isContract(),
            "EventBase: invalid token address"
        );

        _token = IERC20(token);
        _setRecipientRole(service, recipientRoleV2);
    }

    function _create(
        uint eventId,
        uint start,
        uint eventTime,
        bool isAllowedCancel,
        uint enterAllowed,
        uint cancelAllowed
    ) internal {
        GameEvent storage newEvent = _eventInfos[eventId];

        newEvent.start = start;
        newEvent.end = start + eventTime;
        // newEvent.end = start.add(eventTime);

        newEvent.isAllowedCancel = isAllowedCancel;

        newEvent.enterAllowed = enterAllowed == 0
            ? newEvent.end
            : start + enterAllowed;
        newEvent.cancelAllowed = cancelAllowed == 0
            ? newEvent.end
            : start + cancelAllowed;

        // newEvent.enterAllowed = enterAllowed == 0 ? newEvent.end : start.add(enterAllowed);
        // newEvent.cancelAllowed = cancelAllowed == 0 ? newEvent.end : start.add(cancelAllowed);

        emit Created(
            eventId,
            start,
            newEvent.end,
            newEvent.enterAllowed,
            newEvent.cancelAllowed
        );
    }

    function _drop(uint eventId) internal {
        delete _eventInfos[eventId];

        emit Deleted(eventId, "Drop");
    }

    function _enter(
        address user,
        uint eventId,
        uint amount,
        bytes32 column
    ) internal virtual {
        if (amount > 0) {
            require(
                _token.transferFrom(user, address(this), amount),
                "EventBase: enter fail"
            );
        }
        GameEvent storage _event = _eventInfos[eventId];

        _event.enteredUser += 1;
        _event.totalAmount += amount;
        _event.remainAmount += amount;
        _event.enterAmount += amount;

        totalPendingAmount += amount;

        emit Entered(eventId, user, column, amount);
    }

    function _addToken(
        address user,
        uint eventId,
        uint amount
    ) internal virtual {
        require(
            _token.transferFrom(user, address(this), amount),
            "EventBase: add fail"
        );

        GameEvent storage _event = _eventInfos[eventId];

        _event.totalAmount += amount;
        _event.remainAmount += amount;

        totalPendingAmount += amount;

        emit Added(eventId, user, amount);
    }

    function _cancel(
        address user,
        uint eventId,
        uint amount,
        uint enterAmount
    ) internal virtual {
        (uint userAmount, uint incomeAmount) = _distributeToken(
            CANCEL,
            eventId,
            amount
        );

        require(_token.transfer(user, userAmount), "EventBase: cancel fail");

        if (incomeAmount > 0) {
            _addIncome(
                address(_token),
                "CANCEL",
                incomeAmount,
                incomeToPlatformPercent()
            );
        }

        GameEvent storage _event = _eventInfos[eventId];

        unchecked {
            require(
                _event.totalAmount >= amount,
                "EventBase: amount can't over total amount"
            );
            _event.totalAmount -= amount;
            require(
                _event.remainAmount >= amount,
                "EventBase: amount can't over remain amount"
            );
            _event.remainAmount -= amount;
            require(
                _event.enterAmount >= enterAmount,
                "EventBase: amount can't over enter amount"
            );
            _event.enterAmount -= enterAmount;
            require(
                _event.enteredUser - 1 >= 0,
                "EventBase: number of user can't be negative"
            );
            _event.enteredUser -= 1;

            require(
                totalPendingAmount >= amount,
                "EventBase: amount can't over remain amount"
            );
            totalPendingAmount -= amount;
        }

        emit Canceled(eventId, user, amount);
    }

    function _beforeReward(uint eventId) internal virtual {
        GameEvent storage _event = _eventInfos[eventId];
        if (_event.remainAmount == _event.totalAmount) {
            uint incomeAmount;
            // add fee
            unchecked {
                if (_event.enterAmount != _event.remainAmount) {
                    require(
                        _event.remainAmount >= _event.enterAmount,
                        "EventBase: calculate add fee fail"
                    );
                    uint addAmount = _event.remainAmount - _event.enterAmount;
                    (, incomeAmount) = _distributeToken(
                        ADD,
                        eventId,
                        addAmount
                    );
                    if (incomeAmount > 0) {
                        _addIncome(
                            address(_token),
                            "ADD",
                            incomeAmount,
                            incomeToPlatformPercent()
                        );

                        //renew remain amount
                        require(
                            _event.remainAmount >= incomeAmount,
                            "EventBase: calculate enter fee fail"
                        );
                        _event.remainAmount -= incomeAmount;
                    }
                }
                // enter fee
                (, incomeAmount) = _distributeToken(
                    ENTER,
                    eventId,
                    _event.enterAmount
                );

                if (incomeAmount > 0) {
                    _addIncome(
                        address(_token),
                        "ENTER",
                        incomeAmount,
                        incomeToPlatformPercent()
                    );

                    //renew remain amount
                    require(
                        _event.remainAmount >= incomeAmount,
                        "EventBase: calculate enter fee fail"
                    );
                    _event.remainAmount -= incomeAmount;
                }
            }
        }
    }

    function _reward(
        address user,
        uint eventId,
        uint amount,
        bytes32 column
    ) internal virtual {
        GameEvent storage _event = _eventInfos[eventId];

        //reward fee
        (uint userAmount, uint incomeAmount) = _distributeToken(
            REWARD,
            eventId,
            amount
        );

        require(_token.transfer(user, userAmount), "EventBase: reward fail");

        if (incomeAmount > 0) {
            _addIncome(
                address(_token),
                "REWARD",
                incomeAmount,
                incomeToPlatformPercent()
            );
        }

        require(
            _event.remainAmount >= amount,
            "EventBase: amount can't over remain amount"
        );
        require(
            totalPendingAmount >= amount,
            "EventBase: amount can't over total pending amount"
        );
        unchecked {
            _event.remainAmount -= amount;
            totalPendingAmount -= amount;
        }

        _eventInfos[eventId].paymentType = PaymentType.REWARDING;

        if (_event.remainAmount == 0) {
            delete _eventInfos[eventId];
            _afterEventDeleted(eventId);
        }
        emit Rewarded(eventId, user, column, amount);
    }

    function _refund(address user, uint eventId, uint amount) internal virtual {
        GameEvent storage _event = _eventInfos[eventId];

        require(_token.transfer(user, amount), "EventBase: reward fail");

        require(
            _event.remainAmount >= amount,
            "EventBase: amount can't over remain amount"
        );
        require(
            totalPendingAmount >= amount,
            "EventBase: amount can't over total pending amount"
        );
        unchecked {
            _event.remainAmount -= amount;
            totalPendingAmount -= amount;
        }

        _eventInfos[eventId].paymentType = PaymentType.REFUNDING;

        if (_event.remainAmount == 0) {
            delete _eventInfos[eventId];
            _afterEventDeleted(eventId);
        }

        emit Refunded(eventId, user, amount);
    }

    function _deleteEvent() internal {
        // delete finished event
        uint size = _toBeDelete.length;
        if (size > 0) {
            for (uint i = 0; i < size; ) {
                uint targetId = _toBeDelete[i];
                GameEvent memory _event = _eventInfos[targetId];

                unchecked {
                    if (_event.end + aliveTime < block.timestamp) {
                        if (_eventInfos[targetId].remainAmount > 0) {
                            _addIncome(
                                address(_token),
                                UNPAID_COLUMN,
                                _eventInfos[targetId].remainAmount,
                                incomeToPlatformPercent()
                            );
                            require(
                                totalPendingAmount >=
                                    _eventInfos[targetId].remainAmount,
                                "EventBase: calculate pending amount error"
                            );
                            totalPendingAmount -
                                _eventInfos[targetId].remainAmount;
                        }

                        delete _eventInfos[targetId];

                        _afterEventDeleted(targetId);

                        // delete element
                        uint temp = _toBeDelete[size - 1];
                        _toBeDelete[size - 1] = targetId;
                        _toBeDelete[i] = temp;

                        _toBeDelete.pop();

                        size = size - 1;

                        emit Deleted(targetId, "AliveTime");
                    } else {
                        i = i + 1;
                    }
                }
            }
        }
    }

    function changeAliveTime(uint time) external onlyOwner {
        require(time > 0, "EventBase: invalid alive time");

        aliveTime = time;

        emit AliveTimeChanged(time);
    }

    function _afterEventDeleted(uint eventId) internal virtual {}
}
