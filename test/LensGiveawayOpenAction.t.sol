// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {LensGiveawayOpenAction} from "../src/LensGiveawayOpenAction.sol";
import {LensGiveaway} from "../src/LensGiveaway.sol";
import {Types} from 'lens/Types.sol';

contract LensGiveawayOpenActionTest is Test {
    LensGiveaway public lensGiveaway;
    LensGiveawayOpenAction public lensGiveawayOpenAction;

    address public me = address(0xFa3ED20a82df27DF4b1a01dfb7EFC9b1b0848241);

    address public lensHubProxyMumbai = address(0x4fbffF20302F3326B20052ab9C217C44F6480900);

    function setUp() public {
        lensGiveaway = new LensGiveaway();
        lensGiveawayOpenAction = new LensGiveawayOpenAction(lensHubProxyMumbai, address(lensGiveaway), me);
    }

    function testInit() public {
        console.log("Start testInit");
        vm.startPrank(lensHubProxyMumbai); // OnlyHub
        lensGiveawayOpenAction.initializePublicationAction(1, 1, me, abi.encode("Hello"));
        assertEq(lensGiveawayOpenAction.initMessages(1, 1), "Hello");
        console.log("End testInit");
    }

    event Greet(string message, address actor);

    function testProcess() public {
        vm.startPrank(lensHubProxyMumbai); // OnlyHub
        lensGiveawayOpenAction.initializePublicationAction(1, 1, me, abi.encode("Hello"));
        
        Types.ProcessActionParams memory params = Types.ProcessActionParams(1, 1, 1, me, me, new uint256[](0), new uint256[](0), new Types.PublicationType[](0), abi.encode("World"));
        
        vm.expectEmit(true, true, false, true);
        emit Greet("Hello, World! Hello World", me);
        
        lensGiveawayOpenAction.processPublicationAction(params);
    }
}