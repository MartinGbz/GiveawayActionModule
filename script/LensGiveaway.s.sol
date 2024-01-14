// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {LensGiveawayOpenAction} from "src/LensGiveawayOpenAction.sol";

contract LensGiveawayScript is Script {
    function setUp() public {}

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address moduleOwner = vm.envAddress("MODULE_OWNER");
        vm.startBroadcast(deployerPrivateKey);

        address lensHubProxyAddress = vm.envAddress("LENS_HUB_PROXY");

        new LensGiveawayOpenAction(lensHubProxyAddress, address(moduleOwner));

        vm.stopBroadcast();
    }
}
