// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

//分账合约
contract PaymentSplit {
    event PayeeAdded(address account, uint256 shares); //增加受益人
    event PaymentReleased(address to, uint256 amount); //受益人提款
    event PaymentRecived(address from, uint256 amount); //合约收款

    uint256 public totalShares; //总份额
    uint256 public totalReleased; //总支付

    mapping(address => uint256) public shares; //每个收益人的份额
    mapping(address => uint256) public released; //支付给每个受益人的金额
    address[] public payees; //受益人的数组

    //初始化受益人
    constructor(address[] memory _payees, uint256[] memory _shares) payable {
        //检查_payee和_share数组长度
        require(_payees.length == _shares.length, "paymentSplitter: payees and shares length mismatch");
        require(_payees.length > 0 && _shares.length > 0, "no payees");
        //添加受益人
        for (uint256 i = 0; i < _payees.length; i++) {
            payees.push(_payees[i]);
            shares[_payees[i]] = _shares[i];
            totalShares += _shares[i];
            emit PayeeAdded(_payees[i], _shares[i]);
        }
    }
    //收到eth释放事件

    receive() external payable virtual {
        emit PaymentRecived(msg.sender, msg.value);
    }

    //提取受益金额
    function release(address payable _account) public virtual {
        //受益人必须存在
        require(shares[_account] > 0, "account has no shares");
        //应得得eth不能为0
        uint256 payment = releasable(_account);
        require(payment != 0, "account is not due payment");
        //更新总支付，和支付给每个受益人的金额
        totalReleased += payment;
        released[_account] += payment;
        //转账
        (bool success,) = _account.call{value: payment}("");
        require(success, "transfer error");
        emit PaymentReleased(_account, payment);
    }
    //计算一个账户能够领取的eth

    function releasable(address _account) public view returns (uint256) {
        //计算分账合约总收入totalReceived
        uint256 totalReceived = address(this).balance + totalReleased; //合约余额+总支出
        return pendingPayment(_account, totalReceived, released[_account]);
    }

    function pendingPayment(address _account, uint256 _totalReceived, uint256 _alreadyReleased)
        public
        view
        returns (uint256)
    {
        //account应得的eth = 总应得eth - 已领到eth
        //总收入*占比-已领取eth, _totalReceived * shares[_account] / totalShares -  _alreadyReleased;
        return (_totalReceived * shares[_account]) / totalShares - _alreadyReleased;
    }

    //新增受益人
    function _addPayee(address _account, uint256 _accountShares) private {
        //检查accoun地址不能为0
        require(_account != address(0), "account is the zero address");
        //accountShares不能为0
        require(_accountShares > 0, "shares are 0");
        //_account不重复
        require(shares[_account] == 0, "account already has shares");
        //更新payees,shares,totalShares
        payees.push(_account);
        totalShares += _accountShares;
        emit PayeeAdded(_account, _accountShares);
    }
}
