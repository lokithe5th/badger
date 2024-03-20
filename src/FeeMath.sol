// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./CollateralTokenTester.sol";

contract FeeMath {
    uint256 public stakingRewardSplit;
    uint256 public constant MAX_REWARD_SPLIT = 1e4;
    uint256 public constant DECIMAL_PRECISION = 1e18;

    uint256 public targetShareAmount;

    ICollateralToken public collateral;

    constructor(uint256 _split, address _collateral) {
        require(_split <= 10000, "Split too large");
        stakingRewardSplit = _split;
        collateral = ICollateralToken(_collateral);
    }

    function setStakingRewardSplit(uint256 _split) external {
        require(_split <= MAX_REWARD_SPLIT, "PYS too great");
        stakingRewardSplit = _split;
    }

    // Normally this is used to get the fee that should be subtracted from the collShares upon rebase
    // But we want to be able to test the math on either CDP or system
    function setShareTarget(uint256 shares) external {
        targetShareAmount = shares;
    }

    /// @notice Calculate fee for given pair of collateral indexes
    /// @param _newIndex The value synced with stETH.getPooledEthByShares(1e18)
    /// @param _prevIndex The cached global value of `stEthIndex`
    /// @return _feeTaken The fee split in collateral token which will be deduced from current total system collateral
    /// Ripped this out _deltaFeePerUnit The fee split increase per unit, used to added to `systemStEthFeePerUnitIndex`
    /// Ripped this out _perUnitError The fee split calculation error, used to update `systemStEthFeePerUnitIndexError`
    function calcFeeUponStakingReward(
        uint256 _newIndex,
        uint256 _prevIndex
    ) public view returns (uint256) {
        require(_newIndex > _prevIndex, "CDPManager: only take fee with bigger new index");
        uint256 deltaIndex = (_newIndex - _prevIndex); // 1e18
        uint256 deltaIndexFees = (deltaIndex * stakingRewardSplit) / MAX_REWARD_SPLIT;

        // we take the fee for all CDPs immediately which is scaled by index precision
        uint256 _deltaFeeSplit = deltaIndexFees * targetShareAmount;

        // return the values to update the global fee accumulator
        uint256 _feeTaken = collateral.getSharesByPooledEth(_deltaFeeSplit) / DECIMAL_PRECISION;
        return (_feeTaken+1);
    }
}
