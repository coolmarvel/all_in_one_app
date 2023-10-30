// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ISPLimit {
    // ============== LIMIT ERROR ==============
    error InvalidUnit(bytes32 func, uint amount, uint unit);
    error OverStakeMaxLimit(uint amount, uint max);
    error UnderMinLimit(bytes32 func, uint amount, uint min);
    error OverUserStakeMax(
        address user,
        uint amount,
        uint stakedAmount,
        uint max
    );
    error OverTotalStakeMax(
        address user,
        uint amount,
        uint totalStakedAmount,
        uint max
    );

    function stakeUnit() external view returns (uint);

    function unstakeUnit() external view returns (uint);

    function stakeMaxLimit() external view returns (uint);

    function stakeMinLimit() external view returns (uint);

    function unstakeMinLimit() external view returns (uint);

    function stakeUserMaxLimit() external view returns (uint);

    function stakeTotalMaxLimit() external view returns (uint);
}
