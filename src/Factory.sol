// SPDX-License-Identifier: GPL-2.0-or-later
//SPX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../src/Exchange.sol";

//uniswap工厂合约
contract Factory {
    mapping(address => address) public tokenToExchange;

    //创建兑换合约
    function createExchange(address _tokenAddress) public returns (address) {
        require(_tokenAddress != address(0), "invalid token address");
        //一个token只能存在一个 exchange
        require(
            tokenToExchange[_tokenAddress] == address(0),
            "exchange already exists"
        );

        Exchange exchange = new Exchange(_tokenAddress);
        tokenToExchange[_tokenAddress] = address(exchange);

        return address(exchange);
    }

    function getExchange(address _tokenAddress) public view returns (address) {
        return tokenToExchange[_tokenAddress];
    }
}
