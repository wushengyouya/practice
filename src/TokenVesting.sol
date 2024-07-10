// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
//线性释放合约
contract TokenVesting {
    event ERC20Released(address indexed token, uint256 amount); // 提币事件

    mapping(address => uint256) public erc20Released; //记录已经释放的代币
    address public immutable beneficiary; //受益人
    uint256 public immutable start; //开始时间
    uint256 public immutable duration; //归属期

    //初始化受益人地址，释放周期，起始时间戳
    constructor(address _beneficiary, uint256 _duration) {
        require(
            _beneficiary != address(0),
            "VestingWallet:beneficary is zero address"
        );
        beneficiary = _beneficiary;
        start = block.timestamp;
        duration = _duration;
    }

    function release(address token) public {
        // 调用vestedAmount()函数计算可提取的代币数量
        uint256 releasable = vestedAmount(token, block.timestamp) -
            erc20Released[beneficiary];
        require(releasable != 0, "releasable token is zero");
        // 更新已释放代币数量
        erc20Released[beneficiary] += releasable;
        // 转代币给受益人
        IERC20(token).transfer(beneficiary, releasable);
        emit ERC20Released(token, releasable);
    }
    /**
     * @dev 根据线性释放公式，计算已经释放的数量。开发者可以通过修改这个函数，自定义释放方式。
     * @param token: 代币地址
     * @param timestamp: 查询的时间戳
     */
    function vestedAmount(
        address token,
        uint256 timestamp
    ) public view returns (uint256) {
        // 合约里总共收到了多少代币（当前余额 + 已经提取）
        uint256 totalAllocation = IERC20(token).balanceOf(address(this)) +
            erc20Released[beneficiary];
        // 根据线性释放公式，计算已经释放的数量
        if (timestamp < start) {
            return 0;
        } else if (timestamp > start + duration) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start)) / duration;
        }
    }
}
