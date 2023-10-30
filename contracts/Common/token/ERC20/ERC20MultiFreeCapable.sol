// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../../../openzeppelin-contracts/token/ERC20/ERC20.sol";
import "../../../openzeppelin-contracts/utils/Address.sol";
import "../../../openzeppelin-contracts/utils/Counters.sol";
import "../../../Common/WemixFeeVaultV4.sol";
import "../../../Role/IRecipientRoleV4.sol";
import "../../../Role/ValidatorRole.sol";
import "./IERC20MultiFreeCapable.sol";

/**
 * @title ERC20MultiFreeCapable
 * @author Wemade Pte, Ltd
 * @dev ERC20FreeCapable contract to be deployed in wemix.
 * Limit the period transfer amount of tokens.
 * - Limit the total amount transfered per game with not period.
 * - Limit the total amount that one user can receive per game with not period.
 */
abstract contract ERC20MultiFreeCapable is
    IERC20MultiFreeCapable,
    WemixFeeVaultV4,
    ERC20,
    ValidatorRole
{
    using Address for address;
    using Counters for Counters.Counter;

    struct GameInfo {
        bool isRegistered; // whether the game is registered or not
        uint periodCap; // total exchange limit for this token of the game
        uint periodUserCap; // exchange limit for this token per user of the game
        uint remainAmount; // amount of tokens remaining that the contract can pay to the user
        uint capAppliedTime; // Time when the latest exchange limit was applied (timestamp)
        Counters.Counter changedCount; // number of times the cap has changed
    }

    struct Status {
        uint capAppliedTime;
        uint amount; // Amount of tokens exchanged by the user
    }

    mapping(bytes32 => GameInfo) private _gameInfo;
    mapping(bytes32 => mapping(address => Status)) private _userStatus;

    modifier onlyRegisteredGame(bytes32 game) {
        require(
            _gameInfo[game].isRegistered,
            "MultiFreeCap: it's not registered game"
        );
        _;
    }

    /**
     * @dev External function to regist game
     * @param game name of the game that will be registered in this token
     * @param _periodCap total exchange limit for this token
     * @param _periodUserCap exchange limit for this token per user
     */
    function regist(
        bytes32 game,
        uint _periodCap,
        uint _periodUserCap
    ) external onlyOwner {
        require(
            IRecipientRoleV4(_recipientRole.recipientRoleV4).isWalletAdded(
                game
            ),
            "MultiFreeCap: wallets must be registered first"
        );
        require(
            !_gameInfo[game].isRegistered,
            "MultiFreeCap: already registered game"
        );

        _gameInfo[game].isRegistered = true;
        _gameInfo[game].periodCap = _periodCap;
        _gameInfo[game].periodUserCap = _periodUserCap;
        _gameInfo[game].remainAmount = _periodCap;
        _gameInfo[game].capAppliedTime = block.timestamp;
    }

    /**
     * @dev External function to change periodCap and periodUserCap of the game
     * @param game name of the game that will be registered in this token
     * @param _periodCap total exchange limit for this token
     * @param _periodUserCap exchange limit for this token per user
     * @param count number of times the cap has changed
     * @param validatorSig signature (address(this), game, periodCap, periodUserCap)
     */
    function changeAllCap(
        bytes32 game,
        uint _periodCap,
        uint _periodUserCap,
        uint count,
        bytes calldata validatorSig
    )
        external
        onlyRegisteredGame(game)
        onlyValidatorSig(
            abi.encodePacked(
                address(this),
                game,
                _periodCap,
                _periodUserCap,
                count
            ),
            validatorSig
        )
    {
        require(
            count == _gameInfo[game].changedCount.current(),
            "MultiFreeCap: invalid count"
        );

        _gameInfo[game].periodCap = _periodCap;
        _gameInfo[game].remainAmount = _periodCap;
        _gameInfo[game].periodUserCap = _periodUserCap;
        _gameInfo[game].capAppliedTime = block.timestamp;

        _gameInfo[game].changedCount.increment();

        emit CapChanged(game, "periodCap", _gameInfo[game].periodCap);
        emit CapChanged(game, "periodUserCap", _gameInfo[game].periodUserCap);
    }

    /**
     * @dev External function to change periodCap of the game
     * @param game name of the game that will be registered in this token
     * @param amount total exchange limit for this token
     * @param count number of times the cap has changed
     * @param validatorSig signature (address(this), game, amount, count)
     */
    function changePeriodCap(
        bytes32 game,
        uint amount,
        uint count,
        bytes calldata validatorSig
    )
        external
        onlyRegisteredGame(game)
        onlyValidatorSig(
            abi.encodePacked(address(this), game, amount, count),
            validatorSig
        )
    {
        require(
            count == _gameInfo[game].changedCount.current(),
            "MultiFreeCap: invalid count"
        );

        _gameInfo[game].periodCap = amount;
        _gameInfo[game].remainAmount = amount;
        _gameInfo[game].capAppliedTime = block.timestamp;

        _gameInfo[game].changedCount.increment();

        emit CapChanged(game, "periodCap", _gameInfo[game].periodCap);
    }

    /**
     * @dev External function to change periodUserCap of the game
     * @param game name of the game that will be registered in this token
     * @param amount exchange limit for this token per user
     * @param count number of times the cap has changed
     * @param validatorSig signature (address(this), game, amount, count)
     */
    function changePeriodUserCap(
        bytes32 game,
        uint amount,
        uint count,
        bytes calldata validatorSig
    )
        external
        onlyRegisteredGame(game)
        onlyValidatorSig(
            abi.encodePacked(address(this), game, amount, count),
            validatorSig
        )
    {
        require(
            count == _gameInfo[game].changedCount.current(),
            "MultiFreeCap: invalid count"
        );

        _gameInfo[game].periodUserCap = amount;
        _gameInfo[game].capAppliedTime = block.timestamp;

        _gameInfo[game].changedCount.increment();

        emit CapChanged(game, "periodUserCap", _gameInfo[game].periodUserCap);
    }

    /**
     *  @dev External function to get status of user
     *  @param game name of the game that will be registered in this token
     *  @param user wemix address of user
     */
    function getUserStatus(
        bytes32 game,
        address user
    ) external view override returns (uint _capAppliedTime, uint amount) {
        if (_gameInfo[game].periodUserCap > 0) {
            Status memory _elem = _userStatus[game][user];
            _capAppliedTime = _elem.capAppliedTime;
            amount = _elem.amount;

            if (_capAppliedTime < _gameInfo[game].capAppliedTime) {
                _capAppliedTime = _gameInfo[game].capAppliedTime;
                amount = 0;
            }
        }
    }

    /**
     *  @dev External function to get changedCount of the game
     *  @param game name of the game that will be registered in this token
     *  @return periodCap
     */
    function getChangedCount(bytes32 game) external view returns (uint) {
        return _gameInfo[game].changedCount.current();
    }

    /**
     *  @dev External function to get periodCap of the game
     *  @param game name of the game that will be registered in this token
     *  @return periodCap
     */
    function periodCap(bytes32 game) public view override returns (uint) {
        return _gameInfo[game].periodCap;
    }

    /**
     *  @dev External function to get periodUserCap of the game
     *  @param game name of the game that will be registered in this token
     *  @return periodUserCap
     */
    function periodUserCap(bytes32 game) public view override returns (uint) {
        return _gameInfo[game].periodUserCap;
    }

    /**
     * @dev External function to get remainAmount of the game
     * @param game name of the game that will be registered in this token
     * @return remainAmount
     */
    function remainAmount(bytes32 game) public view override returns (uint) {
        return _gameInfo[game].remainAmount;
    }

    /**
     * @dev External function to get capAppliedTime of the game
     * @param game name of the game that registered in this token
     * @return capAppliedTime
     */
    function capAppliedTime(bytes32 game) public view override returns (uint) {
        return _gameInfo[game].capAppliedTime;
    }

    // Verify that the quantity to be transmitted exceeds the set cap.
    function _checkCap(
        bytes32 game,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (from == _treasury() && _isCapAccount(to)) {
            require(
                _gameInfo[game].remainAmount >= amount,
                "MultiFreeCap: period cap exceeds"
            );
            unchecked {
                if (_gameInfo[game].periodCap > 0) {
                    _gameInfo[game].remainAmount -= amount;
                }
            }
            if (_gameInfo[game].periodUserCap > 0) {
                if (
                    _userStatus[game][to].capAppliedTime !=
                    _gameInfo[game].capAppliedTime
                ) {
                    _userStatus[game][to] = Status({
                        capAppliedTime: _gameInfo[game].capAppliedTime,
                        amount: 0
                    });
                }
                Status storage _elem = _userStatus[game][to];
                _elem.amount += amount;
                // _elem.amount = _elem.amount.add(amount);
                require(
                    _elem.amount <= _gameInfo[game].periodUserCap,
                    "MultiFreeCap: period user cap exceeds"
                );
            }
        }
    }

    function _treasury() internal view virtual returns (address);

    function _isCapAccount(
        address account
    ) internal view virtual returns (bool);
}
