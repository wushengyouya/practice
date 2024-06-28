// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../src/IRewardToken.sol";
import "../src/StakeSystem.sol";
import "../src/HackQuest.sol";
import "../src/HQKitty.sol";
//质押合约测试
contract StakeSystemTest is Test {
    HQKitty hqkitty;
    HackQuest hackQuest;
    StakeSystem stakeSystem;
    function setUp() public {
        hqkitty = new HQKitty();
        hackQuest = new HackQuest();
        stakeSystem = new StakeSystem(hqkitty, hackQuest);
        hackQuest.setMintRole(address(this));

        hqkitty.safeMint(msg.sender);
        hackQuest.mint(msg.sender, 2000);
    }

    function test_mint() public {
        hackQuest.mint(msg.sender, 100);
        uint256 balance = hackQuest.balanceOf(
            0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
        );
        assertEq(100 + 2000, balance);
    }

    function testFail_mint() public {
        hackQuest.mint(msg.sender, 100);
        uint256 balance = hackQuest.balanceOf(
            0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
        );
        assertEq(101, balance);
    }

    function test_MintNft() public {
        hqkitty.safeMint(msg.sender);
        uint256 balance = hqkitty.balanceOf(
            0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
        );
        address sender = msg.sender;
        emit log_address(sender);
        assertEq(2, balance);
    }

    function test_OwnerOf() public {
        address owner = hqkitty.ownerOf(1);
        assertEq(owner, msg.sender);
    }

    function test_Stake() public {
        vm.startPrank(address(1));
        hqkitty.safeMint(address(1));
        stakeSystem.stake(2);
        vm.stopPrank();
    }
}
