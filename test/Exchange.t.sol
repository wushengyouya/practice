// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "src/Exchange.sol"; // 确保路径正确
import "src/Factory.sol"; // 确保路径正确
import "src/Token.sol"; // 确保路径正确

import "forge-std/Test.sol";

contract ExchangeTest is Test {
    Token internal token;
    Exchange internal exchange;
    Factory internal factory;
    address user = address(1);

    uint256 internal constant INITIAL_SUPPLY = 1000000 * 1e18; // 确保与Token合约的初始供应量一致

    function setUp() public {
        // 部署Token和Exchange合约
        token = new Token("Zuniswap Token", "ZUNI", INITIAL_SUPPLY);
        factory = new Factory();
        exchange = Exchange(factory.createExchange(address(token)));

        // 创建账户
        vm.deal(user, 10 ether); // 给用户账户添加以太币
        vm.deal(address(this), 10 ether);
    }

    // 测试构造函数
    function testConstructor() public view {
        assertEq(
            exchange.tokenAddress(),
            address(token),
            "Invalid token address"
        );
        assertEq(
            exchange.factoryAddress(),
            address(factory),
            "Invalid factory address"
        );
    }

    // 测试addLiquidity函数
    function testAddLiquidity() public {
        token.approve(address(exchange), 1e18);
        uint256 initialETH = address(this).balance;
        uint256 initialTokens = token.balanceOf(address(this));
        console.log(initialETH, initialTokens);

        // 添加流动性
        uint256 liquidityMinted = exchange.addLiquidity{value: 1 ether}(1e18);
        assertEq(
            token.balanceOf(address(this)),
            initialTokens - 1e18,
            "Invalid token balance"
        );
        assertEq(
            address(this).balance,
            initialETH - 1 ether,
            "Invalid ETH balance"
        );
        assertEq(liquidityMinted, 1 ether, "Invalid liquidity minted");

        // 检查合约余额
        assertEq(
            token.balanceOf(address(exchange)),
            1e18,
            "Invalid exchange token reserve"
        );
        assertEq(
            address(exchange).balance,
            1 ether,
            "Invalid exchange ETH reserve"
        );
    }

    receive() external payable {}

    // 测试removeLiquidity函数
    function testRemoveLiquidity() public {
        //token授权给exchange合约
        token.approve(address(exchange), 1e18);
        // 首先添加流动性
        exchange.addLiquidity{value: 1 ether}(1e18);
        uint256 balance = address(this).balance;
        uint256 tokenBalance = token.balanceOf(address(this));
        // 然后移除流动性
        uint256 ethReserveBefore = address(exchange).balance;
        uint256 tokenReserveBefore = token.balanceOf(address(exchange));
        exchange.removeLiquidity(1 ether);

        // 检查ETH和token是否返回给用户
        assertEq(
            balance + 1 ether,
            address(this).balance,
            "Invalid user ETH balance"
        );
        assertEq(
            token.balanceOf(address(this)),
            tokenBalance + 1e18,
            "Invalid user token balance"
        );

        // 检查合约余额
        assertEq(
            address(exchange).balance,
            ethReserveBefore - 1 ether,
            "Invalid exchange ETH reserve after"
        );
        assertEq(
            token.balanceOf(address(exchange)),
            tokenReserveBefore - 1e18,
            "Invalid exchange token reserve after"
        );
    }

    // 测试getTokenAmount和getETHAmount函数
    function testGetTokenAmountAndGetETHAmount() public {
        //token授权给exchange合约
        token.approve(address(exchange), 1e18);
        // 添加流动性
        exchange.addLiquidity{value: 1 ether}(1e18);

        // 测试ETH转token金额计算
        uint256 tokensBought = exchange.getTokenAmount(1 ether);
        assertGt(tokensBought, 0, "Tokens bought should be greater than zero");

        // 测试token转ETH金额计算
        uint256 ethReceived = exchange.getETHAmount(1e18);
        assertGt(ethReceived, 0, "ETH received should be greater than zero");
    }

    // 测试ethToTokenTransfer函数
    function testEthToTokenTransfer() public {
        //token授权给exchange合约
        token.approve(address(exchange), 1e18);
        // 添加流动性
        exchange.addLiquidity{value: 1 ether}(1e18);

        // 用户执行ETH转token
        uint256 tokensBeforeUser = token.balanceOf(user);
        exchange.ethToTokenTransfer{value: 1 ether}(1, user);
        uint256 tokensAfterUser = token.balanceOf(user);

        // 检查用户是否收到token
        assertEq(
            tokensAfterUser,
            tokensBeforeUser + 0.5 ether,
            "Invalid token balance for user"
        );
    }

    //
    //2,000,000,000,000,000,000
    // 测试tokenToEthSwap函数
    function testTokenToEthSwap() public {
        //token授权给exchange合约
        token.approve(address(exchange), 1e18);
        // 添加流动性
        exchange.addLiquidity{value: 1 ether}(1e18);
        // 用户接收一些token
        token.transfer(user, 1e18);

        // 用户执行token转ETH
        uint256 ethBeforeUser = user.balance;
        vm.prank(user);
        exchange.tokenToEthSwap(1e18, 0.1 ether);
        uint256 ethAfterUser = user.balance;

        // 检查用户是否收到ETH
        assertEq(
            ethAfterUser,
            ethBeforeUser + 0.1 ether,
            "Invalid ETH balance for user"
        );
    }

    // 测试tokenToTokenSwap函数
    function testTokenToTokenSwap() public {
        // 部署另一个Token合约用于交换
        Token anotherToken = new Token("Another Token", "ATKN", 1000000 * 1e18);
        Exchange anotherExchange = Exchange(
            factory.getExchange(address(anotherToken))
        );

        // 用户获取一些token
        token.transfer(user, 1e18);

        // 用户授权Exchange合约转移token
        vm.prank(user);
        token.approve(address(exchange), 1e18);

        // 执行token转token
        uint256 ethBeforeExchange = address(exchange).balance;
        vm.prank(user);
        exchange.tokenToTokenSwap(1e18, 0, address(anotherToken));

        // 检查智能合约的ETH余额是否减少
        assertEq(
            address(exchange).balance,
            ethBeforeExchange - 1 ether,
            "Invalid ETH balance for exchange after tokenToTokenSwap"
        );
    }

    // 测试getAmount函数（这是一个私有函数，因此需要通过公共函数调用）
    function testGetAmount() public {
        // 添加流动性
        exchange.addLiquidity{value: 1 ether}(1e18);

        // 调用getAmount来计算兑换比例
        uint256 tokensBought = exchange.getTokenAmount(0.5 ether);
        assertGt(tokensBought, 0, "Tokens bought should be greater than zero");
    }

    // 你需要确保每个函数的测试逻辑正确，并且考虑到各种边界情况。
    // 私有函数不能直接被测试合约调用，你需要通过公共函数或事件来间接测试它们。

    // 结束测试脚本
}
