// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library SPLib {
    struct SPInfo {
        uint stakedBlock; // block number user staked last
        uint unstakedBlock; // block number user unstaked last
        uint claimedBlock; // block number user claimed last
        uint stakedAmount; // current amount of staked st
        uint claimedAmount; // total amount of claimed rt
        uint stakeFee; // current amount of staking fee
        uint unstakeFee; // total amount of unstaking fee
        uint claimFee; // total amount of claim fee
    }

    struct SP {
        uint endBlock;
        uint stakedCount;
        SPInfo totalInfo;
        mapping(address => SPInfo) userInfo;
    }

    function _setEndBlock(SP storage sp, uint bn) internal {
        sp.endBlock = bn;
    }

    function _updateStakeInfo(
        SP storage sp,
        address account,
        uint amount,
        uint totalFee
    ) internal {
        if (sp.userInfo[account].stakedAmount == 0)
            sp.stakedCount = sp.stakedCount + 1;

        sp.userInfo[account].stakedBlock = block.number;
        sp.userInfo[account].stakeFee =
            sp.userInfo[account].stakeFee +
            totalFee;
        sp.userInfo[account].stakedAmount =
            sp.userInfo[account].stakedAmount +
            amount;

        sp.totalInfo.stakeFee = sp.totalInfo.stakeFee + totalFee;
        sp.totalInfo.stakedAmount = sp.totalInfo.stakedAmount + amount;
    }

    function _updateUnstakeInfo(
        SP storage sp,
        address account,
        uint amount,
        uint totalFee
    ) internal {
        sp.userInfo[account].unstakedBlock = block.number;
        sp.userInfo[account].unstakeFee =
            sp.userInfo[account].unstakeFee +
            totalFee;
        sp.userInfo[account].stakedAmount =
            sp.userInfo[account].stakedAmount -
            (amount + totalFee);

        sp.totalInfo.unstakeFee = sp.totalInfo.unstakeFee + totalFee;
        sp.totalInfo.stakedAmount =
            sp.totalInfo.stakedAmount -
            amount +
            totalFee;

        if (sp.userInfo[account].stakedAmount == 0)
            sp.stakedCount = sp.stakedCount - 1;
    }

    function _updateClaimInfo(
        SP storage sp,
        address account,
        uint amount,
        uint totalFee
    ) internal {
        sp.userInfo[account].claimedBlock = block.number;
        sp.userInfo[account].claimFee =
            sp.userInfo[account].claimFee +
            totalFee;
        sp.userInfo[account].claimedAmount =
            sp.userInfo[account].claimedAmount +
            amount;

        sp.totalInfo.claimFee = sp.totalInfo.claimFee + totalFee;
        sp.totalInfo.claimedAmount = sp.totalInfo.claimedAmount + amount;
    }
}
