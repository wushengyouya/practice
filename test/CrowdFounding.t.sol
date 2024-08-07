// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "../src/IRewardToken.sol";
import "../src/CrowdFounding.sol";
import "../src/HackQuest.sol";

//众筹合约测试
contract CrowdFoundingTest is Test {
    IRewardToken token;
    CrowdFounding crowd;

    function setUp() public {
        HackQuest hackquest = new HackQuest();
        crowd = new CrowdFounding(address(hackquest));
        console.log(msg.sender);
        hackquest.setMintRole(address(this));
        token = hackquest;
        token.mint(address(1), 1000);
        token.mint(address(2), 200);
        token.mint(address(3), 200);
        token.mint(address(4), 200);
        crowd.launch(500, block.timestamp + 300);
        crowd.launch(200, block.timestamp + 300);

        vm.prank(address(1));
        token.approve(address(crowd), 300);
        vm.prank(address(1));
        crowd.crowdFounding(1, 300);

        vm.prank(address(2));
        token.approve(address(crowd), 200);
        vm.prank(address(2));
        crowd.crowdFounding(1, 200);
    }

    // function test_launch() public {
    //     crowd.launch(500, block.timestamp + 300);
    // }

    function test_banlanceOf() public view {
        uint256 amount = token.balanceOf(address(1));
        assertEq(amount, 700);
    }
    //参与众筹

    function test_crowd() public view {
        (uint256 crowdId, uint256 raiseAmount, address owner) = crowd.getCrowdFounding(1);
        assertEq(700, token.balanceOf(address(1)));
        console.log(crowdId, raiseAmount, owner);
    }

    //撤销众筹
    function test_cancelCrowdFounding() public {
        vm.prank(address(3));
        token.approve(address(crowd), 100);
        vm.prank(address(4));
        token.approve(address(crowd), 100);

        vm.prank(address(3));
        crowd.crowdFounding(2, 100);
        vm.prank(address(4));
        crowd.crowdFounding(2, 100);
        uint256 u3 = token.balanceOf(address(3));
        uint256 u4 = token.balanceOf(address(4));
        assertEq(u3, 100);
        assertEq(u4, 100);

        crowd.cancelCrowdFounding(2);
        vm.prank(address(3));
        uint256 myAmount = crowd.getUserRaiseAmount(3);
        assertEq(0, myAmount);

        uint256 myBalance3 = token.balanceOf(address(3));
        assertEq(200, myBalance3);
        uint256 myBalance4 = token.balanceOf(address(4));
        assertEq(200, myBalance4);
    }
    //结束众筹

    function test_endCrowdFounding() public {
        vm.warp(block.timestamp + 500); //设置区块时间
        crowd.getCrowdFounding(1);
        crowd.endCrowdFounding(1);
        uint256 amount = token.balanceOf(address(this));
        uint256 addr1Amount = token.balanceOf(address(1));
        uint256 addr2Amount = token.balanceOf(address(2));
        assertEq(addr1Amount, 700);
        assertEq(addr2Amount, 0);
        assertEq(amount, 500);
    }
}
