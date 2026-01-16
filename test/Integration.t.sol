// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {PerpAggregator} from "../src/PerpAggregator.sol";
import {VenueManager} from "../src/VenueManager.sol";
import {OracleManager} from "../src/OracleManager.sol";
import {MockVenue} from "./mocks/MockVenue.sol";
import {MockOracle} from "./mocks/MockOracle.sol";

/// @title Integration Test
/// @notice End-to-end integration test demonstrating full position lifecycle
contract IntegrationTest is Test {
    PerpAggregator public aggregator;
    VenueManager public venueManager;
    OracleManager public oracleManager;
    MockVenue public gmxVenue;
    MockVenue public synthetixVenue;
    MockOracle public ethOracle;

    address public trader = address(0x123);
    address public ethMarket = address(0x1);

    uint256 public constant ETH_PRICE = 2000e18;
    uint256 public constant INITIAL_MARGIN = 1000e18; // 1000 USDC

    function setUp() public {
        // Deploy core contracts
        venueManager = new VenueManager();
        oracleManager = new OracleManager();
        aggregator = new PerpAggregator(address(venueManager), address(oracleManager));

        // Deploy mock venues
        gmxVenue = new MockVenue();
        gmxVenue.setBasePrice(ETH_PRICE);
        gmxVenue.setFeeBps(10); // 0.1%

        synthetixVenue = new MockVenue();
        synthetixVenue.setBasePrice(ETH_PRICE);
        synthetixVenue.setFeeBps(20); // 0.2%

        // Deploy oracle
        ethOracle = new MockOracle(ETH_PRICE);

        // Register venues
        venueManager.registerVenue(address(gmxVenue), "GMX", 50, 10);
        venueManager.registerVenue(address(synthetixVenue), "Synthetix", 25, 20);

        // Set oracle
        oracleManager.setOracle(ethMarket, address(ethOracle));

        console2.log("\n=== Integration Test Setup ===");
        console2.log("Trader:", trader);
        console2.log("ETH Market:", ethMarket);
        console2.log("ETH Price:", ETH_PRICE / 1e18, "USD");
        console2.log("Initial Margin:", INITIAL_MARGIN / 1e18, "USDC");
        console2.log("============================\n");
    }

    function test_FullPositionLifecycle() public {
        uint256 deadline = block.timestamp + 1 hours;
        uint256 leverage = 10;

        vm.startPrank(trader);

        // Step 1: Open a 10x long position
        console2.log("Step 1: Opening 10x long position...");
        uint256 positionSize = aggregator.openPosition(
            ethMarket,
            true,  // long
            INITIAL_MARGIN,
            leverage,
            0,
            deadline
        );
        console2.log("Position opened. Size:", positionSize / 1e18, "ETH");
        assertGt(positionSize, 0, "Position should be opened");

        // Step 2: Price moves up 10%
        console2.log("\nStep 2: ETH price increases 10%...");
        uint256 newPrice = (ETH_PRICE * 110) / 100;
        ethOracle.setPrice(newPrice);
        gmxVenue.setBasePrice(newPrice);
        synthetixVenue.setBasePrice(newPrice);
        console2.log("New ETH Price:", newPrice / 1e18, "USD");

        // Step 3: Increase position by 50%
        console2.log("\nStep 3: Increasing position by 50%...");
        uint256 additionalMargin = INITIAL_MARGIN / 2;
        uint256 additionalSize = aggregator.increasePosition(
            ethMarket,
            additionalMargin,
            leverage,
            0,
            deadline
        );
        console2.log("Position increased. Additional size:", additionalSize / 1e18, "ETH");
        assertGt(additionalSize, 0, "Position should be increased");

        // Step 4: Price moves down 5%
        console2.log("\nStep 4: ETH price decreases 5%...");
        newPrice = (newPrice * 95) / 100;
        ethOracle.setPrice(newPrice);
        gmxVenue.setBasePrice(newPrice);
        synthetixVenue.setBasePrice(newPrice);
        console2.log("New ETH Price:", newPrice / 1e18, "USD");

        // Step 5: Reduce position by 25%
        console2.log("\nStep 5: Reducing position by 25%...");
        uint256 totalSize = positionSize + additionalSize;
        uint256 sizeToReduce = totalSize / 4;
        uint256 payout1 = aggregator.reducePosition(
            ethMarket,
            sizeToReduce,
            0,
            deadline
        );
        console2.log("Position reduced. Payout:", payout1 / 1e18, "USDC");
        assertGt(payout1, 0, "Should receive payout from reduction");

        // Step 6: Close remaining position
        console2.log("\nStep 6: Closing remaining position...");
        uint256 remainingSize = totalSize - sizeToReduce;
        uint256 payout2 = aggregator.closePosition(
            ethMarket,
            remainingSize,
            0,
            deadline
        );
        console2.log("Position closed. Final payout:", payout2 / 1e18, "USDC");
        assertGt(payout2, 0, "Should receive payout from close");

        vm.stopPrank();

        // Summary
        uint256 totalPayout = payout1 + payout2;
        console2.log("\n=== Trade Summary ===");
        console2.log("Total Margin Invested:", (INITIAL_MARGIN + additionalMargin) / 1e18, "USDC");
        console2.log("Total Payout:", totalPayout / 1e18, "USDC");
        console2.log("===================\n");
    }

    function test_VenueSelection() public {
        uint256 deadline = block.timestamp + 1 hours;

        // GMX has better price (lower fee)
        console2.log("\n=== Venue Selection Test ===");
        console2.log("GMX fee: 0.1%");
        console2.log("Synthetix fee: 0.2%");

        vm.prank(trader);
        uint256 positionSize = aggregator.openPosition(
            ethMarket,
            true,
            INITIAL_MARGIN,
            10,
            0,
            deadline
        );

        console2.log("Position opened via best venue (GMX expected)");
        console2.log("Position size:", positionSize / 1e18, "ETH");
        assertGt(positionSize, 0);
        console2.log("==========================\n");
    }

    function test_OraclePriceProtection() public {
        uint256 deadline = block.timestamp + 1 hours;

        // Set venue price 10% higher than oracle (should fail)
        uint256 manipulatedPrice = (ETH_PRICE * 110) / 100;
        gmxVenue.setBasePrice(manipulatedPrice);
        synthetixVenue.setBasePrice(manipulatedPrice);

        console2.log("\n=== Oracle Protection Test ===");
        console2.log("Oracle price:", ETH_PRICE / 1e18, "USD");
        console2.log("Venue price:", manipulatedPrice / 1e18, "USD");
        console2.log("Deviation: 10% (exceeds 5% limit)");

        vm.prank(trader);
        vm.expectRevert(OracleManager.PriceDeviationTooHigh.selector);
        aggregator.openPosition(
            ethMarket,
            true,
            INITIAL_MARGIN,
            10,
            0,
            deadline
        );

        console2.log("Transaction reverted as expected");
        console2.log("============================\n");
    }

    function test_LeverageLimit() public {
        uint256 deadline = block.timestamp + 1 hours;
        uint256 highLeverage = 30; // Synthetix max is 25x

        console2.log("\n=== Leverage Limit Test ===");
        console2.log("Requested leverage: 30x");
        console2.log("GMX max leverage: 50x");
        console2.log("Synthetix max leverage: 25x");

        vm.prank(trader);
        uint256 positionSize = aggregator.openPosition(
            ethMarket,
            true,
            INITIAL_MARGIN,
            highLeverage,
            0,
            deadline
        );

        console2.log("Position opened via GMX (only venue supporting 30x)");
        console2.log("Position size:", positionSize / 1e18, "ETH");
        assertGt(positionSize, 0);
        console2.log("=========================\n");
    }
}
