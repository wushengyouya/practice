// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/Test.sol";

interface IExchange {
    function ethToTokenSwap(uint256 _minTokens) external payable;

    function ethToTokenTransfer(
        uint256 _minTokens,
        address _recipient
    ) external payable;
}

interface IFactory {
    function getExchange(address _tokenAddress) external returns (address);
}

contract Exchange is ERC20 {
    //token地址
    address public tokenAddress;
    //工厂合约地址
    address public factoryAddress;

    constructor(address _token) ERC20("Zuniswap", "ZUNI-V1") {
        require(_token != address(0), "invalid token address");
        tokenAddress = _token;
        factoryAddress = msg.sender;
    }

    //添加流动性
    function addLiquidity(
        uint256 _tokenAmount
    ) public payable returns (uint256) {
        console.log(msg.sender);
        //初始状态，无任何流动性
        if (getReserve() == 0) {
            require(_tokenAmount != 0, "zero tokenAmount");
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                _tokenAmount
            );
            //兑换合约初始状态按照1:1比例
            uint256 liquidity = address(this).balance;
            _mint(msg.sender, liquidity);
            return liquidity;
        } else {
            //获取eth总量
            uint256 ethReserve = address(this).balance - msg.value;
            //获取token总量
            uint256 tokenReserve = getReserve();
            //计算可以兑换的token量
            uint256 tokenAmount = (msg.value * tokenReserve) / ethReserve; //tokenReserve/ethReserve 一个以太币换取多少个token
            //TODO:传入的token大于计算出的token，是为了保证撤回流动性的时候计算退还投入的代币 ??
            require(_tokenAmount >= tokenAmount, "insufficient token amount"); //必须按照上面的比例

            //将token转入合约
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                tokenAmount
            );
            //计算要mint的流动性token
            uint256 liquidity = (msg.value * totalSupply()) / ethReserve;

            //mint token to user
            _mint(msg.sender, liquidity);
            //返回流动性
            return liquidity;
        }
    }

    //移除流动性，_tokenAmount流动性代币数量
    function removeLiquidity(uint256 _tokenAmount) public {
        require(_tokenAmount > 0, "zero tokenAmount");
        //获取总ETH
        uint256 ethReserve = address(this).balance;
        //获取总token
        uint256 tokenReserve = getReserve();

        //根据代币兑换出ETH
        uint256 eth = (_tokenAmount * ethReserve) / totalSupply(); //ethReserve / totalSupply()一个token可以换几个eth
        // //根据ETH算算出投入的token
        //TODO: understand this code uint256 tokenAmount = (eth * tokenReserve) / ethReserve;
        uint256 tokenAmount = (tokenReserve * _tokenAmount) / totalSupply();
        //销毁用户的流动性代币
        _burn(msg.sender, _tokenAmount);
        //退回ETH,token
        (bool success, ) = msg.sender.call{value: eth}("");
        require(success);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
    }

    //根据传入的token计算出价格

    //获取合约代币总量
    function getReserve() private view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function getTokenAmount(uint256 _ethSold) public returns (uint256) {
        require(_ethSold > 0, "invalid _ethSold");
        uint256 tokenReserve = getReserve();
        return getAmount(_ethSold, address(this).balance, tokenReserve);
    }

    function getETHAmount(uint256 _tokenSold) public returns (uint256) {
        require(_tokenSold > 0, "invalid _tokenSold");
        uint256 tokenReserve = getReserve();
        uint ethReserve = address(this).balance;
        return getAmount(_tokenSold, tokenReserve, ethReserve);
    }

    function ethToToken(uint256 _minTokens, address recipient) private {
        uint256 tokenReserve = getReserve();
        uint256 tokensBought = getAmount(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );
        require(tokensBought > _minTokens, "insufficient output amount");
        IERC20(tokenAddress).transfer(recipient, tokensBought);
    }

    //ETH to Token
    function ethToTokenTransfer(
        uint256 _minTokens,
        address _recipient
    ) public payable {
        ethToToken(_minTokens, _recipient);
    }

    //Token To ETH
    function tokenToEthSwap(uint256 _tokensSold, uint256 _minEth) public {
        //获取Token总量
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );
        require(ethBought > _minEth, "insuficient output amount");
        (bool success, ) = payable(msg.sender).call{value: ethBought}("");
        require(success);
    }

    //Token to Token
    function tokenToTokenSwap(
        uint256 _tokenSold,
        uint256 _minTokensBought,
        address _tokenAddress
    ) public {
        //先把token转换为eth
        //在把eth转为token
        address exchangeAddress = IFactory(factoryAddress).getExchange(
            _tokenAddress
        );
        require(
            exchangeAddress != address(this) && exchangeAddress != address(0),
            "invalid exchange address"
        );
        uint256 tokenReserve = getReserve();

        uint256 ethBought = getAmount(
            _tokenSold,
            tokenReserve,
            address(this).balance
        );
        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenSold
        );
        //调用目标token的exchange合约，将eth传入转为token
        IExchange(exchangeAddress).ethToTokenTransfer{value: ethBought}(
            _minTokensBought,
            msg.sender
        );
    }

    event Msg(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve);

    //计算兑换的数量 收了手续费
    function getAmount1(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) private returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
        //计算手续费按照1%来收取
        uint256 inputAmountWithFee = inputAmount * 99; //49500
        uint256 numerator = inputAmountWithFee * outputReserve; //49500000
        uint256 denominator = (100 * inputReserve) + inputAmountWithFee; //149500
        emit Msg(inputAmount / 1e18, inputReserve, outputReserve);
        console.log(inputAmountWithFee, numerator, denominator);
        return numerator / denominator;
    }

    //不收手续费
    function getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) private view returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
        console.log(
            inputAmount,
            inputReserve,
            outputReserve,
            (inputAmount * outputReserve) / (inputReserve + inputAmount)
        );
        return (inputAmount * outputReserve) / (inputReserve + inputAmount);
    }
}
