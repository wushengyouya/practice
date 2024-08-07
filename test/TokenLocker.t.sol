// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import "../src/TokenLocker.sol";
import "../src/MyToken.sol";

contract TokenLockerTest is Test {
    MyToken token;
    TokenLocker tokenLocker;

    function setUp() public {
        token = new MyToken();
        tokenLocker = new TokenLocker(100, address(1), address(token));
        token.mint(address(tokenLocker), 1000);
    }

    function testFail_releaseUser() public {
        tokenLocker.release();
    }

    function testFail_releaseTime() public {
        vm.prank(address(1));
        tokenLocker.release();
    }

    function test_release() public {
        vm.warp(block.timestamp + 101);
        vm.prank(address(1));
        tokenLocker.release();
        assertEq(1000, token.balanceOf(address(1)));
    }
}
