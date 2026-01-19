// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Tokenomics} from "../src/Tokenomics.sol";
import {DeployTokenomics} from "../script/DeployTokenomics.s.sol";

contract TestTokenomics is Test {
    Tokenomics tokenomics;
    DeployTokenomics deploy;

    function setUp() public {
        deploy = new DeployTokenomics();
        tokenomics = deploy.run();
        vm.prank(msg.sender);
    }

    function testTokenIsCreated() public view {
        assertEq(tokenomics.currentSupply(), 100000 ether);
        assertEq(tokenomics.volumePerTerm(), 0);
        assertEq(tokenomics.currentTerm(), 1);
        assertEq(tokenomics.startingTimeOfTerm(), block.number);
    }

    function testStakeIsDone() public {
        tokenomics.transfer(msg.sender, 200);
        tokenomics.stake(100);
        vm.expectEmit(false, false, false, true);
        emit Tokenomics.Staked(msg.sender, 100);
        (uint256 stakedAmount, uint256 lockedUntil, ) = tokenomics
            .stakedPerAccount(msg.sender);
        assertEq(lockedUntil, block.number + 100800);
        assertEq(stakedAmount, 100);
        assertEq(tokenomics.volumePerTerm(), 100);
    }
}
