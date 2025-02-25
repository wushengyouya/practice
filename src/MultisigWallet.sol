// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

contract MultisigWallet {
    event ExecutionSuccess(bytes32 txHash); //交易成功
    event ExcutionFailure(bytes32 txHash); //交易失败

    address[] public owners; //多签持有人数组
    mapping(address => bool) public isOwner; //记录体格地址是否为为多签持有人
    uint256 public ownerCount; //多签持有人数量
    uint256 public threshold; //多签执行门槛，交易至少有n个多钱人签名
    uint256 public nonce; //nonce，防止签名重放攻击

    constructor(address[] memory _owners, uint256 _threshold) {
        _setUpOwners(_owners, _threshold);
    }

    //初始化owners, isOwner, ownerCount,threshold
    function _setUpOwners(address[] memory _owners, uint256 _threshold) internal {
        //threshold没有被初始化过
        require(threshold == 0, "WTF5000");
        //多签执行门槛 小于 多签人数
        require(_threshold <= _owners.length, "WTF5001");
        //多签执行门槛至少为1
        require(_threshold >= 1, "WTF5002");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            //多签人不为0 的地址,本合约地址，不能重复
            require(owner != address(0) && owner != address(this) && !isOwner[owner], "WTF5003");
            owners.push(owner);
            isOwner[owner] = true;
        }
        ownerCount = _owners.length;
        threshold = _threshold;
    }

    //收集足够的多签签名后，执行交易
    function execTransaction(address to, uint256 value, bytes memory data, bytes memory signatures)
        public
        payable
        virtual
        returns (bool success)
    {
        //编码交易数据,计算哈希
        bytes32 txHash = encodeTransactionData(to, value, data, nonce, block.chainid);
        nonce++; //增加nonce
        checkSignatures(txHash, signatures); //检查签名
        //利用call执行交易，并获取交易结果
        (success,) = to.call{value: value}(data);
        require(success, "WTF5004");
        if (success) {
            emit ExecutionSuccess(txHash);
        } else {
            emit ExcutionFailure(txHash);
        }
    }

    /**
     * @dev 检查签名和交易数据是否对应。如果是无效签名，交易会revert
     * @param dataHash 交易数据哈希
     * @param signatures 几个多签签名打包在一起
     */
    function checkSignatures(bytes32 dataHash, bytes memory signatures) public view {
        // 读取多签执行门槛
        uint256 _threshold = threshold;
        require(_threshold > 0, "WTF5005");

        // 检查签名长度足够长
        require(signatures.length >= _threshold * 65, "WTF5006");

        // 通过一个循环，检查收集的签名是否有效
        // 大概思路：
        // 1. 用ecdsa先验证签名是否有效
        // 2. 利用 currentOwner > lastOwner 确定签名来自不同多签（多签地址递增）
        // 3. 利用 isOwner[currentOwner] 确定签名者为多签持有人
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < _threshold; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            // 利用ecrecover检查签名是否有效
            currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v, r, s);
            require(currentOwner > lastOwner && isOwner[currentOwner], "WTF5007");
            lastOwner = currentOwner;
        }
    }
    //将单个签名从打包的签名分离出来

    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        // 签名的格式：{bytes32 r}{bytes32 s}{uint8 v}
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }

    //编码交易数据
    function encodeTransactionData(address to, uint256 value, bytes memory data, uint256 _nonce, uint256 chanid)
        public
        pure
        returns (bytes32)
    {
        bytes32 txHash = keccak256(abi.encode(to, value, keccak256(data), _nonce, chanid));
        return txHash;
    }
}
