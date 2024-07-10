// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import "../src/NFTSwap.sol";
import "../src/HQKitty.sol";
contract NFTSwapTest is Test {
    HQKitty hqk;
    NFTSwap nftSwap;
    function setUp() public {
        hqk = new HQKitty();
        nftSwap = new NFTSwap();
        hqk.safeMint(address(1));
        hqk.safeMint(address(1));
        hqk.safeMint(address(1));
        vm.prank(address(1));
        hqk.approve(address(nftSwap), 1);
    }

    function test_list() public {
        vm.prank(address(1));
        nftSwap.list(address(hqk), 1, 3);
    }
    function test_purchase() public {
        vm.prank(address(1));
        nftSwap.list(address(hqk), 1, 3);
        uint256 addr2Amount = address(1).balance;

        vm.deal(address(2), 10); //模拟以太币,给账户2转入 10 ether
        //  vm.deal(address(nftSwap), 2 ether);
        vm.prank(address(2));
        nftSwap.purchase{value: 10}(address(hqk), 1);
        assertEq(1, hqk.balanceOf(address(2)));
        assertEq(addr2Amount + 3, address(1).balance);
        console.log(address(2).balance);
    }
    function test_revoke() public {}
    function test_update() public {}
}
