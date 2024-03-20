// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {FeeMath} from "../src/FeeMath.sol";
import {CollateralTokenTester} from "../src/FeeMath.sol";

contract FeeMathTest is Test {
    CollateralTokenTester public collateral;
    FeeMath public feeMath;

    address public bob = address(100001);
    address public alice = address(100002);

    function setUp() public {
        collateral = new CollateralTokenTester();
        feeMath = new FeeMath(0, address(collateral));

        deal(bob, 1e30);
        deal(alice, 1e30);

        vm.prank(bob);
        collateral.deposit{value: 1000 ether}();

        vm.prank(alice);
        collateral.deposit{value: 1000 ether}();

    }

    function test_FeeSplit(uint256 baseIndex, uint256 amountCollFeeSplit/*, uint256 pys*/) public {
        baseIndex = bound(baseIndex, 1e18, 1e21);
        amountCollFeeSplit = bound(amountCollFeeSplit, 1e18, 1e30);
        uint256 pys = 1000; // bound(pys, 50, 10_000);

        feeMath.setStakingRewardSplit(pys);
        feeMath.setShareTarget(amountCollFeeSplit);

        // Always be a 10 percent increase, so we know the yield must be 10% if PYS @ 0
        uint256 newIndex = (baseIndex * 10 / 100) + baseIndex;
        assert(newIndex > baseIndex);

        // Of the 10% take the split fee
        uint256 expectedFee = (amountCollFeeSplit * 1000 / 10000) * feeMath.stakingRewardSplit() / feeMath.MAX_REWARD_SPLIT();
        uint256 actualFee = feeMath.calcFeeUponStakingReward(newIndex, baseIndex);
        console2.log("ExpectedFee ", expectedFee);
        console2.log("ActualFee ", actualFee);

        //assertApproxEqAbs(expectedFee, actualFee, 1e6);
        require(expectedFee == actualFee, "Fee not as expected");
    }
}
