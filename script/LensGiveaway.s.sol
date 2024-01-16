// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {LensGiveawayOpenAction} from "src/LensGiveawayOpenAction.sol";

contract LensGiveawayScript is Script {
    function setUp() public {}

    function run() external {
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // address moduleOwner = vm.envAddress("MODULE_OWNER");
        // vm.startBroadcast(deployerPrivateKey);

        // address lensHubProxyAddress = vm.envAddress("LENS_HUB_PROXY");

        vm.startBroadcast();
        new LensGiveawayOpenAction(0x4fbffF20302F3326B20052ab9C217C44F6480900, 0xFa3ED20a82df27DF4b1a01dfb7EFC9b1b0848241, 6940);
        vm.stopBroadcast();
    }
}
