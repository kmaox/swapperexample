// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./interfaces/IWooPP.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/joeinterfaces/ILBRouter.sol";
import "forge-std/Test.sol";

contract Swapper {
    // Woofi Deployment Address
    address private constant WOOPP = 0xeFF23B4bE1091b53205E35f3AfCD9C7182bf3062;
    IWooPPV2 private constant Woofi = IWooPPV2(WOOPP);

    address private constant TRADERJOE = 0xb4315e873dBcf96Ffd0acd8EA43f689D8c20fB30;
    ILBRouter private constant TraderJoe = ILBRouter(TRADERJOE);

    address private constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    IERC20 private constant Weth = IERC20(WETH);

    constructor() {
        // Approving the various pools the contract is interacting with
        IERC20(WETH).approve(WOOPP, type(uint256).max);
        IERC20(WETH).approve(TRADERJOE, type(uint256).max);
    }

    function woofiExecuteSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address payable to,
        address rebateTo
    ) external payable returns (uint256 realToAmount) {
        Weth.transferFrom(msg.sender, WOOPP, fromAmount);
        return Woofi.swap(fromToken, toToken, fromAmount, minToAmount, to, rebateTo);
    }

    function traderJoeExecuteSwap(uint256 fromAmount, uint256 minToAmount, address to, uint256 deadline) {
        TraderJoe.swapExactTokensForTokens();
    }
}
