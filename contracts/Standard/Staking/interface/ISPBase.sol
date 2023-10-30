// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

struct BaseInfo {
    bytes32 gameId;
    address st;
    address rt;
    bool useMP;
    uint preStart;
    uint preEnd;
    uint startBlock;
    uint stakeMinLimit;
    uint stakeMaxLimit;
    uint globalLu;
    uint userLu;
}

struct VariableInfo {
    uint totalStakedAmount;
    uint totalClaimedAmount;
    uint stakedCount;
}

interface ISPBase {
    event Set(bytes32 indexed column, address addr);
    event Staked(
        bytes32 indexed game,
        address indexed user,
        address indexed st,
        uint amount,
        uint totalFee,
        uint stakedAmount,
        uint totalStakedAmount
    );
    event Unstaked(
        bytes32 indexed game,
        address indexed user,
        address indexed st,
        uint amount,
        uint totalFee,
        uint stakedAmount,
        uint totalStakedAmount
    );
    event Claimed(
        bytes32 indexed game,
        address indexed user,
        address indexed rt,
        uint amount,
        uint totalFee,
        uint claimedAmount,
        uint totalClaimedAmount
    );
    event Compounded(
        bytes32 indexed game,
        address indexed user,
        address indexed rt,
        address st,
        uint amountRT,
        uint amountST,
        uint totalFee,
        uint claimedAmount,
        uint totalClaimedAmount,
        uint stakedAmount,
        uint totalStakedAmount
    );

    function rt() external view returns (address);

    function st() external view returns (address);

    function rtVault() external view returns (address);

    function stVault() external view returns (address);

    function totalMinedRT() external view returns (uint);

    function remainRT() external view returns (uint);

    function amountMax() external view returns (uint);

    function amountMine(address user) external view returns (uint amount);

    function totalSP() external view returns (uint);

    function userSP(address user) external view returns (uint);

    function endBlock() external view returns (uint);

    function stakedCount() external view returns (uint);

    function totalStakedAmount() external view returns (uint);

    function totalClaimedAmount() external view returns (uint);

    function totalStakeFee() external view returns (uint);

    function totalUnstakeFee() external view returns (uint);

    function totalClaimFee() external view returns (uint);

    function stakedAmount(address user) external view returns (uint);

    function claimedAmount(address user) external view returns (uint);

    function stakeFee(address user) external view returns (uint);

    function unstakeFee(address user) external view returns (uint);

    function claimFee(address user) external view returns (uint);

    function stakedBlock(address user) external view returns (uint);

    function unstakedBlock(address user) external view returns (uint);

    function claimedBlock(address user) external view returns (uint);

    function getBaseInfo() external view returns (BaseInfo memory);

    function getVariableInfo() external view returns (VariableInfo memory);
}
