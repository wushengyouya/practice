// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;
import "forge-std/Test.sol";
import "../src/SimpleUpgrade.sol";
contract SimpleUpgradeTest is Test {
    SimpleUpgrade simple;
    Logic1 logic1;
    function setUp() public {
        logic1 = new Logic1();
        simple = new SimpleUpgrade(address(logic1));
    }

    function test_old() public {
        vm.prank(address(1));
        (bool success, ) = address(simple).call(
            abi.encodeWithSignature("foo()")
        );
        string memory world = simple.words();
        assertEq(world, "old");
    }

    function test_upgradeNew() public {
        vm.prank(address(1));
        (bool success, ) = address(simple).call(
            abi.encodeWithSignature("foo()")
        );
        string memory world = simple.words();
        assertEq(world, "old");

        //升级到Logic2
        Logic2 login2 = new Logic2();
        simple.upgrade(address(login2));
        vm.prank(address(1));
        (bool success2, ) = address(simple).call(
            abi.encodeWithSignature("foo()")
        );
        string memory world2 = simple.words();
        assertEq(world2, "new");
    }

    //通用可升级代理测试
    function test_upgrade2() public {
        vm.prank(address(1));
        (bool success, ) = address(simple).call(
            abi.encodeWithSignature("foo()")
        );
        string memory world = simple.words();
        assertEq(world, "old");
        Logic2 logic2 = new Logic2();
        address(logic1).call(
            abi.encodeWithSignature("upgrade2(address)", address(logic2))
        );

        vm.prank(address(1));
        (bool success2, ) = address(simple).call(
            abi.encodeWithSignature("foo()")
        );
        string memory world2 = simple.words();
        assertEq(world, "new");
    }
}
