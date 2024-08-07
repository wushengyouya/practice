// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;
/*
开发者在部署合约时规定锁仓的时间，受益人地址，以及代币合约。
开发者将代币转入TokenLocker合约。
在锁仓期满，受益人可以取走合约里的代币。
*/

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TokenLocker {
    event TokenLockerStart(address indexed beneficiary, address indexed token, uint256 startTime, uint256 lockTime);
    event Release(address indexed beneficiary, address indexed token, uint256 releaseTime, uint256 amount);

    uint256 startTime; //开始锁定时间
    uint256 lockDuration; //锁定期限
    address beneficiary; //受益人
    address token; //代币

    //初始化
    constructor(uint256 _lockDuration, address _beneficiary, address _token) {
        //锁定时间大于0
        require(_lockDuration > 0, "TokenLocker:lock time should greater than 0");
        startTime = block.timestamp;
        beneficiary = _beneficiary;
        lockDuration = _lockDuration;
        token = _token;

        emit TokenLockerStart(beneficiary, token, startTime, lockDuration);
    }

    //提取币
    function release() public {
        //msg.sender必须为受益人
        require(msg.sender == beneficiary, "TokenLock:current user is not beneficiary");
        //不在锁定期内
        require(block.timestamp >= startTime + lockDuration, "TokenLock:current time is before release time");
        uint256 amount = IERC20(token).balanceOf(address(this));
        require(amount > 0, "TokenLock:not tokens to release");
        IERC20(token).transfer(beneficiary, amount);
        emit Release(beneficiary, token, block.timestamp, amount);
    }
}
