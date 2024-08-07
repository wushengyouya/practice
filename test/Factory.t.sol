// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;
import {Exchange} from "../src/Exchange.sol";
import {Token} from "../src/Token.sol";
import {MyToken} from "../src/MyToken.sol";
import {Factory} from "../src/Factory.sol";
import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract FactoryTest is Test {
    Factory factory;
    Token token;
    MyToken myToken;
    address exchangeToken;

    modifier onlyUser() {
        vm.startPrank(address(1));
        _;
        vm.stopPrank();
    }

    function setUp() public {
        factory = new Factory();
        vm.startPrank(address(1));
        token = new Token("kumiko", "KMK", toWei(1000));
        vm.deal(address(1), toWei(1000));
        myToken = new MyToken();
        exchangeToken = factory.createExchange(address(token));
        token.approve(exchangeToken, toWei(200));
        Exchange(exchangeToken).addLiquidity{value: toWei(100)}(toWei(200));
        vm.stopPrank();
    }

    function test_addLiquidity() public onlyUser {
        assertEq(IERC20(exchangeToken).balanceOf(address(1)), toWei(100));
    }

    function test_getTokenAmount() public {
        vm.deal(address(2), 500);
        Exchange exchange = Exchange(exchangeToken);
        uint256 amount_1 = exchange.getTokenAmount(toWei(1)) / 1e15;
        uint256 amount_100 = exchange.getTokenAmount(toWei(100)) / 1e15;
        uint256 amount_1000 = exchange.getTokenAmount(toWei(1000)) / 1e15;
        console.log(amount_1, amount_100, amount_1000);
    }

    function toWei(uint256 amount) public pure returns (uint256) {
        return amount * 1e18;
    }
}
