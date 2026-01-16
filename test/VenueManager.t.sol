// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {VenueManager} from "../src/VenueManager.sol";

contract VenueManagerTest is Test {
    VenueManager public venueManager;

    address public owner = address(this);
    address public venue1 = address(0x1);
    address public venue2 = address(0x2);
    address public nonOwner = address(0x999);

    event VenueRegistered(address indexed venue, string name, uint256 maxLeverage, uint256 feeBps);
    event VenueRemoved(address indexed venue);
    event VenueStatusChanged(address indexed venue, bool isActive);

    function setUp() public {
        venueManager = new VenueManager();
    }

    function test_RegisterVenue() public {
        vm.expectEmit(true, false, false, true);
        emit VenueRegistered(venue1, "GMX", 50, 10);

        venueManager.registerVenue(venue1, "GMX", 50, 10);

        VenueManager.VenueInfo memory info = venueManager.getVenueInfo(venue1);
        assertEq(info.isActive, true);
        assertEq(info.maxLeverage, 50);
        assertEq(info.feeBps, 10);
        assertEq(info.name, "GMX");
    }

    function test_RegisterMultipleVenues() public {
        venueManager.registerVenue(venue1, "GMX", 50, 10);
        venueManager.registerVenue(venue2, "Synthetix", 25, 20);

        address[] memory activeVenues = venueManager.getActiveVenues();
        assertEq(activeVenues.length, 2);
        assertEq(activeVenues[0], venue1);
        assertEq(activeVenues[1], venue2);
    }

    function test_RevertWhen_RegisteringZeroAddress() public {
        vm.expectRevert(VenueManager.InvalidVenue.selector);
        venueManager.registerVenue(address(0), "Invalid", 50, 10);
    }

    function test_RevertWhen_RegisteringDuplicateVenue() public {
        venueManager.registerVenue(venue1, "GMX", 50, 10);

        vm.expectRevert(VenueManager.VenueAlreadyRegistered.selector);
        venueManager.registerVenue(venue1, "GMX", 50, 10);
    }

    function test_RevertWhen_InvalidLeverage() public {
        vm.expectRevert(VenueManager.InvalidLeverage.selector);
        venueManager.registerVenue(venue1, "GMX", 0, 10);

        vm.expectRevert(VenueManager.InvalidLeverage.selector);
        venueManager.registerVenue(venue1, "GMX", 101, 10);
    }

    function test_RemoveVenue() public {
        venueManager.registerVenue(venue1, "GMX", 50, 10);

        vm.expectEmit(true, false, false, false);
        emit VenueRemoved(venue1);

        venueManager.removeVenue(venue1);

        VenueManager.VenueInfo memory info = venueManager.getVenueInfo(venue1);
        assertEq(info.isActive, false);
    }

    function test_SetVenueStatus() public {
        venueManager.registerVenue(venue1, "GMX", 50, 10);

        vm.expectEmit(true, false, false, true);
        emit VenueStatusChanged(venue1, false);

        venueManager.setVenueStatus(venue1, false);

        assertEq(venueManager.isVenueActive(venue1), false);
    }

    function test_GetActiveVenues_FiltersInactive() public {
        venueManager.registerVenue(venue1, "GMX", 50, 10);
        venueManager.registerVenue(venue2, "Synthetix", 25, 20);

        venueManager.setVenueStatus(venue1, false);

        address[] memory activeVenues = venueManager.getActiveVenues();
        assertEq(activeVenues.length, 1);
        assertEq(activeVenues[0], venue2);
    }

    function test_RevertWhen_NonOwnerRegistersVenue() public {
        vm.prank(nonOwner);
        vm.expectRevert(VenueManager.Unauthorized.selector);
        venueManager.registerVenue(venue1, "GMX", 50, 10);
    }

    function test_TransferOwnership() public {
        venueManager.transferOwnership(nonOwner);
        assertEq(venueManager.owner(), nonOwner);
    }

    function testFuzz_RegisterVenue(uint256 maxLeverage, uint256 feeBps) public {
        maxLeverage = bound(maxLeverage, 1, 100);
        feeBps = bound(feeBps, 0, 1000);

        venueManager.registerVenue(venue1, "Test", maxLeverage, feeBps);

        VenueManager.VenueInfo memory info = venueManager.getVenueInfo(venue1);
        assertEq(info.maxLeverage, maxLeverage);
        assertEq(info.feeBps, feeBps);
    }
}
