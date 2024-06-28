// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
//定义接口IRewardToken 继承ERC20，定义mint方法
interface IRewardToken is IERC20 {
    function mint(address recipient, uint256 amount) external;
}