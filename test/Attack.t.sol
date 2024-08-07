//重入攻击测试

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import "../src/Attack.sol";
import "../src/Bank.sol";

contract AttackTest is Test {
    Attack attack;
    Bank bank;

    function setUp() public {
        bank = new Bank();
        bank.deposit{value: 10 ether}();
        attack = new Attack(bank);
    }
    //不带主币

    function testFail_withdrawNotEth() public {
        attack.attack();
    }
    //带了1 ether

    function test_attack() public {
        attack.attack{value: 1 ether}();
        assertEq(address(attack).balance, 11 ether);
        assertEq(address(bank).balance, 0);
    }
}
