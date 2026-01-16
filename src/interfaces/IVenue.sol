// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IVenue
/// @notice Standard interface that all perpetual DEX venues must implement
interface IVenue {
    /// @notice Open a new perpetual position
    /// @param market The market address (e.g., ETH/USD)
    /// @param isLong True for long, false for short
    /// @param margin The margin amount in USDC
    /// @param leverage The leverage multiplier (e.g., 10 = 10x)
    /// @param minOut Minimum position size to accept (slippage protection)
    /// @return executedSize The actual position size opened
    function openPosition(
        address market,
        bool isLong,
        uint256 margin,
        uint256 leverage,
        uint256 minOut
    ) external returns (uint256 executedSize);

    /// @notice Close an existing perpetual position
    /// @param market The market address
    /// @param positionSize The size of the position to close
    /// @param minOut Minimum payout to accept (slippage protection)
    /// @return payout The amount returned to the user
    function closePosition(
        address market,
        uint256 positionSize,
        uint256 minOut
    ) external returns (uint256 payout);

    /// @notice Increase an existing position
    /// @param market The market address
    /// @param additionalMargin Additional margin to add
    /// @param leverage Leverage for the additional margin
    /// @param minOut Minimum additional position size
    /// @return additionalSize The additional position size added
    function increasePosition(
        address market,
        uint256 additionalMargin,
        uint256 leverage,
        uint256 minOut
    ) external returns (uint256 additionalSize);

    /// @notice Reduce an existing position
    /// @param market The market address
    /// @param sizeToReduce The position size to reduce
    /// @param minOut Minimum payout to accept
    /// @return payout The amount returned from the reduction
    function reducePosition(
        address market,
        uint256 sizeToReduce,
        uint256 minOut
    ) external returns (uint256 payout);

    /// @notice Get a quote for opening a position
    /// @param market The market address
    /// @param isLong True for long, false for short
    /// @param margin The margin amount
    /// @param leverage The leverage multiplier
    /// @return executionPrice The estimated execution price
    /// @return fee The estimated fee
    function getQuote(
        address market,
        bool isLong,
        uint256 margin,
        uint256 leverage
    ) external view returns (uint256 executionPrice, uint256 fee);
}
