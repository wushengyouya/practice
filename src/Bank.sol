//重入攻击复现演示
//解决方案
//1.检查-影响-交互模式
//2.重入锁
//3.拉取支付模式，将原先的“主动转账”分解为“转账者发起转账”加上“接受者主动拉取”。再引入一个合约

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;
contract Bank {
    mapping(address => uint256) public balanceOf;
    uint256 private status;
    //存钱
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
    }
    //重入锁
    modifier nonReentrant() {
        // 在第一次调用 nonReentrant 时，_status 将是 0
        require(status == 0, "ReentrancyGuard: reentrant call");
        // 在此之后对 nonReentrant 的任何调用都将失败
        status = 1;
        _;
        // 调用结束，将 _status 恢复为0
        status = 0;
    }
    //取钱
    function withdraw() public payable nonReentrant {
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "Insufficient balance");
        // 转账 ether !!! 可能激活恶意合约的fallback/receive函数，有重入风险！
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether");
        //检查影响交互模式
        balanceOf[msg.sender] = 0;
    }

    //查询银行余额
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
