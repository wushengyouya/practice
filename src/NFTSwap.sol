// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {console} from "forge-std/Test.sol";
/** 
卖家：出售NFT的一方，可以挂单list、撤单revoke、修改价格update。
买家：购买NFT的一方，可以购买purchase。
订单：卖家发布的NFT链上订单，一个系列的同一tokenId最多存在一个订单，
其中包含挂单价格price和持有人owner信息。当一个订单交易完成或被撤单后，其中信息清零。
 * 
*/
contract NFTSwap is IERC721Receiver {
    event List(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 price
    );
    event Purchase(
        address indexed buyer,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 price
    );
    event Revoke(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId
    );
    event Update(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 newPrice
    );

    //nft订单结构体
    struct Order {
        address owner;
        uint256 price;
    }
    mapping(address => mapping(uint256 => Order)) public nftList;

    modifier CheckNftAddr(address nftAddr) {
        require(nftAddr != address(0), "the nftaddress is zero address");
        _;
    }
    //发布nft交易订单
    function list(
        address nftAddr,
        uint256 tokenId,
        uint256 price
    ) public CheckNftAddr(nftAddr) {
        IERC721 nft = IERC721(nftAddr);
        require(tokenId != 0, "tokenid is zero");
        require(nft.ownerOf(tokenId) == msg.sender, "not the nft owner");
        //nft授权给合约
        require(nft.getApproved(tokenId) == address(this), "not approve");
        require(price > 0, "price < 0");
        //将nft转给合约
        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        nftList[nftAddr][tokenId] = Order(msg.sender, price);
        emit List(msg.sender, nftAddr, tokenId, price);
    }

    //购买
    function purchase(
        address nftAddr,
        uint256 tokenId
    ) public payable CheckNftAddr(nftAddr) {
        console.log("start purchase");
        IERC721 nft = IERC721(nftAddr);
        Order storage order = nftList[nftAddr][tokenId];
        require(order.price > 0, "nft price < 0");
        require(msg.value >= order.price, "ETH not enough");
        require(nft.ownerOf(tokenId) == address(this), "the nft not exists");
        //将nft转入购买者账户
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
        //将主币转给卖家
        console.log("transfer to seller", msg.value, order.price);
        (bool success, ) = payable(order.owner).call{value: order.price}("");
        require(success, "transfer eth to seller error");
        //将多余的主币退回
        payable(msg.sender).transfer(msg.value - order.price);
        //清除订单
        delete nftList[nftAddr][tokenId];
        //释放购买事件
        emit Purchase(msg.sender, nftAddr, tokenId, order.price);
    }

    //撤回nft订单
    function revoke(
        address nftAddr,
        uint256 tokenId
    ) public CheckNftAddr(nftAddr) {
        IERC721 nft = IERC721(nftAddr);
        Order memory order = nftList[nftAddr][tokenId];

        //当前要取消订单的nft在当前合约种存在
        require(nft.ownerOf(tokenId) == address(this), "nft not exists");
        //nft的seller == msg.sender
        require(msg.sender == order.owner, "not nft owner");
        //退回nft
        nft.safeTransferFrom(address(this), order.owner, tokenId);
        emit Revoke(order.owner, nftAddr, tokenId);
    }
    function update(
        address nftAddr,
        uint256 tokenId,
        uint256 newPrice
    ) public CheckNftAddr(nftAddr) {
        //价格必须大于0
        require(newPrice > 0, "price <0");
        Order storage order = nftList[nftAddr][tokenId];
        //调用为当前nft的owner
        require(msg.sender == order.owner, "not nft owner");
        IERC721 nft = IERC721(nftAddr);
        require(nft.ownerOf(tokenId) == address(this), "nft not exsits");
        order.price = newPrice;
        emit Update(msg.sender, nftAddr, tokenId, newPrice);
    }
    // 实现{IERC721Receiver}的onERC721Received，能够接收ERC721代币
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
