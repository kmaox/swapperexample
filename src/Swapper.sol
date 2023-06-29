// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./interfaces/IWooPP.sol";
import "./interfaces/joeinterfaces/ILBRouter.sol";
import "./interfaces/kyberinterfaces/IPool.sol";
import "./interfaces/zyberinterfaces/IZyberRouter02.sol";
import "forge-std/Test.sol";

contract Swapper {
    // Woofi Deployment Address
    address private constant WOOPP = 0xeFF23B4bE1091b53205E35f3AfCD9C7182bf3062;
    IWooPPV2 private constant Woofi = IWooPPV2(WOOPP);

    // TraderJoe
    address private constant TRADERJOE = 0xb4315e873dBcf96Ffd0acd8EA43f689D8c20fB30;
    ILBRouter private constant TraderJoe = ILBRouter(TRADERJOE);

    //KyberSwap Elastic
    address private constant KYBERSWAP1 = 0x33ecc05a09A84aF2153C208EE7E61A31c6B1aDF1;

    // ZyberSwap
    address private constant ZYBERSWAP = 0x16e71B13fE6079B4312063F7E81F76d165Ad32Ad;
    IZyberRouter02 private constant ZyberSwap = IZyberRouter02(ZYBERSWAP);
    address private constant ZYBERSWAPUSDTUSDC = 0x941F4ac07d2526258FC9A07a6C9a23715968B419;
    // Weth
    address private constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    IERC20 private constant Weth = IERC20(WETH);

    address private constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    IERC20 private constant Usdt = IERC20(USDT);

    constructor() {
        // Approving the various pools the contract is interacting with
        IERC20(WETH).approve(WOOPP, type(uint256).max);
        IERC20(WETH).approve(TRADERJOE, type(uint256).max);
        IERC20(WETH).approve(KYBERSWAP1, type(uint256).max);
        IERC20(USDT).approve(ZYBERSWAP, type(uint256).max);
    }

    function woofiExecuteSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address payable to,
        address rebateTo
    ) external returns (uint256 realToAmount) {
        // For Woo logic, we need to send the token directly to the pool
        // contract here acts like a router basically
        Weth.transferFrom(msg.sender, WOOPP, fromAmount);
        return Woofi.swap(fromToken, toToken, fromAmount, minToAmount, to, rebateTo);
    }

    function traderJoeExecuteSwap(
        uint256 fromAmount,
        uint256 minToAmount,
        ILBRouter.Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut) {
        // For the traderJoe logic, we need to send the weth
        // to the actual contract address, which sends it to the router
        Weth.transferFrom(msg.sender, address(this), fromAmount);
        return TraderJoe.swapExactTokensForTokens(fromAmount, minToAmount, path, to, deadline);
    }

    // We take in the address of the kyberswap pool as there
    // are a variety of kyberSwap pools that can be used in the future
    function kyberSwapExecuteSwap(
        address kyberPool,
        address recipient,
        int256 swapQty,
        bool isToken0,
        uint160 limitSqrtP
    ) external returns (int256 qty0, int256 qty1) {
        bytes memory data;
        Weth.transferFrom(msg.sender, address(this), uint256(swapQty));
        return IPool(kyberPool).swap(recipient, swapQty, isToken0, limitSqrtP, data);
    }

    function swapCallback(int256 deltaQty0, int256 deltaQty1, bytes calldata data) external {
        Weth.transfer(KYBERSWAP1, uint256(deltaQty0));
    }

    function zyberExecuteswap(
        uint256 amountFrom,
        uint256 minToAmount,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        Usdt.transferFrom(msg.sender, address(this), amountFrom);
        ZyberSwap.swapExactTokensForTokens(amountFrom, 0, path, to, deadline);
    }
}
