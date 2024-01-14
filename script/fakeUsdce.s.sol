// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {FakeUSDCe} from "src/fakeUsdce.sol";

contract FakeUsdceScript is Script {
    function setUp() public {}

    function run() external {
        vm.startBroadcast();
        new FakeUSDCe();
        vm.stopBroadcast();
    }
}
