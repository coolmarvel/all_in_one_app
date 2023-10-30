// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../../../openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../../../openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../../Periodic.sol";
import "./IERC20DailyCapable.sol";

/**
 * @title ERC20DailyCapable
 * @author Wemade Tree Pte, Ltd
 * @dev ERC20DailyCapable contract to be deployed in wemix.
 * Limit the daily transfer amount of tokens.
 * - Limit the total amount transfered per day.
 * - Limit the total amount that one user can receive per day.
 */
abstract contract ERC20DailyCapable is IERC20DailyCapable, ERC20, Periodic {
    using SafeMath for uint256;

    uint private _dailyCap;
    uint private _dailyUserCap;

    struct Status {
        uint endTime;
        uint amount;
    }
    mapping(address => Status) private _userStatus;
    uint private _remainAmount;

    constructor(uint start, uint dailyCap, uint dailyUserCap) internal {
        _dailyCap = dailyCap;
        _dailyUserCap = dailyUserCap;
        initPeriodic(start, 1 days);
    }

    function changeDailyCap(uint amount) external onlyOwner {
        _dailyCap = amount;
        emit CapChanged("daily", _dailyCap);
    }

    function changeDailyUserCap(uint amount) external onlyOwner {
        _dailyUserCap = amount;
        emit CapChanged("user", _dailyUserCap);
    }

    function getUserStatus(
        address account
    ) external view override returns (uint endTime, uint amount) {
        Status memory _elem = _userStatus[account];
        endTime = _elem.endTime;
        amount = _elem.amount;
    }

    function dailyCap() public view override returns (uint) {
        return _dailyCap;
    }

    function dailyUserCap() public view override returns (uint) {
        return _dailyUserCap;
    }

    function remainAmount() public view override returns (uint) {
        require(_dailyCap > 0, "Cap: cap is 0");
        if (_isRenewable()) {
            return dailyCap();
        } else {
            return _remainAmount;
        }
    }

    // Verify that the quantity to be transmitted exceeds the set cap.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from == _treasury() && _isCapAccount(to)) {
            _renew();

            if (_dailyCap > 0) {
                _remainAmount = _remainAmount.sub(
                    amount,
                    "Cap: daily cap exceeds"
                );
            }
            if (_dailyUserCap > 0) {
                if (_userStatus[to].endTime != endTime()) {
                    _userStatus[to] = Status({endTime: endTime(), amount: 0});
                }
                Status storage _elem = _userStatus[to];
                _elem.amount = _elem.amount.add(amount);
                require(
                    _elem.amount <= dailyUserCap(),
                    "Cap: daily user cap exceeds"
                );
            }
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    function _renew() internal virtual override returns (bool pass) {
        pass = super._renew();
        if (pass && (_dailyCap > 0)) {
            uint balance = balanceOf(address(this));
            _remainAmount = _dailyCap > balance ? balance : _dailyCap;
        }
    }

    function _treasury() internal view virtual returns (address);

    function _isCapAccount(
        address account
    ) internal view virtual returns (bool);
}
