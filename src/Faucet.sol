// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
//代币水龙头

contract Faucet {
    //定义每次能领多少
    uint256 private allowdToken = 100;
    //存储每个人领取的状态，限制每个人只能领取一次
    mapping(address => bool) private requestedAddress;
    //代币合约地址
    IERC20 token;

    event SendToken(address indexed from, address indexed to, uint256 amount);

    constructor(IERC20 _token) {
        token = _token;
    }

    function requestedToken() public {
        //不能是零地址
        require(msg.sender != address(0), "address is zero addr");
        //已经领取过的不能继续再领
        require(!requestedAddress[msg.sender], "this address requested");
        //必须已授权
        require(token.approve(msg.sender, allowdToken), "not approve");

        token.transfer(msg.sender, allowdToken);
        //记录已领取的地址
        requestedAddress[msg.sender] = true;
        emit SendToken(address(this), msg.sender, allowdToken);
    }
}
