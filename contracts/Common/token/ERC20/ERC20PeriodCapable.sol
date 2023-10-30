// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../../openzeppelin-contracts/token/ERC20/ERC20.sol";
import "../../../openzeppelin-contracts/utils/Address.sol";
import "../../Periodic.sol";
import "./IERC20PeriodCapable.sol";

/**
 * @title ERC20PeriodCapable
 * @author Wemade Pte, Ltd
 * @dev ERC20PeriodCapable contract to be deployed in wemix.
 * Limit the period transfer amount of tokens.
 * - Limit the total amount transfered per period.
 * - Limit the total amount that one user can receive per period.
 */
abstract contract ERC20PeriodCapable is IERC20PeriodCapable, ERC20, Periodic {
    using Address for address;

    uint256 public _periodCap;
    uint256 public _periodUserCap;

    // uint256 private _periodCap;
    // uint256 private _periodUserCap;

    struct Status {
        uint256 endTime;
        uint256 amount;
    }
    mapping(address => Status) private _userStatus;
    uint256 private _remainAmount;

    constructor(
        uint256 start,
        uint256 periodCap,
        uint256 periodUserCap,
        uint256 period
    ) {
        _periodCap = periodCap;
        _periodUserCap = periodUserCap;
        initPeriodic(start, period);
    }

    function changePeriodCap(uint256 amount) external onlyOwner {
        _periodCap = amount;
        emit CapChanged("periodCap", _periodCap);
    }

    function changePeriodUserCap(uint256 amount) external onlyOwner {
        _periodUserCap = amount;
        emit CapChanged("periodUserCap", _periodUserCap);
    }

    function getUserStatus(
        address user
    ) external view override returns (uint256 endTime, uint256 amount) {
        if (_periodUserCap > 0) {
            Status memory _elem = _userStatus[user];
            endTime = _elem.endTime;
            amount = _elem.amount;
            unchecked {
                if (endTime < block.timestamp) {
                    uint256 round = round();
                    require(
                        block.timestamp >= endTime,
                        "ERC20PeriodCapable: endTime exceeds timestamp"
                    );
                    endTime += (((block.timestamp - endTime) / round + 1) *
                        round);
                    amount = 0;
                }
            }
        }
    }

    // function periodCap() public view override returns (uint256) {
    //     return _periodCap;
    // }

    // function periodUserCap() public view override returns (uint256) {
    //     return _periodUserCap;
    // }

    function remainAmount() public view override returns (uint256) {
        if (_isRenewable()) {
            return _periodCap;
            // return periodCap();
        } else {
            return _remainAmount;
        }
    }

    // Verify that the quantity to be transmitted exceeds the set cap.
    function _checkCap(address from, address to, uint256 amount) internal {
        if (from == _treasury() && _isCapAccount(to)) {
            _renew();

            if (_periodCap > 0) {
                require(
                    _remainAmount >= amount,
                    "ERC20PeriodCapable: amount exceeds remainAmount"
                );
                _remainAmount -= amount;
            }
            if (_periodUserCap > 0) {
                if (_userStatus[to].endTime != endTime()) {
                    _userStatus[to] = Status({endTime: endTime(), amount: 0});
                }
                Status storage _elem = _userStatus[to];
                _elem.amount += amount;
                require(
                    _elem.amount <= _periodUserCap,
                    "ERC20PeriodCapable: amount exceeds periodUserCap"
                );
                // require(_elem.amount <= periodUserCap(), "ERC20PeriodCapable: amount exceeds periodUserCap");
            }
        }
    }

    function _renew() internal virtual override returns (bool pass) {
        pass = super._renew();
        if (pass && (_periodCap > 0)) {
            uint256 balance = balanceOf(_treasury());
            _remainAmount = _periodCap > balance ? balance : _periodCap;
        }
    }

    function _treasury() internal view virtual returns (address);

    function _isCapAccount(
        address account
    ) internal view virtual returns (bool);
}
