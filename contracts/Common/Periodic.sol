// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../openzeppelin-contracts/access/Ownable.sol";

/**
 * @title Periodic
 * @author Wemade Pte, Ltd
 * @dev Optional function according to the renewal of the period.
 *
 * Use when there is a function that needs to be called every specific period.
 * Set the start time and cycle.
 * Override the _renew()
 */
abstract contract Periodic is Ownable {
    uint256 public immutable startTime;
    uint256 private _endTime;
    uint256 private _round;

    event RoundChanged(uint256 indexed round);

    constructor(uint256 start) {
        startTime = start;
    }

    function changeRound(uint256 r) external onlyOwner {
        _round = r;
        emit RoundChanged(_round);
    }

    function initPeriodic(uint256 round_) public onlyOwner {
        require(_endTime == 0, "periodic: already inited");
        _round = round_;
        unchecked {
            if (startTime == 0) {
                uint256 currentTime = block.timestamp;
                require(
                    _endTime >= currentTime - (currentTime % _round),
                    "Periodic: underflow err"
                );
                _endTime = currentTime - (currentTime % _round);
            } else {
                _endTime = startTime;
            }
        }
    }

    function endTime() public view returns (uint256) {
        return _endTime;
    }

    function round() public view returns (uint256) {
        return _round;
    }

    function _isRenewable() internal view returns (bool) {
        return block.timestamp > _endTime;
    }

    function _renew() internal virtual returns (bool pass) {
        pass = _isRenewable();
        if (pass) {
            _endTime += (((block.timestamp - _endTime) / _round + 1) * _round);
        }
    }
}
