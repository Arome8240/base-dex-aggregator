// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IVenue} from "./interfaces/IVenue.sol";
import {IPerpAggregator} from "./interfaces/IPerpAggregator.sol";
import {VenueManager} from "./VenueManager.sol";
import {OracleManager} from "./OracleManager.sol";

/// @title PerpAggregator
/// @notice Main entry point for perpetual DEX aggregation on Base
/// @dev Non-custodial router that aggregates execution across multiple perp venues
contract PerpAggregator is IPerpAggregator {
    /// @notice Venue manager contract
    VenueManager public immutable venueManager;

    /// @notice Oracle manager contract
    OracleManager public immutable oracleManager;

    /// @notice Owner address for admin functions
    address public owner;

    /// @notice Paused state
    bool public paused;

    /// @notice Reentrancy guard
    uint256 private locked = 1;

    error Unauthorized();
    error Paused();
    error DeadlineExpired();
    error SlippageExceeded();
    error InvalidMarket();
    error InvalidMargin();
    error InvalidLeverage();
    error InvalidPositionSize();
    error NoActiveVenues();
    error ReentrancyGuard();

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier nonReentrant() {
        if (locked != 1) revert ReentrancyGuard();
        locked = 2;
        _;
        locked = 1;
    }

    modifier checkDeadline(uint256 deadline) {
        if (block.timestamp > deadline) revert DeadlineExpired();
        _;
    }

    constructor(address _venueManager, address _oracleManager) {
        if (_venueManager == address(0) || _oracleManager == address(0)) {
            revert InvalidMarket();
        }

        venueManager = VenueManager(_venueManager);
        oracleManager = OracleManager(_oracleManager);
        owner = msg.sender;
    }

    /// @inheritdoc IPerpAggregator
    function openPosition(
        address market,
        bool isLong,
        uint256 margin,
        uint256 leverage,
        uint256 minOut,
        uint256 deadline
    )
        external
        whenNotPaused
        nonReentrant
        checkDeadline(deadline)
        returns (uint256 executedSize)
    {
        // Input validation
        if (market == address(0)) revert InvalidMarket();
        if (margin == 0) revert InvalidMargin();
        if (leverage == 0) revert InvalidLeverage();

        // Select best venue
        address bestVenue = _selectBestVenue(market, isLong, margin, leverage);

        // Get quote for price validation
        (uint256 executionPrice, ) = IVenue(bestVenue).getQuote(market, isLong, margin, leverage);

        // Validate price against oracle
        oracleManager.validatePrice(market, executionPrice, isLong);

        // Execute on best venue
        executedSize = IVenue(bestVenue).openPosition(
            market,
            isLong,
            margin,
            leverage,
            minOut
        );

        // Slippage check
        if (executedSize < minOut) revert SlippageExceeded();

        emit PositionOpened(
            msg.sender,
            market,
            bestVenue,
            isLong,
            margin,
            leverage,
            executedSize,
            executionPrice
        );
    }

    /// @inheritdoc IPerpAggregator
    function closePosition(
        address market,
        uint256 positionSize,
        uint256 minOut,
        uint256 deadline
    )
        external
        whenNotPaused
        nonReentrant
        checkDeadline(deadline)
        returns (uint256 payout)
    {
        // Input validation
        if (market == address(0)) revert InvalidMarket();
        if (positionSize == 0) revert InvalidPositionSize();

        // Select best venue (simplified - in production would track user's venue)
        address bestVenue = _selectBestVenueForClose(market);

        // Execute close
        payout = IVenue(bestVenue).closePosition(market, positionSize, minOut);

        // Slippage check
        if (payout < minOut) revert SlippageExceeded();

        emit PositionClosed(msg.sender, market, bestVenue, positionSize, payout);
    }

    /// @inheritdoc IPerpAggregator
    function increasePosition(
        address market,
        uint256 additionalMargin,
        uint256 leverage,
        uint256 minOut,
        uint256 deadline
    )
        external
        whenNotPaused
        nonReentrant
        checkDeadline(deadline)
        returns (uint256 additionalSize)
    {
        // Input validation
        if (market == address(0)) revert InvalidMarket();
        if (additionalMargin == 0) revert InvalidMargin();
        if (leverage == 0) revert InvalidLeverage();

        // Select venue (simplified)
        address venue = _selectBestVenueForClose(market);

        // Execute increase
        additionalSize = IVenue(venue).increasePosition(
            market,
            additionalMargin,
            leverage,
            minOut
        );

        // Slippage check
        if (additionalSize < minOut) revert SlippageExceeded();

        emit PositionIncreased(msg.sender, market, venue, additionalMargin, additionalSize);
    }

    /// @inheritdoc IPerpAggregator
    function reducePosition(
        address market,
        uint256 sizeToReduce,
        uint256 minOut,
        uint256 deadline
    )
        external
        whenNotPaused
        nonReentrant
        checkDeadline(deadline)
        returns (uint256 payout)
    {
        // Input validation
        if (market == address(0)) revert InvalidMarket();
        if (sizeToReduce == 0) revert InvalidPositionSize();

        // Select venue (simplified)
        address venue = _selectBestVenueForClose(market);

        // Execute reduction
        payout = IVenue(venue).reducePosition(market, sizeToReduce, minOut);

        // Slippage check
        if (payout < minOut) revert SlippageExceeded();

        emit PositionReduced(msg.sender, market, venue, sizeToReduce, payout);
    }

    /// @notice Select the best venue for opening a position
    /// @dev Compares quotes from all active venues and selects best execution
    function _selectBestVenue(
        address market,
        bool isLong,
        uint256 margin,
        uint256 leverage
    ) internal view returns (address bestVenue) {
        address[] memory activeVenues = venueManager.getActiveVenues();
        if (activeVenues.length == 0) revert NoActiveVenues();

        uint256 bestPrice = isLong ? type(uint256).max : 0;

        for (uint256 i = 0; i < activeVenues.length; i++) {
            address venue = activeVenues[i];

            // Check if venue supports the leverage
            VenueManager.VenueInfo memory info = venueManager.getVenueInfo(venue);
            if (leverage > info.maxLeverage) continue;

            try IVenue(venue).getQuote(market, isLong, margin, leverage) returns (
                uint256 price,
                uint256 fee
            ) {
                // Adjust price for fees
                uint256 effectivePrice = isLong ? price + fee : price - fee;

                // For longs, we want lowest price; for shorts, highest price
                if (isLong) {
                    if (effectivePrice < bestPrice) {
                        bestPrice = effectivePrice;
                        bestVenue = venue;
                    }
                } else {
                    if (effectivePrice > bestPrice) {
                        bestPrice = effectivePrice;
                        bestVenue = venue;
                    }
                }
            } catch {
                // Skip venues that fail to quote
                continue;
            }
        }

        if (bestVenue == address(0)) revert NoActiveVenues();
    }

    /// @notice Select venue for closing (simplified - returns first active venue)
    /// @dev In production, would track which venue holds user's position
    function _selectBestVenueForClose(address market) internal view returns (address) {
        address[] memory activeVenues = venueManager.getActiveVenues();
        if (activeVenues.length == 0) revert NoActiveVenues();

        // Simplified: return first active venue
        // In production: track user positions per venue
        return activeVenues[0];
    }

    /// @notice Pause the contract
    function pause() external onlyOwner {
        paused = true;
    }

    /// @notice Unpause the contract
    function unpause() external onlyOwner {
        paused = false;
    }

    /// @notice Transfer ownership
    /// @param newOwner The new owner address
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidMarket();
        owner = newOwner;
    }
}
