// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../base/SPBase.sol";
import "../interface/ISPCore.sol";
import "../interface/ISPMineRevenue.sol";

/**
 * @title SPMineRevenue
 * @author Wemade Pte, Ltd
 * @dev This contract calculates totalMinedRT as revenue coming into rt-vault
 */
abstract contract SPMineRevenue is ISPCore, ISPMineRevenue, SPBase {
    //===== VARIABLES =====//
    uint public override lastBalance; // last rt balance of the rtVault
    uint private _totalRevenue; // total revenue of the rtVault

    event Renew(
        uint time,
        uint lastBalance,
        uint currentBalance,
        uint _totalRevenue
    );

    constructor(
        bytes32 game,
        address rt,
        address st,
        bytes32 service,
        address recipientRole
    ) SPBase(game, rt, st, 0, service, recipientRole) {}

    //===== EXTERNAL FUNCTIONS =====//
    function mineType() external pure override returns (Core.MineType) {
        return Core.MineType.Revenue;
    }

    /**
     * @dev Update totalMinedRT by rtVault's revenue
     */
    function renew() public {
        uint currentBalance = IERC20(rt).balanceOf(rtVault);
        if (lastBalance < currentBalance) {
            _totalRevenue =
                currentBalance +
                totalClaimedAmount() +
                totalClaimFee();
            emit Renew(
                block.timestamp,
                lastBalance,
                currentBalance,
                _totalRevenue
            );
        }

        lastBalance = currentBalance;
    }

    function totalMinedRT() public view virtual override returns (uint amount) {
        amount = _totalRevenue;
        uint currentBalance = IERC20(rt).balanceOf(rtVault);
        if (lastBalance < currentBalance) {
            amount = currentBalance + totalClaimedAmount() + totalClaimFee();
        }

        if (amountMax > 0 && amount > amountMax) amount = amountMax;
    }

    //===== INTERNAL FUNCTIONS =====//
    function _claim(address user) internal virtual override {
        renew();
        super._claim(user);
        renew();
    }

    function _compound(address user) internal virtual override {
        renew();
        super._compound(user);
        renew();
    }
}
