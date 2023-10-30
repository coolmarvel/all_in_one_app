// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./core/SPMineSchedule.sol";
import "./option/SPCoolTime.sol";
import "./option/SPLockUp.sol";
import "./option/SPLimit.sol";
import "./option/SPMultiPoint.sol";
import "../../../projects/ExecuteManager/contracts/IExecuteManager.sol";
import "../../openzeppelin-contracts/security/ReentrancyGuard.sol";

/**
 * @title SPSchedule
 * @author Wemade Pte, Ltd
 * @dev Standard Staking Pool ver.Schedule
 */
contract SPSchedule is
    SPMineSchedule,
    SPCoolTime,
    SPLockUp,
    SPLimit,
    SPMultiPoint,
    ReentrancyGuard
{
    using Address for address;
    address public executeManager;

    modifier onlyExecutable(bytes4 selector) {
        require(
            IExecuteManager(executeManager).isExecutable(selector),
            "SPSchedule: not executable"
        );
        _;
    }

    constructor(
        bytes32 game,
        address rt,
        address st,
        uint amount,
        bytes32 service,
        address recipientRole,
        address _excuteManager
    ) SPMineSchedule(game, rt, st, amount, service, recipientRole) {
        if (!_excuteManager.isContract()) revert InvalidAddress(_excuteManager);
        executeManager = _excuteManager;
    }

    function stake(
        uint amount
    ) external nonReentrant onlyExecutable(this.stake.selector) {
        _beforeStake(msg.sender, amount);
        _claim(msg.sender);
        _stake(msg.sender, amount);
    }

    function unstake(
        uint amount
    ) external nonReentrant onlyExecutable(this.unstake.selector) {
        _beforeUnstake(msg.sender, amount);
        _claim(msg.sender);
        _unstake(msg.sender, amount);
    }

    function claim() external nonReentrant onlyExecutable(this.claim.selector) {
        _beforeClaim(msg.sender);
        _claim(msg.sender);
    }

    /**
     * @dev Stake the sender's token and compound
     * @param amount amount of tokens
     */
    function stakeWithCompound(
        uint amount
    ) external nonReentrant onlyExecutable(this.stakeWithCompound.selector) {
        _beforeStake(msg.sender, amount);
        _compound(msg.sender);
        _stake(msg.sender, amount);
    }

    /**
     * @dev Unstake the sender's token and compound
     * @param amount amount of tokens
     */
    function unstakeWithCompound(
        uint amount
    ) external nonReentrant onlyExecutable(this.unstakeWithCompound.selector) {
        _beforeUnstake(msg.sender, amount);
        _compound(msg.sender);
        _unstake(msg.sender, amount);
    }

    /**
     * @dev Reward for the sender's staking and restaking the reward
     */
    function compound()
        external
        nonReentrant
        onlyExecutable(this.compound.selector)
    {
        _beforeClaim(msg.sender);
        _compound(msg.sender);
    }

    function totalMinedRT()
        public
        view
        override(SPBase, SPMineSchedule)
        returns (uint)
    {
        return super.totalMinedRT();
    }

    function totalSP()
        public
        view
        virtual
        override(SPBase, SPMultiPoint)
        returns (uint)
    {
        return super.totalSP();
    }

    function userSP(
        address user
    ) public view virtual override(SPBase, SPMultiPoint) returns (uint) {
        return super.userSP(user);
    }

    function getBaseInfo() external view override returns (BaseInfo memory) {
        (uint preStart, uint preEnd) = getPreStakeInfo();
        return
            BaseInfo({
                gameId: game,
                st: st,
                rt: rt,
                useMP: useMP,
                preStart: preStart,
                preEnd: preEnd,
                startBlock: startBlock,
                stakeMinLimit: stakeMinLimit,
                stakeMaxLimit: stakeMaxLimit,
                globalLu: globalLu,
                userLu: userLu
            });
    }

    function getVariableInfo()
        external
        view
        override
        returns (VariableInfo memory)
    {
        return
            VariableInfo({
                totalStakedAmount: totalStakedAmount(),
                totalClaimedAmount: totalClaimedAmount(),
                stakedCount: stakedCount()
            });
    }

    function _claim(address user) internal virtual override {
        _updateMP(user);
        super._claim(user);
    }

    function _compound(address user) internal virtual override {
        _updateMP(user);
        super._compound(user);
    }

    function _beforeStake(
        address user,
        uint amount
    )
        internal
        view
        virtual
        override(SPBase, SPMineSchedule, SPCoolTime, SPLimit)
    {
        super._beforeStake(user, amount);
    }

    function _beforeUnstake(
        address user,
        uint amount
    ) internal view virtual override(SPBase, SPCoolTime, SPLimit, SPLockUp) {
        super._beforeUnstake(user, amount);
    }

    function _beforeClaim(
        address user
    ) internal view virtual override(SPBase, SPCoolTime) {
        super._beforeClaim(user);
    }

    function _afterStake(
        address user,
        uint amount,
        uint totalFee
    ) internal virtual override(SPBase, SPLockUp, SPLimit, SPMultiPoint) {
        super._afterStake(user, amount, totalFee);
    }

    function _afterUnstake(
        address user,
        uint amount,
        uint totalFee
    ) internal virtual override(SPBase, SPMultiPoint) {
        super._afterUnstake(user, amount, totalFee);
    }

    function _stakeFeePercents(
        address user
    )
        internal
        view
        virtual
        override(SPBase, SPCoolTime)
        returns (bytes32[] memory columns)
    {
        columns = super._stakeFeePercents(user);
    }

    function _unstakeFeePercents(
        address user
    )
        internal
        view
        virtual
        override(SPBase, SPCoolTime, SPLockUp)
        returns (bytes32[] memory columns)
    {
        columns = super._unstakeFeePercents(user);
    }

    function _claimFeePercents(
        address user
    )
        internal
        view
        virtual
        override(SPBase, SPCoolTime)
        returns (bytes32[] memory columns)
    {
        columns = super._claimFeePercents(user);
    }

    function shutdown(address to) external onlyOwner {
        require(to != address(0), "SPB-01");
        uint rtBalance = IERC20(rt).balanceOf(rtVault);
        uint stBalance = IERC20(st).balanceOf(stVault);

        rtVault == address(this)
            ? require(IERC20(rt).transfer(to, rtBalance))
            : require(IERC20(rt).transferFrom(rtVault, to, rtBalance));
        if (stVault != address(0x000000000000000000000000000000000000dEaD)) {
            stVault == address(this)
                ? require(IERC20(st).transfer(to, stBalance))
                : require(IERC20(st).transferFrom(stVault, to, stBalance));
        }
    }
}
