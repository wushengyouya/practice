// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/RandomOnchain.sol";

contract RandomOnchainTest is Test {
    RandomOnchain r;

    function setUp() public {
        r = new RandomOnchain();
    }
    //链上产生随机数

    function test_getRandomOnchain() public {
        r.getRandomOnchain();
    }
}
