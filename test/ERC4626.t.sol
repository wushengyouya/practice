// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;
import {Test, console} from "forge-std/Test.sol";
import "../src/ERC4626.sol";
import "../src/MyToken.sol";
import "../src/IERC4626.sol";
contract ERC4626Test is Test {
    IERC4626 ierc4626;
    MyToken token;
    function setUp() public {
        token = new MyToken();
        token.mint(address(this), 1000);
        ierc4626 = new ERC4626(token, "kumiko", "KMK");
    }

    function test_deposit() public {
        token.approve(address(ierc4626), 1000);
        ierc4626.deposit(1000, address(2));
        ierc4626.balanceOf(address(2));
    }

    function test_withdraw() public {
        token.approve(address(ierc4626), 1000);
        ierc4626.deposit(1000, address(this));
        ierc4626.withdraw(600, address(1), address(this));
        assertEq(ierc4626.balanceOf(address(this)), 400);
        assertEq(600, token.balanceOf(address(1)));
    }

    function test_withdraw2() public {
        vm.startPrank(address(6));
        token.mint(address(6), 1000);
        token.approve(address(ierc4626), 1000);
        ierc4626.deposit(1000, address(6));
        ierc4626.approve(address(3), 1000);
        vm.stopPrank();
        //-----------------------------
        token.mint(address(3), 1000);
        vm.startPrank(address(3));
        token.approve(address(ierc4626), 1000);
        ierc4626.deposit(1000, address(3));
        ierc4626.withdraw(600, address(4), address(6));
        assertEq(ierc4626.balanceOf(address(3)), 1000);
        assertEq(600, token.balanceOf(address(4)));
        vm.stopPrank();
    }
}
