// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
//荷兰拍卖，随时间拍卖价格递减

contract DutchAuction is Ownable, ERC721 {
    uint256 totalSupply = 5000;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) Ownable(msg.sender) {}

    uint256 public constant COLLECTOIN_SIZE = 10000; //NFT总数
    uint256 public constant AUCTION_START_PRICE = 1 ether; //起拍价
    uint256 public constant AUCTION_END_PRICE = 0.1 ether; //结束价
    uint256 public constant AUCTION_TIME = 10 minutes; //拍卖时间
    uint256 public constant AUCTION_DROP_INTERVAL = 1 minutes; //每过多久时间，价格衰减一次
    uint256 public constant AUCTION_DROP_PER_STEP =
        (AUCTION_START_PRICE - AUCTION_END_PRICE) / (AUCTION_TIME / AUCTION_DROP_INTERVAL); //每次价格衰减步长
    uint256 public auctionStartTime; //拍卖开始时间戳
    string private _baseTokenURI; //metadata uri
    uint256[] private _allTokens; //记录所有tokenid

    // auctionStartTime setter函数，onlyOwner
    function auctionStartTimeSetter(uint256 startTime) public onlyOwner {
        auctionStartTime = startTime;
    }
    // 获取拍卖实时价格

    function getAuctionPrice() public view returns (uint256 currentPrice) {
        //当前时间小于开始时间
        if (block.timestamp < auctionStartTime) {
            currentPrice = AUCTION_START_PRICE;
        } else if (block.timestamp > auctionStartTime + 10 minutes) {
            //当前时间大于结束时间
            currentPrice = AUCTION_END_PRICE;
        } else {
            //当前时间位于拍卖中间
            uint256 per = (block.timestamp - auctionStartTime) / AUCTION_DROP_INTERVAL;
            currentPrice = AUCTION_START_PRICE - (per * AUCTION_DROP_PER_STEP);
        }
    }
    // 拍卖mint函数

    function auctionMint(uint256 quantity) external payable {
        uint256 autionTime = auctionStartTime;
        // 检查是否设置起拍时间，拍卖是否开始
        require(autionTime != 0 && block.timestamp > autionTime, "sale not start");
        //检查是否超出了总供应量
        require(
            totalSupply + quantity < COLLECTOIN_SIZE,
            "not enough remaining reserved for auction to support desired mint amount"
        );
        //计算价格成本
        uint256 totalCost = getAuctionPrice() * quantity;
        //判断用户是否发送了足够多的主币
        require(msg.value >= totalCost, "need to send more ETH");
        //mint nft
        for (uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply;
            _mint(msg.sender, mintIndex);
            totalSupply++;
        }
        //多余的主币退还
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost); //注意重入风险
        }
    }
    // 提款函数，onlyOwner

    function withdrawMoney() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "transfer fail");
    }
}
