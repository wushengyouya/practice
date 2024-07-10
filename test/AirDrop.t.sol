// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
import {Test, console} from "forge-std/Test.sol";
import "../src/MyToken.sol";
import "../src/AirDrop.sol";
contract AirDropTest is Test {
    AirDrop airDrop;
    MyToken token;
    function setUp() public {
        airDrop = new AirDrop();
        token = new MyToken();
    }

    function test_multiTransferETH() public {
        address payable[] memory addrs = new address payable[](3);
        addrs[0] = payable(address(1));
        addrs[1] = payable(address(2));
        addrs[2] = payable(address(3));
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;
        airDrop.multiTransferETH{value: 600}(addrs, amounts);
        assertEq(addrs[0].balance, 100);
    }
    function test_multiTransferToken() public {
        address[] memory addrs = new address[](3);
        addrs[0] = address(1);
        addrs[1] = address(2);
        addrs[2] = address(3);
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;
        token.mint(address(this), 600);
        token.approve(address(airDrop), 600);
        airDrop.multiTransferToken(address(token), addrs, amounts);
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(addrs[0]), 100);
        assertEq(token.balanceOf(addrs[1]), 200);
        assertEq(token.balanceOf(addrs[2]), 300);
    }
}
