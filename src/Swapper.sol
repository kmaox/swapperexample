// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./interfaces/IWooPP.sol";
import "./interfaces/joeinterfaces/ILBRouter.sol";
import "./interfaces/kyberinterfaces/IPool.sol";
import "./interfaces/zyberinterfaces/ISwapRouter.sol";
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
    address private constant ZYBERSWAP = 0xFa58b8024B49836772180f2Df902f231ba712F72;
    ISwapRouter private constant ZyberSwap = ISwapRouter(ZYBERSWAP);

    // Weth
    address private constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    IERC20 private constant Weth = IERC20(WETH);

    address private constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    IERC20 private constant Usdt = IERC20(USDT);

    address private constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    constructor() {
        // Approving the various pools the contract is interacting with
        IERC20(WETH).approve(WOOPP, type(uint256).max);
        IERC20(WETH).approve(TRADERJOE, type(uint256).max);
        IERC20(WETH).approve(KYBERSWAP1, type(uint256).max);
        IERC20(USDT).approve(ZYBERSWAP, type(uint256).max);
    }

    function executeSwap(
        address fromToken,
        address toToken,
        uint256[] calldata fromAmount,
        uint256[] calldata minToAmount,
        ILBRouter.Path memory traderjoePath,
        int256 kyberSwapQty,
        address to,
        uint256 deadline
    ) external returns (uint256 woofiAmountOut, uint256 traderJoeAmountOut, uint256 zyberAmountOut) {
        uint256 woofiFromAmount = fromAmount[0];
        woofiAmountOut = woofiExecuteSwap(fromToken, toToken, woofiFromAmount, minToAmount[1], payable(to), to);

        uint256 traderJoeFromAmount = fromAmount[1];
        traderJoeAmountOut = traderJoeExecuteSwap(traderJoeFromAmount, minToAmount[1], traderjoePath, to, deadline);

        // This is the MIN_SQRT_RATIO + 1, which needs to be inputted in order for all of the inputted swapQTY to be sold
        uint160 sellAll = 4295128740;

        (int256 qty0, int256 qty1) = kyberSwapExecuteSwap(KYBERSWAP1, to, kyberSwapQty, true, sellAll);

        int256 zyberFromAmount;
        if (qty0 < 0) {
            zyberFromAmount = absVal(qty0);
        } else {
            zyberFromAmount = absVal(qty1);
        }

        ISwapRouter.ExactInputSingleParams memory zyberParams;
        zyberParams.tokenIn = USDT;
        zyberParams.tokenOut = USDC;
        zyberParams.recipient = to;
        zyberParams.deadline = block.timestamp + 1;
        zyberParams.amountIn = uint256(zyberFromAmount);
        // 1% slippage
        zyberParams.amountOutMinimum = zyberParams.amountIn * 99 / 100;
        zyberParams.limitSqrtPrice = 0;
        zyberAmountOut = zyberExecuteswap(zyberParams);
    }

    function woofiExecuteSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address payable to,
        address rebateTo
    ) internal returns (uint256 realToAmount) {
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
    ) internal returns (uint256 amountOut) {
        // For the traderJoe logic, we need to send the weth
        // to the actual contract address, which sends it to the router
        Weth.transferFrom(msg.sender, address(this), fromAmount);
        return TraderJoe.swapExactTokensForTokens(fromAmount, minToAmount, path, to, deadline);
    }

    // We take in the address of the kyberswap pool as there
    // are a variety of kyberSwap pools that can be used in the future
    // See kyberswap for more details here
    function kyberSwapExecuteSwap(
        address kyberPool,
        address recipient,
        int256 swapQty,
        bool isToken0,
        uint160 limitSqrtP
    ) internal returns (int256 qty0, int256 qty1) {
        bytes memory data;
        Weth.transferFrom(msg.sender, address(this), uint256(swapQty));
        return IPool(kyberPool).swap(recipient, swapQty, isToken0, limitSqrtP, data);
    }

    function swapCallback(int256 deltaQty0, int256 deltaQty1, bytes calldata data) external {
        Weth.transfer(KYBERSWAP1, uint256(deltaQty0));
    }

    function zyberExecuteswap(ISwapRouter.ExactInputSingleParams memory params)
        public
        returns (uint256 zyberAmountOut)
    {
        Usdt.transferFrom(msg.sender, address(this), params.amountIn);
        return ZyberSwap.exactInputSingle(params);
    }

    function absVal(int256 integer) private returns (int256) {
        return (integer * -1);
    }
}
