// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../src/Swapper.sol";

contract SwapperTest is Test {
    Swapper swapper;
    address private constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    IERC20 private constant Weth = IERC20(WETH);

    address private constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    IERC20 private constant Usdt = IERC20(USDT);

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
        Weth.approve(address(swapper), type(uint256).max);
    }

    function testWoofiSwap() external {
        uint256 returnedAmount = swapper.woofiExecuteSwap(WETH, USDT, fromAmount, minToAmount, payable(whale), whale);
        assert(returnedAmount >= minToAmount);
    }

    function testTraderJoeSwap() external {
        // The token path of the swap, weth -> usdt
        IERC20[] memory tokenPath = new IERC20[](2);
        tokenPath[0] = Weth;
        tokenPath[1] = Usdt;

        // The weth - usdt pool is 15 bps
        uint256[] memory pairBinSteps = new uint256[](1);
        pairBinSteps[0] = 15;

        ILBRouter.Version[] memory versions = new ILBRouter.Version[](1);
        versions[0] = ILBRouter.Version.V2_1; // Dex swap is being performed on v2.1

        ILBRouter.Path memory path; // instanciate and populate the path to perform the swap.
        path.pairBinSteps = pairBinSteps;
        path.versions = versions;
        path.tokenPath = tokenPath;
        console.log(address(swapper));
        uint256 returnedAmount =
            swapper.traderJoeExecuteSwap(fromAmount, minToAmount, path, whale, block.timestamp + 10);
        assert(returnedAmount >= minToAmount);
    }

    function testKyberSwap() external {
        //uint160 MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
        uint160 MIN_SQRT_RATIO = 4295128739;
        address kyber1fee = 0x33ecc05a09A84aF2153C208EE7E61A31c6B1aDF1;
        // MAX_SQRT_RATIO
        (int256 qty0, int256 qty1) =
            swapper.kyberSwapExecuteSwap(kyber1fee, whale, int256(fromAmount), true, MIN_SQRT_RATIO + 1);
        assert(qty0 > qty1);
    }
}
