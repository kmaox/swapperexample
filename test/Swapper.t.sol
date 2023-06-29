// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../src/Swapper.sol";

contract SwapperTest is Test {
    Swapper swapper;
    address weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address usdt = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    // 1 eth, 18dp
    uint256 fromAmount = 1 * 1e18;
    // 1800 usdt, 6 dp
    uint256 minToAmount = 1800 * 1000000;

    address whale = 0xC6d973B31BB135CaBa83cf0574c0347BD763ECc5;

    function setUp() external {
        swapper = new Swapper();
        // Whale on arbitrum with 10+ WETH, used for testing
        vm.startPrank(whale);
        // Approve the Swapper
        IERC20(weth).approve(address(swapper), type(uint256).max);
    }

    function testWoofiSwap() external {
        uint256 returnedAmount = swapper.woofiExecuteSwap(weth, usdt, fromAmount, minToAmount, payable(whale), whale);
        assert(returnedAmount >= minToAmount);
    }

    function testTraderJoeSwap() external {}
}
