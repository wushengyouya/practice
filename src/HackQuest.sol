// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./IRewardToken.sol";

contract HackQuest is IRewardToken, ERC20 {
    address private owner;
    address private minterRole;

    event Owner(address owner);

    constructor() ERC20("HackQuest", "HQ") {
        owner = msg.sender;
        emit Owner(owner);
    }

    //设置铸造角色
    function setMintRole(address role) public {
        //只有owner可以设置
        require(msg.sender == owner, "not owner");
        minterRole = role;
    }

    //只有minterRole能铸造
    function mint(address recipient, uint256 amount) external {
        require(msg.sender == minterRole, "not mintRole");
        _mint(recipient, amount);
    }
}
