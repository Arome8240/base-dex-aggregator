// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IVenue} from "../../src/interfaces/IVenue.sol";

/// @title MockVenue
/// @notice Mock perpetual venue for testing
contract MockVenue is IVenue {
    uint256 public basePrice = 2000e18; // $2000 for ETH
    uint256 public feeBps = 10; // 0.1%
    bool public shouldRevert;

    mapping(address => mapping(address => uint256)) public positions;

    function setBasePrice(uint256 _price) external {
        basePrice = _price;
    }

    function setFeeBps(uint256 _feeBps) external {
        feeBps = _feeBps;
    }

    function setShouldRevert(bool _shouldRevert) external {
        shouldRevert = _shouldRevert;
    }

    function openPosition(
        address market,
        bool, // isLong
        uint256 margin,
        uint256 leverage,
        uint256 // minOut - not checked in mock, let aggregator handle it
    ) external override returns (uint256 executedSize) {
        if (shouldRevert) revert("MockVenue: forced revert");

        executedSize = (margin * leverage * 1e18) / basePrice;
        positions[msg.sender][market] += executedSize;

        return executedSize;
    }

    function closePosition(
        address market,
        uint256 positionSize,
        uint256 // minOut - not checked in mock
    ) external override returns (uint256 payout) {
        if (shouldRevert) revert("MockVenue: forced revert");

        require(positions[msg.sender][market] >= positionSize, "MockVenue: insufficient position");

        payout = (positionSize * basePrice) / 1e18;
        positions[msg.sender][market] -= positionSize;

        return payout;
    }

    function increasePosition(
        address market,
        uint256 additionalMargin,
        uint256 leverage,
        uint256 // minOut - not checked in mock
    ) external override returns (uint256 additionalSize) {
        if (shouldRevert) revert("MockVenue: forced revert");

        additionalSize = (additionalMargin * leverage * 1e18) / basePrice;
        positions[msg.sender][market] += additionalSize;

        return additionalSize;
    }

    function reducePosition(
        address market,
        uint256 sizeToReduce,
        uint256 // minOut - not checked in mock
    ) external override returns (uint256 payout) {
        if (shouldRevert) revert("MockVenue: forced revert");

        require(positions[msg.sender][market] >= sizeToReduce, "MockVenue: insufficient position");

        payout = (sizeToReduce * basePrice) / 1e18;
        positions[msg.sender][market] -= sizeToReduce;

        return payout;
    }

    function getQuote(
        address, // market
        bool, // isLong
        uint256 margin,
        uint256 leverage
    ) external view override returns (uint256 executionPrice, uint256 fee) {
        if (shouldRevert) revert("MockVenue: forced revert");

        executionPrice = basePrice;
        fee = (margin * leverage * feeBps) / 10000;

        return (executionPrice, fee);
    }
}
