//  SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract EventOption {
    struct Option {
        bool isRenewable; // check renew end time when full user or full amount
        uint totalLimit; // user total amount limit per event. zero = no limit
        uint addAllowed; // add limit time
        uint addLimit; // limit the number of add token per user. zero = can't add
        uint maxUserNum; // max number of user per event. zero = no limit
        uint maxTotalAmount; // max total amount per event. zero = no limit
    }

    mapping(uint => Option) internal _options; // event id => Option

    function _changeOption(
        uint eventId,
        bool isRenewable,
        uint totalLimit,
        uint addAllowed,
        uint addLimit,
        uint maxUserNum,
        uint maxTotalAmount
    ) internal {
        Option storage _option = _options[eventId];

        _option.isRenewable = isRenewable;
        _option.totalLimit = totalLimit;
        _option.addAllowed = addAllowed;
        _option.addLimit = addLimit;
        _option.maxUserNum = maxUserNum;
        _option.maxTotalAmount = maxTotalAmount;
    }

    function _deleteOption(uint eventId) internal returns (bool) {
        delete _options[eventId];
        return true;
    }
}
