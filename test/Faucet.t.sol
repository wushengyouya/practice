// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../src/Faucet.sol";
import "../src/HackQuest.sol";

contract MyToken is ERC20 {
    constructor() ERC20("kumiko", "KMK") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract FaucetTest is Test {
    Faucet faucet;
    MyToken token;

    function setUp() public {
        token = new MyToken();
        faucet = new Faucet(token);
        token.mint(address(faucet), 2000);
    }

    function test_balance() public view {
        assertEq(2000, token.balanceOf(address(faucet)));
    }

    function test_requstToken() public {
        faucet.requestedToken();
        assertEq(100, token.balanceOf(address(this)));
        assertEq(token.balanceOf(address(faucet)), 1900);
    }

    receive() external payable {
        faucet.requestedToken();
    }
}
