// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {OracleManager} from "../src/OracleManager.sol";
import {MockOracle} from "./mocks/MockOracle.sol";

contract OracleManagerTest is Test {
    OracleManager public oracleManager;
    MockOracle public mockOracle;

    address public market = address(0x1);
    uint256 public constant INITIAL_PRICE = 2000e18;

    event OracleSet(address indexed market, address indexed oracle);
    event MaxPriceDeviationUpdated(uint256 oldValue, uint256 newValue);

    function setUp() public {
        oracleManager = new OracleManager();
        mockOracle = new MockOracle(INITIAL_PRICE);
    }

    function test_SetOracle() public {
        vm.expectEmit(true, true, false, false);
        emit OracleSet(market, address(mockOracle));

        oracleManager.setOracle(market, address(mockOracle));

        assertEq(oracleManager.oracles(market), address(mockOracle));
    }

    function test_GetLatestPrice() public {
        oracleManager.setOracle(market, address(mockOracle));

        uint256 price = oracleManager.getLatestPrice(market);
        assertEq(price, INITIAL_PRICE);
    }

    function test_RevertWhen_OracleNotSet() public {
        vm.expectRevert(OracleManager.OracleNotSet.selector);
        oracleManager.getLatestPrice(market);
    }

    function test_RevertWhen_PriceIsStale() public {
        oracleManager.setOracle(market, address(mockOracle));

        // Warp forward 20 minutes to make the price stale
        vm.warp(block.timestamp + 20 minutes);

        vm.expectRevert(OracleManager.StalePrice.selector);
        oracleManager.getLatestPrice(market);
    }

    function test_ValidatePrice_Success() public {
        oracleManager.setOracle(market, address(mockOracle));

        // Execution price within 5% deviation
        uint256 executionPrice = 2050e18; // 2.5% higher

        oracleManager.validatePrice(market, executionPrice, true);
    }

    function test_RevertWhen_PriceDeviationTooHigh() public {
        oracleManager.setOracle(market, address(mockOracle));

        // Execution price with >5% deviation
        uint256 executionPrice = 2200e18; // 10% higher

        vm.expectRevert(OracleManager.PriceDeviationTooHigh.selector);
        oracleManager.validatePrice(market, executionPrice, true);
    }

    function test_SetMaxPriceDeviation() public {
        uint256 newDeviation = 1000; // 10%

        vm.expectEmit(false, false, false, true);
        emit MaxPriceDeviationUpdated(500, newDeviation);

        oracleManager.setMaxPriceDeviation(newDeviation);

        assertEq(oracleManager.maxPriceDeviationBps(), newDeviation);
    }

    function test_ValidatePrice_WithCustomDeviation() public {
        oracleManager.setOracle(market, address(mockOracle));
        oracleManager.setMaxPriceDeviation(1000); // 10%

        // Now 10% deviation should be acceptable
        uint256 executionPrice = 2200e18;

        oracleManager.validatePrice(market, executionPrice, true);
    }

    function test_RevertWhen_NonOwnerSetsOracle() public {
        vm.prank(address(0x999));
        vm.expectRevert(OracleManager.Unauthorized.selector);
        oracleManager.setOracle(market, address(mockOracle));
    }

    function testFuzz_ValidatePrice(uint256 executionPrice) public {
        oracleManager.setOracle(market, address(mockOracle));

        // Bound execution price to within 5% of oracle price
        executionPrice = bound(executionPrice, 1900e18, 2100e18);

        oracleManager.validatePrice(market, executionPrice, true);
    }

    function testFuzz_PriceDeviation(uint256 deviation) public {
        deviation = bound(deviation, 0, 5000); // 0-50%

        oracleManager.setMaxPriceDeviation(deviation);
        assertEq(oracleManager.maxPriceDeviationBps(), deviation);
    }
}
