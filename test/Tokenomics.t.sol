// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Tokenomics} from "../src/Tokenomics.sol";
import {DeployTokenomics} from "../script/DeployTokenomics.s.sol";

contract TestTokenomics is Test {
    Tokenomics tokenomics;
    DeployTokenomics deploy;
    address treasury = makeAddr("treasury");

    function setUp() public {
        deploy = new DeployTokenomics();
        tokenomics = deploy.run(treasury);
    }

    function testTokenIsCreated() public view {
        assertEq(tokenomics.treasury(), treasury);
        assertEq(tokenomics.currentSupply(), 100000 ether);
        assertEq(tokenomics.volumePerTerm(), 0);
        assertEq(tokenomics.currentTerm(), 1);
        assertEq(tokenomics.startingTimeOfTerm(), block.timestamp);
    }

    function testStakeIsDone() public {
        vm.prank(treasury);
        tokenomics.transfer(msg.sender, 200);
        vm.prank(msg.sender);
        vm.expectEmit(false, false, false, true);
        emit Tokenomics.Staked(msg.sender, 100);
        tokenomics.stake(100);
        (uint256 stakedAmount, uint256 lockedUntil, ) = tokenomics
            .stakedPerAccount(msg.sender);
        assertEq(lockedUntil, block.timestamp + 14 days);
        assertEq(stakedAmount, 100);
        assertEq(tokenomics.volumePerTerm(), 100);
    }

    function testStakeRevertsIfAmountIsInvalid() public {
        vm.prank(treasury);
        tokenomics.transfer(msg.sender, 200);
        vm.expectRevert(Tokenomics.Stake_InvalidAmount.selector);
        tokenomics.stake(0);
    }

    function testUnstakeIsDone() public {
        vm.prank(treasury);
        tokenomics.transfer(msg.sender, 200);
        vm.startPrank(msg.sender);
        tokenomics.stake(200);
        vm.warp(block.timestamp + 15 days);
        vm.expectEmit(false, false, false, true);
        emit Tokenomics.Unstaked(msg.sender, 200);
        tokenomics.unstake(200);
        vm.stopPrank();
        (uint256 stakedAmount, , ) = tokenomics.stakedPerAccount(msg.sender);
        assertEq(stakedAmount, 0);
        assertEq(tokenomics.volumePerTerm(), 200);
    }

    function testUnstakeRevertsIfAmountIsInvalid() public {
        vm.prank(treasury);
        tokenomics.transfer(msg.sender, 200);
        vm.startPrank(msg.sender);
        tokenomics.stake(200);
        vm.expectRevert(Tokenomics.Unstake_InvalidAmount.selector);
        tokenomics.unstake(0);
    }

    function testUnstakeRevertsIfStakeIsLocked() public {
        vm.prank(treasury);
        tokenomics.transfer(msg.sender, 200);
        vm.startPrank(msg.sender);
        tokenomics.stake(200);
        vm.expectRevert(Tokenomics.Unstake_StakeLocked.selector);
        tokenomics.unstake(200);
    }

    function testUnstakeRevertsIfNotEnoughTokenIsStaked() public {
        vm.prank(treasury);
        tokenomics.transfer(msg.sender, 200);
        vm.startPrank(msg.sender);
        tokenomics.stake(200);
        vm.warp(block.timestamp + 15 days);
        vm.expectRevert(Tokenomics.Unstake_NotEnoughAmountStaked.selector);
        tokenomics.unstake(500);
    }
}
