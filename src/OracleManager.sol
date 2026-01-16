// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IOracle} from "./interfaces/IOracle.sol";

/// @title OracleManager
/// @notice Manages price oracles and validates execution prices
contract OracleManager {
    /// @notice Maximum allowed price staleness (15 minutes)
    uint256 public constant MAX_PRICE_AGE = 15 minutes;

    /// @notice Maximum allowed price deviation in basis points (500 = 5%)
    uint256 public maxPriceDeviationBps = 500;

    /// @notice Mapping of market to oracle address
    mapping(address => address) public oracles;

    /// @notice Owner address for admin functions
    address public owner;

    /// @notice Emitted when an oracle is set
    event OracleSet(address indexed market, address indexed oracle);

    /// @notice Emitted when max price deviation is updated
    event MaxPriceDeviationUpdated(uint256 oldValue, uint256 newValue);

    error Unauthorized();
    error InvalidOracle();
    error StalePrice();
    error PriceDeviationTooHigh();
    error OracleNotSet();

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Set oracle for a market
    /// @param market The market address
    /// @param oracle The oracle contract address
    function setOracle(address market, address oracle) external onlyOwner {
        if (market == address(0) || oracle == address(0)) revert InvalidOracle();

        oracles[market] = oracle;

        emit OracleSet(market, oracle);
    }

    /// @notice Set maximum price deviation
    /// @param newMaxDeviationBps New max deviation in basis points
    function setMaxPriceDeviation(uint256 newMaxDeviationBps) external onlyOwner {
        uint256 oldValue = maxPriceDeviationBps;
        maxPriceDeviationBps = newMaxDeviationBps;

        emit MaxPriceDeviationUpdated(oldValue, newMaxDeviationBps);
    }

    /// @notice Get the latest price for a market
    /// @param market The market address
    /// @return price The latest price
    function getLatestPrice(address market) external view returns (uint256 price) {
        address oracle = oracles[market];
        if (oracle == address(0)) revert OracleNotSet();

        uint256 timestamp;
        (price, timestamp) = IOracle(oracle).getLatestPrice();

        // Check price staleness
        if (block.timestamp - timestamp > MAX_PRICE_AGE) revert StalePrice();
    }

    /// @notice Validate execution price against oracle price
    /// @param market The market address
    /// @param executionPrice The execution price to validate
    /// @param isLong True if long position, false if short
    function validatePrice(
        address market,
        uint256 executionPrice,
        bool isLong
    ) external view {
        address oracle = oracles[market];
        if (oracle == address(0)) revert OracleNotSet();

        (uint256 oraclePrice, uint256 timestamp) = IOracle(oracle).getLatestPrice();

        // Check price staleness
        if (block.timestamp - timestamp > MAX_PRICE_AGE) revert StalePrice();

        // Calculate deviation
        uint256 deviation;
        if (executionPrice > oraclePrice) {
            deviation = ((executionPrice - oraclePrice) * 10000) / oraclePrice;
        } else {
            deviation = ((oraclePrice - executionPrice) * 10000) / oraclePrice;
        }

        // Check if deviation is acceptable
        if (deviation > maxPriceDeviationBps) revert PriceDeviationTooHigh();
    }

    /// @notice Transfer ownership
    /// @param newOwner The new owner address
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidOracle();
        owner = newOwner;
    }
}
