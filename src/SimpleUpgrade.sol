// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
//简单的可升级合约，管理可以同通过升级函数更改逻辑合约地址，从而改变合约的逻辑

contract SimpleUpgrade {
    address public implementtation; //逻辑合约的地址
    address public admin; //admin address
    string public words; //字符串，可以通过逻辑合约的函数改变

    //初始化逻辑合约与admin
    constructor(address _implementtation) {
        implementtation = _implementtation;
        admin = msg.sender;
    }

    //fallback函数，将调用委托给逻辑合约
    fallback() external payable {
        //透明代理,增加权限判断,调用者不能为管理员
        require(msg.sender != admin);
        (bool success, bytes memory data) = implementtation.delegatecall(msg.data);
    }
    //第一种方案，透明带来。升级合约函数放在代理合约中。费gas

    function upgrade(address newImplementtation) public {
        require(msg.sender == admin, "not admin");
        implementtation = newImplementtation;
    }
}

contract Logic1 {
    address public implementtation; //逻辑合约的地址
    address public admin; //admin address
    string public words; //字符串，可以通过逻辑合约的函数改变

    constructor() {
        admin = msg.sender;
    }

    function foo() public {
        words = "old";
    }
    //第二种方案通用可升级代理，升级函数放在逻辑合约中，避免“选择器冲突”。节约gas，更复杂

    function upgrade2(address _implementtation) public {
        console.log(msg.sender, admin);

        require(msg.sender == admin, "not admin");
        implementtation = _implementtation;
    }
}

contract Logic2 {
    address public implementtation; //逻辑合约的地址
    address public admin; //admin address
    string public words; //字符串，可以通过逻辑合约的函数改变

    constructor() {
        admin = msg.sender;
    }

    function foo() public {
        words = "new";
    }

    //通用可升级代理，升级函数放在逻辑合约中，避免“选择器冲突”
    function upgrade2(address _implementtation) public {
        console.log(msg.sender, admin);
        require(msg.sender == admin, "not admin");

        implementtation = _implementtation;
    }
}
