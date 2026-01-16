// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IOracle} from "../../src/interfaces/IOracle.sol";

/// @title MockOracle
/// @notice Mock price oracle for testing
contract MockOracle is IOracle {
    uint256 public price;
    uint256 public timestamp;
    uint8 public constant decimals = 18;

    constructor(uint256 _initialPrice) {
        price = _initialPrice;
        timestamp = block.timestamp;
    }

    function setPrice(uint256 _price) external {
        price = _price;
        timestamp = block.timestamp;
    }

    function setTimestamp(uint256 _timestamp) external {
        timestamp = _timestamp;
    }

    function getLatestPrice() external view override returns (uint256, uint256) {
        return (price, timestamp);
    }
}
