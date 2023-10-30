// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./SPLib.sol";
import "../interface/ISPBase.sol";
import "./calculator/SPKCalculator.sol";
import "./calculator/SPFeeCalculator.sol";
import "../../../../projects/Compounder/contracts/ICompounder.sol";
import "../../../openzeppelin-contracts/interfaces/IERC20.sol";
import "../../../openzeppelin-contracts/access/Ownable.sol";

/**
 * @title SPBase
 * @author Wemade Pte, Ltd
 * @dev This contract supports the basic functions of staking (stake, unstake, claim)
 * and manages user information participating in the staking.
 *
 * Note By staking a specific token, the reward token is compensated,
 * and the contract holds as much as the total compensation amount of this reward token.
 */
abstract contract SPBase is ISPBase, SPKCalculator, SPFeeCalculator, Ownable {
    using SPLib for SPLib.SP;
    using Address for address;
    using SafeERC20 for IERC20;

    //===== VARIABLES =====//
    SPLib.SP private _sp;

    bytes32 public game;
    address public compounder;

    address public override rt; // reward token
    address public override st; // staking token
    address public override rtVault; // address of vault storing rt
    address public override stVault; // address of vault storing st

    uint public override amountMax; // maximum amount to be rewarded

    bytes32 private constant BASE_STAKE = "base-stake-fee"; // column of base staking fee
    bytes32 private constant BASE_UNSTAKE = "base-unstake-fee"; // column of base unstaking fee
    bytes32 private constant BASE_CLAIM = "base-claim-fee"; // column of base claim fee

    constructor(
        bytes32 _game,
        address _rt,
        address _st,
        uint amount,
        bytes32 service,
        address recipientRole
    ) SPFeeCalculator(service, recipientRole) {
        game = _game;
        rt = _rt;
        st = _st;
        rtVault = address(this);
        stVault = address(this);
        amountMax = amount;
    }

    //===== EXTERNAL FUNCTIONS =====//
    /**
     * @dev Set end block
     * @param bn block number
     */
    function setEndBlock(uint bn) external onlyOwner {
        if (bn < block.number) revert UnderValue(bn, block.number);
        _sp._setEndBlock(bn);
    }

    /**
     * @dev Set the vault's address
     * @param _rtVault rt vault's address
     * @param _stVault st vault's address
     */
    function setVault(address _rtVault, address _stVault) public onlyOwner {
        if (_rtVault == address(0)) revert InvalidAddress(_rtVault);
        if (_stVault == address(0)) revert InvalidAddress(_stVault);

        if (IERC20(rt).balanceOf(rtVault) > 0) {
            if (rtVault == address(this)) {
                IERC20(rt).safeTransfer(
                    _rtVault,
                    IERC20(rt).balanceOf(rtVault)
                );
            } else {
                IERC20(rt).safeTransferFrom(
                    rtVault,
                    _rtVault,
                    IERC20(rt).balanceOf(rtVault)
                );
            }
        }

        if (IERC20(st).balanceOf(stVault) > 0) {
            if (stVault == address(this)) {
                IERC20(st).safeTransfer(_stVault, totalStakedAmount());
            } else {
                IERC20(st).safeTransferFrom(
                    stVault,
                    _stVault,
                    totalStakedAmount()
                );
            }
        }

        rtVault = _rtVault;
        stVault = _stVault;

        emit Set("RT_Vault", rtVault);
        emit Set("ST_Vault", stVault);
    }

    /**
     * @dev Set Compounder address
     * @param addr Compounder address
     */
    function setCompounder(address addr) external onlyOwner {
        if (!addr.isContract()) revert InvalidAddress(addr);
        compounder = addr;

        emit Set("Compounder", compounder);
    }

    /**
     * @dev Set base fee percents
     * @param stakeVal value of the fee perecent of staking
     * @param unstakeVal value of the fee perecent of unstaking
     * @param claimVal value of the fee perecent of claim
     */
    function setBaseFeePercent(
        uint stakeVal,
        uint unstakeVal,
        uint claimVal
    ) external onlyOwner {
        _setFeePercent(BASE_STAKE, stakeVal);
        _setFeePercent(BASE_UNSTAKE, unstakeVal);
        _setFeePercent(BASE_CLAIM, claimVal);
    }

    //===== PUBLIC FUNCTIONS =====//
    /**
     * @dev To get total mined reward token
     */
    function totalMinedRT() public view virtual override returns (uint) {}

    /**
     * @dev To get total amount of remain reward token
     */
    function remainRT() public view virtual override returns (uint) {
        uint amount = totalClaimedAmount() + totalClaimFee();
        return totalMinedRT() <= amount ? 0 : totalMinedRT() - amount;
    }

    /**
     * @dev To get estimated amount of compensation for the user
     * @param user user address
     */
    function amountMine(
        address user
    ) public view override returns (uint amount) {
        uint k = rewardK(totalMinedRT(), totalSP(), user);

        return (k * userSP(user)) / 1e22;
    }

    /**
     * @dev To get total stake point
     */
    function totalSP() public view virtual override returns (uint) {
        return totalStakedAmount();
    }

    /**
     * @dev To get stake point of the user
     */
    function userSP(address user) public view virtual override returns (uint) {
        return stakedAmount(user);
    }

    /**
     * @dev To get block number of end of stkaing
     */
    function endBlock() public view override returns (uint) {
        return _sp.endBlock;
    }

    /**
     * @dev To get count of staked users
     */
    function stakedCount() public view override returns (uint) {
        return _sp.stakedCount;
    }

    /**
     * @dev To get current total staked amount
     */
    function totalStakedAmount() public view override returns (uint) {
        return _sp.totalInfo.stakedAmount;
    }

    /**
     * @dev To get total claimed amount
     */
    function totalClaimedAmount() public view override returns (uint) {
        return _sp.totalInfo.claimedAmount;
    }

    /**
     * @dev To get total fee of staking of all
     */
    function totalStakeFee() public view override returns (uint) {
        return _sp.totalInfo.stakeFee;
    }

    /**
     * @dev To get total fee of unstaking of all
     */
    function totalUnstakeFee() public view override returns (uint) {
        return _sp.totalInfo.unstakeFee;
    }

    /**
     * @dev To get total fee of claim of all
     */
    function totalClaimFee() public view override returns (uint) {
        return _sp.totalInfo.claimFee;
    }

    /**
     * @dev To get current amount of staked st of the user
     * @param user user's address
     */
    function stakedAmount(address user) public view override returns (uint) {
        return _sp.userInfo[user].stakedAmount;
    }

    /**
     * @dev To get total amount of claimed rt of the user
     * @param user user's address
     */
    function claimedAmount(address user) public view override returns (uint) {
        return _sp.userInfo[user].claimedAmount;
    }

    /**
     * @dev To get total fee of staking of the user
     * @param user user's address
     */
    function stakeFee(address user) public view override returns (uint) {
        return _sp.userInfo[user].stakeFee;
    }

    /**
     * @dev To get total fee of unstaking token of the user
     * @param user user's address
     */
    function unstakeFee(address user) public view override returns (uint) {
        return _sp.userInfo[user].unstakeFee;
    }

    /**
     * @dev To get total fee of claim token of the user
     * @param user user's address
     */
    function claimFee(address user) public view override returns (uint) {
        return _sp.userInfo[user].claimFee;
    }

    /**
     * @dev To get last block number the user staked
     * @param user user's address
     */
    function stakedBlock(address user) public view override returns (uint) {
        return _sp.userInfo[user].stakedBlock;
    }

    /**
     * @dev To get last block number the user unstaked
     * @param user user's address
     */
    function unstakedBlock(address user) public view override returns (uint) {
        return _sp.userInfo[user].unstakedBlock;
    }

    /**
     * @dev To get last block number the user claimed
     * @param user user's address
     */
    function claimedBlock(address user) public view override returns (uint) {
        return _sp.userInfo[user].claimedBlock;
    }

    //===== INTERNAL FUNCTIONS =====//
    /**
     * @dev Stake the users' token
     * @param user user's address
     * @param amount amount of tokens
     */
    function _stake(address user, uint amount) internal virtual {
        uint totalFee;
        address _user = user; // avoid stack too deep
        bytes32[] memory columns = _stakeFeePercents(_user);

        if (columns.length > 0) {
            IERC20(st).safeTransferFrom(_user, address(this), amount);
            (amount, totalFee) = _addIncome(amount, _user, st, columns);
            if (stVault != address(this))
                IERC20(st).safeTransfer(stVault, amount);
        } else {
            IERC20(st).safeTransferFrom(_user, stVault, amount);
        }

        _afterStake(_user, amount, totalFee);
    }

    /**
     * @dev Unstake the user's token
     * @param user user's address
     * @param amount amount of tokens
     */
    function _unstake(address user, uint amount) internal virtual {
        uint totalFee;
        address _user = user; // avoid stack too deep
        bytes32[] memory columns = _unstakeFeePercents(_user);
        (amount, totalFee) = _reward(_user, st, columns, amount);
        _afterUnstake(_user, amount, totalFee);
    }

    /**
     * @dev Reward for the user's staking
     * @param user user's address
     */
    function _claim(address user) internal virtual {
        uint k = super._updateUserKWithReward(totalMinedRT(), totalSP(), user);
        if (k > 0) {
            uint amount = (k * userSP(user)) / 1e22;
            if (amount > 0) {
                uint totalFee;
                address _user = user; // avoid stack too deep
                bytes32[] memory columns = _claimFeePercents(_user);
                (amount, totalFee) = _reward(_user, rt, columns, amount);
                _afterClaim(_user, amount, totalFee);
            }
        }
        super._updateK(totalMinedRT(), totalSP());
    }

    /**
     * @dev Reward for the user's staking and restaking the reward
     * @param user user's address
     */
    function _compound(address user) internal virtual {
        uint k = super._updateUserKWithReward(totalMinedRT(), totalSP(), user);
        if (k > 0) {
            uint amount = (k * userSP(user)) / 1e22;
            if (amount > 0) {
                uint totalFee;
                address _user = user; // avoid stack too deep
                bytes32[] memory columns = _claimFeePercents(user);

                if (rtVault != address(this))
                    IERC20(rt).safeTransferFrom(rtVault, address(this), amount);
                if (columns.length > 0)
                    (amount, totalFee) = _addIncome(amount, _user, rt, columns);

                _afterClaim(_user, amount, totalFee);

                if (IERC20(rt).allowance(address(this), compounder) < amount) {
                    IERC20(rt).safeApprove(compounder, amount);
                }

                uint amountST = ICompounder(compounder).compound(amount);

                _afterStake(_user, amountST, 0);

                emit Compounded(
                    game,
                    _user,
                    rt,
                    st,
                    amount,
                    amountST,
                    totalFee,
                    claimedAmount(_user),
                    totalClaimedAmount(),
                    stakedAmount(_user),
                    totalStakedAmount()
                );
            }
        }
        super._updateK(totalMinedRT(), totalSP());
    }

    /**
     * @dev Cheack before stake
     * @param user user's address
     * @param amount amount of staked tokens
     */
    function _beforeStake(address user, uint amount) internal view virtual {
        if (stVault == address(0)) revert InvalidAddress(stVault);
        if (!(endBlock() == 0 || block.number <= endBlock()))
            revert OverEndBlock(endBlock());
        if (user == address(0)) revert InvalidAddress(user);
        if (amount <= 0) revert UnderValue(amount, 0);
    }

    /**
     * @dev Cheack before unstake
     * @param user user's address
     * @param amount amount of unstaked tokens
     */
    function _beforeUnstake(address user, uint amount) internal view virtual {
        if (stVault == address(0x000000000000000000000000000000000000dEaD))
            revert InvalidAddress(stVault);
        if (stakedAmount(user) <= 0) revert UnderValue(stakedAmount(user), 0);
        if (amount > stakedAmount(user))
            revert OverValue(amount, stakedAmount(user));
    }

    /**
     * @dev Cheack before claim
     * @param user user's address
     */
    function _beforeClaim(address user) internal view virtual {
        if (rtVault == address(0)) revert InvalidAddress(rtVault);
        if (stakedAmount(user) <= 0) revert UnderValue(stakedAmount(user), 0);
    }

    /**
     * @dev Update info after stake
     * @param user user's address
     * @param amount staked amount
     * @param totalFee total fee of staking
     */
    function _afterStake(
        address user,
        uint amount,
        uint totalFee
    ) internal virtual {
        _sp._updateStakeInfo(user, amount, totalFee);

        emit Staked(
            game,
            user,
            st,
            amount,
            totalFee,
            stakedAmount(user),
            totalStakedAmount()
        );
    }

    /**
     * @dev Update info after unstake
     * @param user user's address
     * @param amount unstaked amount
     * @param totalFee total fee of unstaking
     */
    function _afterUnstake(
        address user,
        uint amount,
        uint totalFee
    ) internal virtual {
        _sp._updateUnstakeInfo(user, amount, totalFee);

        emit Unstaked(
            game,
            user,
            st,
            amount,
            totalFee,
            stakedAmount(user),
            totalStakedAmount()
        );
    }

    /**
     * @dev Update info after claim
     * @param user user's address
     * @param amount claimed amount
     * @param totalFee total fee of claim
     */
    function _afterClaim(
        address user,
        uint amount,
        uint totalFee
    ) internal virtual {
        _sp._updateClaimInfo(user, amount, totalFee);

        emit Claimed(
            game,
            user,
            rt,
            amount,
            totalFee,
            claimedAmount(user),
            totalClaimedAmount()
        );
    }

    function _reward(
        address user,
        address token,
        bytes32[] memory columns,
        uint amount
    ) private returns (uint, uint) {
        uint totalFee;
        address vault = token == rt ? rtVault : stVault;

        if (vault != address(this))
            IERC20(token).safeTransferFrom(vault, address(this), amount);
        if (columns.length > 0)
            (amount, totalFee) = _addIncome(amount, user, token, columns);
        IERC20(token).safeTransfer(user, amount);

        return (amount, totalFee);
    }

    function _stakeFeePercents(
        address user
    ) internal view virtual override returns (bytes32[] memory columns) {
        columns = super._stakeFeePercents(user);
        columns = _addFee(feePercent[BASE_STAKE], BASE_STAKE, columns);
    }

    function _unstakeFeePercents(
        address user
    ) internal view virtual override returns (bytes32[] memory columns) {
        columns = super._unstakeFeePercents(user);
        columns = _addFee(feePercent[BASE_UNSTAKE], BASE_UNSTAKE, columns);
    }

    function _claimFeePercents(
        address user
    ) internal view virtual override returns (bytes32[] memory columns) {
        columns = super._claimFeePercents(user);
        columns = _addFee(feePercent[BASE_CLAIM], BASE_CLAIM, columns);
    }
}
