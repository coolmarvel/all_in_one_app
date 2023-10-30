// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../../../openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../../../openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../../../openzeppelin-solidity/contracts/utils/Address.sol";
import "../../../Role/ValidatorRole.sol";
import "../../MultiPeriodic.sol";
import "./IERC20MultiPeriodCapable.sol";

/**
 * @title ERC20MultiPeriodCapable
 * @author Wemade Pte, Ltd
 * @dev ERC20MultiPeriodCapable contract to be deployed in wemix.
 * Limit the period transfer amount of tokens.
 * - Limit the total amount transfered per period per game.
 * - Limit the total amount that one user can receive per period per game.
 */
abstract contract ERC20MultiPeriodCapable is
    IERC20MultiPeriodCapable,
    ERC20,
    MultiPeriodic,
    ValidatorRole
{
    using SafeMath for uint;
    using Address for address;

    struct GameInfo {
        uint periodCap;
        uint periodUserCap;
        uint remainAmount;
    }

    struct Status {
        uint endTime;
        uint amount;
    }

    mapping(bytes32 => GameInfo) private _gameInfo;
    mapping(bytes32 => mapping(address => Status)) private _userStatus;

    constructor() internal {}

    function regist(
        bytes32 game,
        uint periodCap,
        uint periodUserCap,
        uint start,
        uint round
    ) external onlyOwner {
        require(
            _periodic[game].endTime == 0,
            "MultiCap: already registed game"
        );

        _gameInfo[game].periodCap = periodCap;
        _gameInfo[game].periodUserCap = periodUserCap;

        _setPeriodic(game, start, round);
    }

    function changePeriodCap(
        bytes32 game,
        uint amount,
        bytes calldata validatorSig
    )
        external
        onlyRegistedGame(game)
        onlyValidatorSig(
            abi.encodePacked(address(this), game, amount),
            validatorSig
        )
    {
        _gameInfo[game].periodCap = amount;
        emit CapChanged(game, "periodCap", _gameInfo[game].periodCap);
    }

    function changePeriodUserCap(
        bytes32 game,
        uint amount,
        bytes calldata validatorSig
    )
        external
        onlyRegistedGame(game)
        onlyValidatorSig(
            abi.encodePacked(address(this), game, amount),
            validatorSig
        )
    {
        _gameInfo[game].periodUserCap = amount;
        emit CapChanged(game, "periodUserCap", _gameInfo[game].periodUserCap);
    }

    function getUserStatus(
        bytes32 game,
        address user
    )
        external
        view
        override
        onlyRegistedGame(game)
        returns (uint endTime, uint amount)
    {
        if (_gameInfo[game].periodUserCap > 0) {
            Status memory _elem = _userStatus[game][user];
            endTime = _elem.endTime;
            amount = _elem.amount;

            if (endTime < block.timestamp) {
                uint round = super.round(game);
                endTime = endTime.add(
                    block.timestamp.sub(endTime).div(round).add(1).mul(round)
                );
                amount = 0;
            }
        }
    }

    function periodCap(
        bytes32 game
    ) public view override onlyRegistedGame(game) returns (uint) {
        return _gameInfo[game].periodCap;
    }

    function periodUserCap(
        bytes32 game
    ) public view override onlyRegistedGame(game) returns (uint) {
        return _gameInfo[game].periodUserCap;
    }

    function remainAmount(
        bytes32 game
    ) public view override onlyRegistedGame(game) returns (uint) {
        if (_isRenewable(game)) {
            return _gameInfo[game].periodCap;
        } else {
            return _gameInfo[game].remainAmount;
        }
    }

    // Verify that the quantity to be transmitted exceeds the set cap.
    function _checkCap(
        bytes32 game,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (from == _treasury() && _isCapAccount(to)) {
            _renew(game);

            if (_gameInfo[game].periodCap > 0) {
                _gameInfo[game].remainAmount = _gameInfo[game].remainAmount.sub(
                    amount,
                    "MultiCap: period cap exceeds"
                );
            }
            if (_gameInfo[game].periodUserCap > 0) {
                if (_userStatus[game][to].endTime != endTime(game)) {
                    _userStatus[game][to] = Status({
                        endTime: endTime(game),
                        amount: 0
                    });
                }
                Status storage _elem = _userStatus[game][to];
                _elem.amount = _elem.amount.add(amount);
                require(
                    _elem.amount <= _gameInfo[game].periodUserCap,
                    "MultiCap: period user cap exceeds"
                );
            }
        }
    }

    function _renew(
        bytes32 game
    ) internal virtual override returns (bool pass) {
        pass = super._renew(game);
        if (pass && (_gameInfo[game].periodCap > 0)) {
            uint balance = balanceOf(address(this));
            _gameInfo[game].remainAmount = _gameInfo[game].periodCap > balance
                ? balance
                : _gameInfo[game].periodCap;
        }
    }

    function _treasury() internal view virtual returns (address);

    function _isCapAccount(
        address account
    ) internal view virtual returns (bool);
}
