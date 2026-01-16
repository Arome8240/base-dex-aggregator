// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IPerpAggregator
/// @notice Interface for the perpetual DEX aggregator
interface IPerpAggregator {
    /// @notice Emitted when a position is opened
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

    /// @notice Emitted when a position is closed
    event PositionClosed(
        address indexed user,
        address indexed market,
        address indexed venue,
        uint256 positionSize,
        uint256 payout
    );

    /// @notice Emitted when a position is increased
    event PositionIncreased(
        address indexed user,
        address indexed market,
        address indexed venue,
        uint256 additionalMargin,
        uint256 additionalSize
    );

    /// @notice Emitted when a position is reduced
    event PositionReduced(
        address indexed user,
        address indexed market,
        address indexed venue,
        uint256 sizeReduced,
        uint256 payout
    );

    /// @notice Open a new perpetual position
    function openPosition(
        address market,
        bool isLong,
        uint256 margin,
        uint256 leverage,
        uint256 minOut,
        uint256 deadline
    ) external returns (uint256 executedSize);

    /// @notice Close an existing position
    function closePosition(
        address market,
        uint256 positionSize,
        uint256 minOut,
        uint256 deadline
    ) external returns (uint256 payout);

    /// @notice Increase an existing position
    function increasePosition(
        address market,
        uint256 additionalMargin,
        uint256 leverage,
        uint256 minOut,
        uint256 deadline
    ) external returns (uint256 additionalSize);

    /// @notice Reduce an existing position
    function reducePosition(
        address market,
        uint256 sizeToReduce,
        uint256 minOut,
        uint256 deadline
    ) external returns (uint256 payout);
}
