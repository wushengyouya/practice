// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

//继承ERC721合约
contract HQKitty is ERC721 {
    uint256 public _tokenIdCounter = 1;
    //构造函数初始化ERC721

    constructor() ERC721("HQKitty", "HQK") {}

    function safeMint(address to) public {
        _safeMint(to, _tokenIdCounter);
        _tokenIdCounter++;
    }
}
