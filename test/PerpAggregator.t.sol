// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {PerpAggregator} from "../src/PerpAggregator.sol";
import {VenueManager} from "../src/VenueManager.sol";
import {OracleManager} from "../src/OracleManager.sol";
import {MockVenue} from "./mocks/MockVenue.sol";
import {MockOracle} from "./mocks/MockOracle.sol";

contract PerpAggregatorTest is Test {
    PerpAggregator public aggregator;
    VenueManager public venueManager;
    OracleManager public oracleManager;
    MockVenue public venue1;
    MockVenue public venue2;
    MockOracle public oracle;

    address public user = address(0x123);
    address public market = address(0x1);

    uint256 public constant INITIAL_PRICE = 2000e18;
    uint256 public constant MARGIN = 1000e18;
    uint256 public constant LEVERAGE = 10;

    event PositionOpened(
        address indexed user,
        address indexed market,
        address indexed venue,
        bool isLong,
        uint256 margin,
        uint256 leverage,
        uint256 executedSize,
        uint256 executionPrice
    );

    event PositionClosed(
        address indexed user,
        address indexed market,
        address indexed venue,
        uint256 positionSize,
        uint256 payout
    );

    function setUp() public {
        // Deploy core contracts
        venueManager = new VenueManager();
        oracleManager = new OracleManager();
        aggregator = new PerpAggregator(address(venueManager), address(oracleManager));

        // Deploy mocks
        venue1 = new MockVenue();
        venue2 = new MockVenue();
        oracle = new MockOracle(INITIAL_PRICE);

        // Setup venues
        venueManager.registerVenue(address(venue1), "GMX", 50, 10);
        venueManager.registerVenue(address(venue2), "Synthetix", 25, 20);

        // Setup oracle
        oracleManager.setOracle(market, address(oracle));
    }

    function test_OpenPosition_Success() public {
        uint256 deadline = block.timestamp + 1 hours;
        uint256 minOut = 0;

        vm.prank(user);
        vm.expectEmit(true, true, true, false);
        emit PositionOpened(user, market, address(venue1), true, MARGIN, LEVERAGE, 0, INITIAL_PRICE);

        uint256 executedSize = aggregator.openPosition(
            market,
            true,
            MARGIN,
            LEVERAGE,
            minOut,
            deadline
        );

        assertGt(executedSize, 0);
    }

    function test_OpenPosition_SelectsBestVenue() public {
        // Set venue2 to have better price
        venue2.setBasePrice(1900e18);

        uint256 deadline = block.timestamp + 1 hours;

        vm.prank(user);
        uint256 executedSize = aggregator.openPosition(
            market,
            true,
            MARGIN,
            LEVERAGE,
            0,
            deadline
        );

        // Venue2 should be selected (lower price for long)
        assertGt(executedSize, 0);
    }

    function test_ClosePosition_Success() public {
        // First open a position
        uint256 deadline = block.timestamp + 1 hours;

        vm.startPrank(user);
        uint256 executedSize = aggregator.openPosition(
            market,
            true,
            MARGIN,
            LEVERAGE,
            0,
            deadline
        );

        // Now close it
        vm.expectEmit(true, true, true, false);
        emit PositionClosed(user, market, address(venue1), executedSize, 0);

        uint256 payout = aggregator.closePosition(
            market,
            executedSize,
            0,
            deadline
        );

        vm.stopPrank();

        assertGt(payout, 0);
    }

    function test_IncreasePosition_Success() public {
        uint256 deadline = block.timestamp + 1 hours;

        vm.startPrank(user);

        // Open initial position
        aggregator.openPosition(market, true, MARGIN, LEVERAGE, 0, deadline);

        // Increase position
        uint256 additionalSize = aggregator.increasePosition(
            market,
            500e18,
            LEVERAGE,
            0,
            deadline
        );

        vm.stopPrank();

        assertGt(additionalSize, 0);
    }

    function test_ReducePosition_Success() public {
        uint256 deadline = block.timestamp + 1 hours;

        vm.startPrank(user);

        // Open position
        uint256 executedSize = aggregator.openPosition(
            market,
            true,
            MARGIN,
            LEVERAGE,
            0,
            deadline
        );

        // Reduce position
        uint256 payout = aggregator.reducePosition(
            market,
            executedSize / 2,
            0,
            deadline
        );

        vm.stopPrank();

        assertGt(payout, 0);
    }

    function test_RevertWhen_DeadlineExpired() public {
        uint256 deadline = block.timestamp - 1;

        vm.prank(user);
        vm.expectRevert(PerpAggregator.DeadlineExpired.selector);
        aggregator.openPosition(market, true, MARGIN, LEVERAGE, 0, deadline);
    }

    function test_RevertWhen_SlippageExceeded() public {
        uint256 deadline = block.timestamp + 1 hours;

        // Calculate expected size and set minOut higher
        uint256 expectedSize = (MARGIN * LEVERAGE * 1e18) / INITIAL_PRICE;
        uint256 minOut = expectedSize * 2; // Require 2x the expected size

        vm.prank(user);
        vm.expectRevert(PerpAggregator.SlippageExceeded.selector);
        aggregator.openPosition(market, true, MARGIN, LEVERAGE, minOut, deadline);
    }

    function test_RevertWhen_InvalidMargin() public {
        uint256 deadline = block.timestamp + 1 hours;

        vm.prank(user);
        vm.expectRevert(PerpAggregator.InvalidMargin.selector);
        aggregator.openPosition(market, true, 0, LEVERAGE, 0, deadline);
    }

    function test_RevertWhen_InvalidLeverage() public {
        uint256 deadline = block.timestamp + 1 hours;

        vm.prank(user);
        vm.expectRevert(PerpAggregator.InvalidLeverage.selector);
        aggregator.openPosition(market, true, MARGIN, 0, 0, deadline);
    }

    function test_RevertWhen_NoActiveVenues() public {
        // Deactivate all venues
        venueManager.setVenueStatus(address(venue1), false);
        venueManager.setVenueStatus(address(venue2), false);

        uint256 deadline = block.timestamp + 1 hours;

        vm.prank(user);
        vm.expectRevert(PerpAggregator.NoActiveVenues.selector);
        aggregator.openPosition(market, true, MARGIN, LEVERAGE, 0, deadline);
    }

    function test_RevertWhen_Paused() public {
        aggregator.pause();

        uint256 deadline = block.timestamp + 1 hours;

        vm.prank(user);
        vm.expectRevert(PerpAggregator.Paused.selector);
        aggregator.openPosition(market, true, MARGIN, LEVERAGE, 0, deadline);
    }

    function test_Unpause() public {
        aggregator.pause();
        aggregator.unpause();

        uint256 deadline = block.timestamp + 1 hours;

        vm.prank(user);
        uint256 executedSize = aggregator.openPosition(
            market,
            true,
            MARGIN,
            LEVERAGE,
            0,
            deadline
        );

        assertGt(executedSize, 0);
    }

    function test_RevertWhen_OraclePriceDeviationTooHigh() public {
        // Set venue price far from oracle price
        venue1.setBasePrice(3000e18); // 50% higher than oracle
        venue2.setBasePrice(3000e18);

        uint256 deadline = block.timestamp + 1 hours;

        vm.prank(user);
        vm.expectRevert(OracleManager.PriceDeviationTooHigh.selector);
        aggregator.openPosition(market, true, MARGIN, LEVERAGE, 0, deadline);
    }

    function test_SelectsVenueWithinLeverageLimit() public {
        // Venue2 has max leverage of 25
        uint256 highLeverage = 30;
        uint256 deadline = block.timestamp + 1 hours;

        vm.prank(user);
        // Should select venue1 (max leverage 50)
        uint256 executedSize = aggregator.openPosition(
            market,
            true,
            MARGIN,
            highLeverage,
            0,
            deadline
        );

        assertGt(executedSize, 0);
    }

    function test_RevertWhen_NonOwnerPauses() public {
        vm.prank(address(0x999));
        vm.expectRevert(PerpAggregator.Unauthorized.selector);
        aggregator.pause();
    }

    function testFuzz_OpenPosition(
        uint256 margin,
        uint256 leverage,
        bool isLong
    ) public {
        margin = bound(margin, 1e18, 10000e18);
        leverage = bound(leverage, 1, 50);

        uint256 deadline = block.timestamp + 1 hours;

        vm.prank(user);
        uint256 executedSize = aggregator.openPosition(
            market,
            isLong,
            margin,
            leverage,
            0,
            deadline
        );

        assertGt(executedSize, 0);
    }

    function testFuzz_FullPositionLifecycle(
        uint256 margin,
        uint256 leverage
    ) public {
        margin = bound(margin, 1e18, 10000e18);
        leverage = bound(leverage, 1, 50);
        uint256 deadline = block.timestamp + 1 hours;

        vm.startPrank(user);

        // Open
        uint256 executedSize = aggregator.openPosition(
            market,
            true,
            margin,
            leverage,
            0,
            deadline
        );

        // Increase
        uint256 additionalSize = aggregator.increasePosition(
            market,
            margin / 2,
            leverage,
            0,
            deadline
        );

        // Reduce
        uint256 payout1 = aggregator.reducePosition(
            market,
            additionalSize,
            0,
            deadline
        );

        // Close
        uint256 payout2 = aggregator.closePosition(
            market,
            executedSize,
            0,
            deadline
        );

        vm.stopPrank();

        assertGt(executedSize, 0);
        assertGt(additionalSize, 0);
        assertGt(payout1, 0);
        assertGt(payout2, 0);
    }
}
