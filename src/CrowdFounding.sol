// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IRewardToken.sol";
import {console} from "forge-std/Test.sol";
//众筹合约
contract CrowdFounding {
    //众筹token
    IRewardToken private token;
    //众筹交易id
    uint256 private countId = 1;

    event Launch(
        address indexed owner,
        uint256 startTime,
        uint256 endTime,
        uint256 goal
    );
    event CancelCrowdFounding(uint256 indexed id, address indexed owner);
    event Log(string str);
    event CrowdFoundingEvevt(address indexed owner, uint256 id, uint256 amount);
    event EndCrowdFounding(
        uint256 indexed id,
        address indexed from,
        address indexed to,
        uint256 amount
    );
    constructor(address _token) {
        token = IRewardToken(_token);
    }

    //所有众筹
    // mapping(address => Transaction) public ;
    mapping(uint256 => Transaction) public crowds;
    mapping(uint256 => address) public ownerCrowds; //所有权
    mapping(uint256 => mapping(address => uint256)) userAmounts; //众筹项目下，每个用户众筹的金额
    mapping(uint256 => address[]) usersCrowdFounding; //某个项目参与众筹的人员
    struct Transaction {
        uint256 id;
        uint256 goal; //目标金额
        uint256 startTime;
        uint256 endTime;
        uint256 raiseAmount; //已筹到金额
        bool end; //是否结束
    }

    //发起众筹
    function launch(
        uint256 amount,
        uint256 endTime
    ) public returns (uint256 currentId) {
        //金额必须大于0
        require(amount > 0, "goal amount < 0");
        //结束时间必须大于开始时间
        require(endTime > block.timestamp, "endTime < startTime");
        require(
            msg.sender != address(0),
            "current address is the zero address"
        );
        Transaction memory transaction = Transaction(
            countId,
            amount,
            block.timestamp,
            endTime,
            0,
            false
        );
        currentId = countId;
        crowds[currentId] = transaction;
        ownerCrowds[currentId] = msg.sender;
        countId++;
        emit Launch(msg.sender, block.timestamp, endTime, amount);
    }
    //众筹
    function crowdFounding(uint256 id, uint256 amount) public {
        //当前需要众筹的项目存在
        require(ownerCrowds[id] != address(0), "the crowdfounding not exists");
        //众筹金额必须大于等于账户余额
        require(
            token.balanceOf(msg.sender) >= amount,
            "crowdfounding amount > balanceOf amount"
        );
        require(msg.sender != address(0), "zero address");
        Transaction storage transaction = crowds[id];
        console.log(msg.sender);
        //token.approve(address(this), amount);
        // token.transfer(address(this), amount);
        token.transferFrom(msg.sender, address(this), amount);

        //用户第一次参与该项目的众筹，保存他的地址
        uint256 userRaiseAmount = userAmounts[id][msg.sender];
        if (userRaiseAmount == 0) {
            if (usersCrowdFounding[id].length == 0) {
                usersCrowdFounding[id].push(msg.sender);
            } else {
                //当前地址不存在，则添加
                for (uint256 i = 0; i < usersCrowdFounding[id].length; i++) {
                    if (usersCrowdFounding[id][i] != msg.sender) {
                        usersCrowdFounding[id].push(msg.sender);
                    }
                }
            }
        }
        userAmounts[id][msg.sender] += amount; //该项目下用户累计众筹金额
        transaction.raiseAmount += amount;

        emit CrowdFoundingEvevt(msg.sender, id, amount);
    }

    function getCrowdFounding(
        uint256 id
    )
        public
        view
        returns (uint256 crowdId, uint256 raiseAmount, address owner)
    {
        Transaction memory t = crowds[id];
        owner = ownerCrowds[id];
        return (t.id, t.raiseAmount, owner);
    }
    //项目发起方,撤销众筹
    function cancelCrowdFounding(uint256 id) public {
        Transaction storage transaction = crowds[id];
        require(!transaction.end, "is end");
        require(msg.sender == ownerCrowds[id], "not exists");
        address[] memory usersAddr = usersCrowdFounding[id];
        transaction.end = true; //设置该项目已结束

        //退还众筹金额
        console.log(usersAddr.length);
        for (uint256 i = 0; i < usersAddr.length; i++) {
            uint256 amount = userAmounts[id][usersAddr[i]]; //读取用户总金额
            userAmounts[id][usersAddr[i]] = 0; //设置为0
            transaction.raiseAmount -= amount; //减去该用户的众筹金额
            //payable(usersAddr[i]).transfer(amount);第一版问题代码，此代码转的是ETH主币，而这里是代币
            console.log(usersAddr[i], amount);
            token.transfer(usersAddr[i], amount);
            delete userAmounts[id][usersAddr[i]]; //清空金额
        }
        delete usersCrowdFounding[id]; //清空众筹地址
        emit CancelCrowdFounding(id, msg.sender);
    }

    //查询自己的众筹金额
    function getUserRaiseAmount(uint256 id) public view returns (uint256) {
        return userAmounts[id][msg.sender];
    }
    //结束众筹
    function endCrowdFounding(uint256 id) public {
        Transaction storage transaction = crowds[id];
        require(!transaction.end, "the crowdfounding is ended");
        require(
            block.timestamp > transaction.endTime,
            "current time < end time"
        );
        require(msg.sender == ownerCrowds[id], "not owner");
        console.log(transaction.raiseAmount, transaction.goal, transaction.end);
        require(
            transaction.raiseAmount >= transaction.goal,
            "not enough goal amount"
        );
        uint256 totalAmount = transaction.raiseAmount;
        transaction.raiseAmount = 0;
        token.transfer(msg.sender, totalAmount);
        transaction.end = true;

        emit EndCrowdFounding(id, address(this), msg.sender, totalAmount);
    }
}
