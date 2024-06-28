// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
//引入ERC721,ERC20
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./IRewardToken.sol";



//创建StakeSystem合约,定义NFT合约地址，ERC20地址,通过构造函数初始化
contract StakeSystem is IERC721Receiver {
    IERC721 public stakedNFT;
    IRewardToken public rewardsToken;
    uint256 private STAKE_TIME = 10; //默认质押周期时间10s

    event StakedSuccess(address indexed owner, uint256 indexed tokenId);
    event Log(address addr);
    struct Staker {
        uint256[] ids; //所有tokenId
        mapping(uint256 => uint256) lockPeriod; //质押锁定时间
        uint256 pendingRewards; //奖励
        uint256 totalRewardsClaimed; //已领取奖励
    }
    //当以质押结构体，地址质押的所有NFT，所有NFT指向的所有者地址
    mapping(address => Staker) public stakers; //所有质押账户
    mapping(uint256 => address) tokenOwners; //质押NFT的owners

    constructor(IERC721 _stakedNFT, IRewardToken _rewardsToken) {
        stakedNFT = _stakedNFT;
        rewardsToken = _rewardsToken;
    }

    //编写质押功能
    function stake(uint256 _tokenId) public {
        //确认nft所有权
        require(stakedNFT.ownerOf(_tokenId) == msg.sender, "not tokenId owner");
        Staker storage staker = stakers[msg.sender];
        staker.ids.push(_tokenId);
        staker.lockPeriod[_tokenId] = block.timestamp; //添加质押时间
        tokenOwners[_tokenId] = msg.sender;//存储所有者
        //将nft，授权并转入合约种
        emit Log(msg.sender);
        stakedNFT.approve(address(this), _tokenId);
        stakedNFT.safeTransferFrom(msg.sender, address(this), _tokenId);
        emit StakedSuccess(msg.sender, _tokenId);
    }

    //编写计算计算质押奖励
    function calculateStakeReward(address _user) public {
        Staker storage staker = stakers[_user];
        uint256[] storage ids = staker.ids;
        //确定有质押nft
        for (uint256 i = 0; i < staker.ids.length; i++) {
            if(staker.lockPeriod[ids[i]] > 0 && block.timestamp > staker.lockPeriod[ids[i]] + STAKE_TIME){
                uint256 rewardPeriod = (block.timestamp - staker.lockPeriod[ids[i]]) / STAKE_TIME;
                staker.pendingRewards += rewardPeriod * 10e18;
                uint256 lockTime = (block.timestamp - staker.lockPeriod[ids[i]]) * STAKE_TIME;
                //存在疑问，为什么设置 当前区块时间+剩余的质押时间 ??
                staker.lockPeriod[ids[i]] = block.timestamp + lockTime;
            }
        }
        
    }

    //领取奖励代币
    function claimAllRewards() public{
        //计算质押奖励
        calculateStakeReward(msg.sender);
        uint256 rewardAmount = stakers[msg.sender].pendingRewards;
        require(rewardAmount > 0);
        //将待领取金额设置为0
        stakers[msg.sender].pendingRewards = 0;
        rewardsToken.mint(msg.sender, rewardAmount);
        stakers[msg.sender].totalRewardsClaimed += rewardAmount;
    }
    //撤销质押
    function unStake(uint256 _tokenId) public{
        require(tokenOwners[_tokenId] == msg.sender,"user must be the owner of the staked nft");
        // 判断是否还有质押奖励没
        calculateStakeReward(msg.sender);
        Staker storage staker = stakers[msg.sender];

        //有待领取的质押奖励不能撤销质押
        require(staker.pendingRewards <= 0,"pendingReward > 0");
        staker.lockPeriod[_tokenId] = 0;
        if(staker.ids.length > 0){
            for(uint256 i =0;i<staker.ids.length;i++){
                if(_tokenId == staker.ids[i]){
                    //有大于两个质押的nft，将最后与要撤销质押的nft交换位置
                    if(staker.ids.length > 1){
                        staker.ids[i] = staker.ids[staker.ids.length - 1];
                        staker.ids.pop();
                    }
                    //将nft退回
                    stakedNFT.transferFrom(address(this), msg.sender, _tokenId);
                    delete staker.ids[i];
                    delete tokenOwners[_tokenId];
                }
            }
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4){
        // 处理接收到的NFT 
        return this.onERC721Received.selector;
    }
    
}


