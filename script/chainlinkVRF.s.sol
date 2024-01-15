// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {VRFv2Consumer} from "src/chainlinkVRF.sol";

contract ChainlinkVRFScript is Script {
    function setUp() public {}

    function run() external {
        vm.startBroadcast();
        new VRFv2Consumer(6940);
        vm.stopBroadcast();
    }
}
