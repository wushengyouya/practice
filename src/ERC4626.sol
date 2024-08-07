// SPDX-License-Identifier: SEE LICENSE IN LICENSE
/*
金库合约是 DeFi 乐高中的基础，它允许你把基础资产（代币）质押到合约中，换取一定收益，包括以下应用场景:
收益农场: 在 Yearn Finance 中，你可以质押 USDT 获取利息。
借贷: 在 AAVE 中，你可以出借 ETH 获取存款利息和贷款。
质押: 在 Lido 中，你可以质押 ETH 参与 ETH 2.0 质押，得到可以生息的 stETH。
*/
pragma solidity ^0.8.22;

import "./IERC4626.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract ERC4626 is ERC20, IERC4626 {
    ERC20 private immutable _asset;
    uint8 private immutable _decimals;

    constructor(ERC20 asset_, string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _asset = asset_;
        _decimals = asset_.decimals();
    }

    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    function decimals() public view virtual override(IERC20Metadata, ERC20) returns (uint8) {
        return _decimals;
    }

    //存款/提款逻辑

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        //利用previewDeposit()计算将获得的金库份额
        shares = previewDeposit(assets);

        //先tansfer后Mint,防止重入
        _asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        //释放Deposit事件
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    //铸造
    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        //利用previewMint() 计算需要存款的基础资产数额
        assets = previewMint(shares);

        //先transer后Mint，防止重入
        _asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares) {
        //利用previewWithdraw 计算将销毁的金库金额
        shares = previewWithdraw(assets);
        //如果不是owner,则检查并更新授权
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }
        //先销毁后transfer() ,防止重入
        _burn(owner, shares);
        _asset.transfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function redeem(uint256 shares, address receiver, address owner) public virtual returns (uint256 assets) {
        //利用previewRedeem() 计算能赎回的基础资产数额
        assets = previewRedeem(shares);
        //如果调用者不是owner,则检查并更新授权
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }
        _burn(owner, shares);
        _asset.transfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    //会计逻辑

    //返回合约中基础资产持仓
    function totalAssets() public view virtual returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        // 如果 supply 为 0，那么 1:1 赎回基础资产
        // 如果 supply 不为0，那么按比例赎回
        uint256 supply = totalSupply();
        return supply == 0 ? assets : (assets * supply) / totalAssets();
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        // 如果 supply 为 0，那么 1:1 赎回基础资产
        // 如果 supply 不为0，那么按比例赎回
        uint256 supply = totalSupply();
        return supply == 0 ? shares : (shares * totalAssets()) / supply;
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    //存款/提款逻辑限额

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf(owner));
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf(owner);
    }
}
