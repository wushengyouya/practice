// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
//空投合约

contract AirDrop {
    //领取失败的地址
    mapping(address => uint256) failTransferList;

    event Log(string log);
    //数组求和函数

    function getSum(uint256[] calldata _arr) public pure returns (uint256 sum) {
        for (uint256 i = 0; i < _arr.length; i++) {
            sum += _arr[i];
        }
    }

    receive() external payable {
        emit Log("this is receive");
    }

    fallback() external payable {
        emit Log("this is fallback");
    }
    //代币空投

    function multiTransferToken(address _token, address[] calldata _addresses, uint256[] calldata _amounts) external {
        require(_addresses.length == _amounts.length, "Lengths of address and amounts not equal");
        IERC20 token = IERC20(_token);
        uint256 _amountSum = getSum(_amounts); // 计算空投代币总量
        require(token.allowance(msg.sender, address(this)) >= _amountSum, "need approve erc20 token");
        //执行转账
        for (uint8 i; i < _addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], _amounts[i]);
        }
    }

    //主币空投
    function multiTransferETH(address payable[] calldata _addresses, uint256[] calldata _amounts) external payable {
        require(_addresses.length == _amounts.length, "Lengths of address and amounts not equal");
        uint256 _amountSum = getSum(_amounts); // 计算空投代币总量
        //当前合约主币的数量必须大于等于要空投的数量 address(this).balance
        require(msg.value == _amountSum, "eth not enough");
        for (uint256 i = 0; i < _addresses.length; i++) {
            (bool success,) = _addresses[i].call{value: _amounts[i]}("");
            if (!success) {
                failTransferList[_addresses[i]] = _amounts[i];
            }
        }
    }
}
