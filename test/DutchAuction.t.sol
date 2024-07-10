// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
import "forge-std/Test.sol";
import "../src/DutchAuction.sol";
contract DutchAuctionTest is Test {
    DutchAuction dutch;
    function setUp() public {
        dutch = new DutchAuction("kumiko", "KMK");
    }

    function test_auctionMint() public {
        dutch.auctionStartTimeSetter(block.timestamp);
        vm.warp(block.timestamp + 20);
        dutch.auctionMint{value: 10 ether}(3);
        //assertEq(7, address(this).balance);
        assertEq(3, dutch.balanceOf(address(this)));
    }

    receive() external payable {}

    function test_withDraw() public {
        dutch.auctionStartTimeSetter(block.timestamp);
        vm.warp(block.timestamp + 20);
        dutch.auctionMint{value: 10 ether}(3);
        //assertEq(7, address(this).balance);
        assertEq(3, dutch.balanceOf(address(this)));
        dutch.withdrawMoney();
        assertEq(10, address(this).balance);
    }
}
