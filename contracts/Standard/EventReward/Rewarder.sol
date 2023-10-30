// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../../openzeppelin-contracts/security/Pausable.sol";
import "../../openzeppelin-contracts/utils/Counters.sol";
import "../../openzeppelin-contracts/interfaces/IERC20.sol";
import "../../openzeppelin-contracts/access/Ownable.sol";
import "../../openzeppelin-contracts/access/IAccessControl.sol";
import "../../openzeppelin-contracts/utils/Address.sol";

import "../../Common/UserNonce.sol";

/**
 * @title Rewarder
 * @author Wemade Pte, Ltd
 * @dev Rewarder contract to be deployed in wemix(main net).
 *
 * It is a contract that rewards events occurring in the game.
 * This contract must have FT for compensation.
 */
abstract contract Rewarder is Ownable, Pausable, UserNonce {
    using Address for address;
    using Counters for Counters.Counter;

    //===== VARIABLES =====//
    address public rt; // The token for reward.
    address public treasury; // The treasury that has rt.
    bytes32 public validatorRole; // The name of validator.

    IAccessControl roleManager;

    //===== EVENTS =====//
    event Rewarded(bytes32 indexed column, address indexed user, uint amount);
    event Shutdown(address indexed recipient, uint amount);
    event SetOption(bytes32 indexed option, address addr);

    modifier onlyValidator() {
        require(
            roleManager.hasRole(validatorRole, msg.sender),
            "Rewarder: sender is not validator"
        );
        _;
    }

    constructor(
        address token,
        address manager,
        address validator,
        bytes32 role
    ) {
        require(token.isContract(), "Rewarder: invalid token");
        require(validator != address(0), "Rewarder: invalid address");
        require(manager.isContract(), "Rewarder: invalid address");

        rt = token;
        validatorRole = role;
        roleManager = IAccessControl(manager);
        treasury = address(this);
    }

    //===== EXTERNAL FUNCTIONS =====//
    /**
     * @dev External function of paying reward to users.
     * @param user         wemix wallet address of the user who will be rewarded.
     * @param nonce        user nonce
     * @param amount       reward amount
     * @param column       event informaiton
     */
    function reward(
        address user,
        uint nonce,
        uint amount,
        bytes32 column
    ) external whenNotPaused onlyValidator {
        checkUserNonce(user, nonce);

        _transfer(user, amount);

        emit Rewarded(column, user, amount);
    }

    function setTreasury(address addr) external onlyOwner {
        require(addr != address(0), "ER: invalid address");
        treasury = addr;

        emit SetOption("treasury", treasury);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function shutdown(address to) external whenPaused onlyOwner {
        uint balance = IERC20(rt).balanceOf(treasury);

        if (balance > 0) {
            _transfer(to, balance);
        }

        emit Shutdown(to, balance);
    }

    //===== PUBLIC FUNCTIONS =====//
    /**
     * @return _
     * Of the amounts held in the treasury, the amount that can be used as rewards
     */
    function remainBalance() public view virtual returns (uint) {
        return IERC20(rt).balanceOf(treasury);
    }

    //===== INTERNAL FUNCTIONS =====//
    /**
     * @dev Internal function that trasnfer rt to "to".
     * @param to user address
     * @param amount reward amount
     */
    function _transfer(address to, uint amount) internal {
        if (treasury == address(this)) {
            require(IERC20(rt).transfer(to, amount));
        } else {
            require(IERC20(rt).transferFrom(treasury, to, amount));
        }
    }
}
