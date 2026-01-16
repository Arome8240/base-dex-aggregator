// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {PerpAggregator} from "../src/PerpAggregator.sol";
import {VenueManager} from "../src/VenueManager.sol";
import {OracleManager} from "../src/OracleManager.sol";

/// @title Deploy
/// @notice Deployment script for Base Perpetual DEX Aggregator
contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy VenueManager
        VenueManager venueManager = new VenueManager();
        console2.log("VenueManager deployed at:", address(venueManager));

        // Deploy OracleManager
        OracleManager oracleManager = new OracleManager();
        console2.log("OracleManager deployed at:", address(oracleManager));

        // Deploy PerpAggregator
        PerpAggregator perpAggregator = new PerpAggregator(
            address(venueManager),
            address(oracleManager)
        );
        console2.log("PerpAggregator deployed at:", address(perpAggregator));

        vm.stopBroadcast();

        // Log deployment summary
        console2.log("\n=== Deployment Summary ===");
        console2.log("VenueManager:   ", address(venueManager));
        console2.log("OracleManager:  ", address(oracleManager));
        console2.log("PerpAggregator: ", address(perpAggregator));
        console2.log("========================\n");
    }
}
