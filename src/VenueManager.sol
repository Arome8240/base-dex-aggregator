// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IVenue} from "./interfaces/IVenue.sol";

/// @title VenueManager
/// @notice Manages registered perpetual DEX venues
contract VenueManager {
    struct VenueInfo {
        bool isActive;
        uint256 maxLeverage;
        uint256 feeBps; // Fee in basis points (100 = 1%)
        string name;
    }

    /// @notice Mapping of venue address to venue info
    mapping(address => VenueInfo) public venues;

    /// @notice Array of all registered venue addresses
    address[] public venueList;

    /// @notice Owner address for admin functions
    address public owner;

    /// @notice Emitted when a venue is registered
    event VenueRegistered(address indexed venue, string name, uint256 maxLeverage, uint256 feeBps);

    /// @notice Emitted when a venue is removed
    event VenueRemoved(address indexed venue);

    /// @notice Emitted when a venue is activated/deactivated
    event VenueStatusChanged(address indexed venue, bool isActive);

    error Unauthorized();
    error VenueAlreadyRegistered();
    error VenueNotRegistered();
    error InvalidVenue();
    error InvalidLeverage();

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Register a new venue
    /// @param venue The venue contract address
    /// @param name The venue name
    /// @param maxLeverage Maximum leverage supported (e.g., 50 = 50x)
    /// @param feeBps Fee in basis points
    function registerVenue(
        address venue,
        string calldata name,
        uint256 maxLeverage,
        uint256 feeBps
    ) external onlyOwner {
        if (venue == address(0)) revert InvalidVenue();
        if (venues[venue].isActive) revert VenueAlreadyRegistered();
        if (maxLeverage == 0 || maxLeverage > 100) revert InvalidLeverage();

        venues[venue] = VenueInfo({
            isActive: true,
            maxLeverage: maxLeverage,
            feeBps: feeBps,
            name: name
        });

        venueList.push(venue);

        emit VenueRegistered(venue, name, maxLeverage, feeBps);
    }

    /// @notice Remove a venue
    /// @param venue The venue address to remove
    function removeVenue(address venue) external onlyOwner {
        if (!venues[venue].isActive) revert VenueNotRegistered();

        venues[venue].isActive = false;

        emit VenueRemoved(venue);
    }

    /// @notice Set venue active status
    /// @param venue The venue address
    /// @param isActive The new active status
    function setVenueStatus(address venue, bool isActive) external onlyOwner {
        if (venues[venue].maxLeverage == 0) revert VenueNotRegistered();

        venues[venue].isActive = isActive;

        emit VenueStatusChanged(venue, isActive);
    }

    /// @notice Check if a venue is active
    /// @param venue The venue address
    /// @return True if the venue is active
    function isVenueActive(address venue) external view returns (bool) {
        return venues[venue].isActive;
    }

    /// @notice Get all active venues
    /// @return activeVenues Array of active venue addresses
    function getActiveVenues() external view returns (address[] memory activeVenues) {
        uint256 count = 0;
        for (uint256 i = 0; i < venueList.length; i++) {
            if (venues[venueList[i]].isActive) {
                count++;
            }
        }

        activeVenues = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < venueList.length; i++) {
            if (venues[venueList[i]].isActive) {
                activeVenues[index] = venueList[i];
                index++;
            }
        }
    }

    /// @notice Get venue info
    /// @param venue The venue address
    /// @return info The venue information
    function getVenueInfo(address venue) external view returns (VenueInfo memory info) {
        return venues[venue];
    }

    /// @notice Transfer ownership
    /// @param newOwner The new owner address
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidVenue();
        owner = newOwner;
    }
}
