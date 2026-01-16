// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IOracle
/// @notice Interface for price oracle feeds (Chainlink-style)
interface IOracle {
    /// @notice Get the latest price for an asset
    /// @return price The latest price (scaled by decimals)
    /// @return timestamp The timestamp of the price update
    function getLatestPrice() external view returns (uint256 price, uint256 timestamp);

    /// @notice Get the number of decimals for the price feed
    /// @return decimals The number of decimals
    function decimals() external view returns (uint8);
}
