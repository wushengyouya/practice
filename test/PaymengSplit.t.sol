// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/PaymentSplit.sol";

contract PaymengSplitTest is Test {
    PaymentSplit ps;

    function setUp() public {
        address[] memory payees = new address[](2);
        payees[0] = address(1);
        payees[1] = address(2);
        uint256[] memory shares = new uint256[](2);
        shares[0] = 2;
        shares[1] = 2;
        ps = new PaymentSplit(payees, shares);
        vm.deal(address(ps), 10);
    }

    function test_release() public {
        ps.release(payable(address(1)));
        assertEq(5, address(1).balance);
    }

    function test_releasable() public {}
    function test_pendingPayment() public {}
}
