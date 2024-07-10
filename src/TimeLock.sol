// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;
//时间锁合约
/**
时间锁主要有三个功能：
创建交易，并加入到时间锁队列。
在交易的锁定期满后，执行交易。
后悔了，取消时间锁队列中的某些交易。
项目方一般会把时间锁合约设为重要合约的管理员，例如金库合约，再通过时间锁操作他们。
时间锁合约的管理员一般为项目的多签钱包，保证去中心化。
 * 
 */

contract TimeLock {
    //交易取消
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint256 executeTime
    );
    //交易执行
    event ExcuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint256 executeTime
    );
    //交易创建并进入队列
    event QueueTransactin(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint256 executeTime
    );
    //修改管理员
    event NewAdmin(address indexed newAdmin);

    address public admin; //管理员地址
    uint public constant GRACE_PERIOD = 7 days; //交易有效期
    uint public delay; //交易锁定时间
    mapping(bytes32 => bool) public queuedTransactions; //所有在时间锁队列中的交易

    modifier onlyOwner() {
        require(msg.sender == admin, "TimeLock:caller not admin");
        _;
    }
    modifier onlyTimelock() {
        require(msg.sender == address(this), "Timelock:caller not timelock");
        _;
    }
    //初始化管理员地址，交易锁定时间
    constructor(uint _delay) {
        delay = _delay;
        admin = msg.sender;
    }

    //修改管理员地址，修改者必须为时间锁合约
    function changeAdmin(address newAdmin) public onlyTimelock {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }

    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executeTime
    ) public onlyOwner returns (bytes32) {
        //交易执行时间满足锁定时间
        require(
            executeTime > getBlockTimestamp() + delay,
            "TimeLock:queueTrasaction:estimated execute block must satify delay"
        );
        //计算交易的唯一标识符txHash
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        //将交易添加到队列
        queuedTransactions[txHash] = true;

        emit QueueTransactin(
            txHash,
            target,
            value,
            signature,
            data,
            executeTime
        );
        return txHash;
    }

    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executeTime
    ) public onlyOwner {
        //计算交易hash
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        //检查是否在队列中
        require(
            queuedTransactions[txHash],
            "Timelock:cancelTransaction:transaction hasn't been queued"
        );
        //将交易移出队列
        queuedTransactions[txHash] = false;
        emit CancelTransaction(
            txHash,
            target,
            value,
            signature,
            data,
            executeTime
        );
    }

    //执行交易
    //* 要求：
    // * 1. 交易在时间锁队列中
    //* 2. 达到交易的执行时间
    //* 3. 交易没过期
    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executeTime
    ) public payable onlyOwner returns (bytes memory) {
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        require(
            queuedTransactions[txHash],
            "Timelock:cancelTransaction:transaction hasn't been queued"
        );
        require(
            getBlockTimestamp() >= executeTime,
            "Timelock::executeTransaction: Transaction hasn't surpassed time lock."
        );
        require(
            getBlockTimestamp() <= executeTime + GRACE_PERIOD,
            "Timelock::executeTransaction: Transaction is stale."
        );

        //将交易移出队列
        queuedTransactions[txHash] = false;

        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature))),
                data
            );
        }

        (bool success, bytes memory returnData) = target.call{value: value}(
            callData
        );
        require(
            success,
            "Timelock:executeTransaction:transaction execution reverted"
        );

        emit ExcuteTransaction(
            txHash,
            target,
            value,
            signature,
            data,
            executeTime
        );
        return returnData;
    }

    function getBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function getTxHash(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executeTime
    ) public pure returns (bytes32) {
        return
            keccak256(abi.encode(target, value, signature, data, executeTime));
    }
}
