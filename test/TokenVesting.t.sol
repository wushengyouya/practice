// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import "../src/TokenVesting.sol";
import "../src/MyToken.sol";

contract TokenVestingTest is Test {
    MyToken token;
    TokenVesting tokenVesting;

    function setUp() public {
        token = new MyToken();
        tokenVesting = new TokenVesting(address(1), 100);
        token.mint(address(tokenVesting), 1000);
    }

    function test_release() public {
        //vm.warp(block.timestamp - 10);
        vm.expectRevert();
        tokenVesting.release(address(token));
        vm.warp(block.timestamp + 50);
        tokenVesting.release(address(token));
        console.log(token.balanceOf(address(1)));
        vm.warp(block.timestamp + 101);
        tokenVesting.release(address(token));
        assertEq(1000, token.balanceOf(address(1)));
    }
}
