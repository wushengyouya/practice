// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IERC4626 is IERC20, IERC20Metadata {
    //存款时触发
    event Deposit(
        address indexed sender,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
    //取款时触发
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    //存款-取款逻辑
    //返回金库的基础资产代币地址
    //必须时ERC20代币合约地址
    //不能revert()
    function asset() external returns (address assetTokenAddress);

    //存款函数-用户向金库存入assets 单位的基础资产，然后合约铸造shares单位的金库
    //额度给receiver地址
    //释放Deposit事件，如果资产不能存入必须revert，比如存款数据大于上限
    function deposit(
        uint256 assets,
        address receiver
    ) external returns (uint256 shares);

    //铸造函数，用户需要存入assets单位的基础资产，然后给receiver地址铸造shares数量的金库额度
    //释放Deposit事件，如果金库额度不能铸造必须revert,比如铸造数额大于上限等
    function mint(
        uint256 shares,
        address receiver
    ) external returns (uint256 assets);

    //提款函数，owner地址销毁shares单位的金库额度，然后合约件assets单数的基础资产发送给receiver地址
    //释放Withdraw事件，如果全部基础资产不能提取，将revert
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    //赎回函数:owner地址销毁shares数量的金库额度，然后合约将assets单位的基础资产发给receiver地址
    //释放Withdraw事件
    //如果金库额度不能全部销毁
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    //会计逻辑

    //返回金库中管理的基础资产代币总额
    function totalAssets() external view returns (uint256 totalManagedAssets);
    //返回利用一定数额基础资产可以换取的金库额度
    function convertToShares(
        uint256 assets
    ) external view returns (uint256 shares);

    //利用一定数额金库额度可以换取的基础资产
    function convertToAssets(
        uint256 shares
    ) external view returns (uint256 assets);

    //存款一定数额的基础资产能够获得的金库额度
    function previewDeposit(
        uint256 assets
    ) external view returns (uint256 shares);

    //模拟铸造shares数额的金库额度需要存款的基础资产数量
    function previewMint(uint256 shares) external view returns (uint256 assets);

    //提款assets数额的基础资产需要赎回的金库份额
    function previewWithdraw(
        uint256 assets
    ) external view returns (uint256 shares);

    //销毁shares数额的金库额度能够赎回的基础资产数量
    function previewRedeem(
        uint256 shares
    ) external view returns (uint256 assets);

    //存款/提款限额逻辑

    //单词可存的最大基础资产
    function maxDeposit(
        address receiver
    ) external view returns (uint256 maxAssets);

    //单次铸造的最大金库额度
    function maxMint(
        address receiver
    ) external view returns (uint256 maxShares);

    //返回某个用户地址单词取款可以提取的最大基础资产额度
    function maxWithdraw(
        address owner
    ) external view returns (uint256 maxAssets);

    //返回某个用个用户地址单词赎回可以销毁的最大金库额度
    function maxRedeem(address owner) external view returns (uint256 maxShares);
}
