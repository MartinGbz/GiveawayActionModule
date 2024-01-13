// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ILensGiveaway} from "./ILensGiveaway.sol";

contract LensGiveaway is ILensGiveaway {
    event Greet(string message, address actor);

    function helloWorld(string memory message, address actor) external {
        emit Greet(string(abi.encodePacked("Hello, World! ", message)), actor);
    }
}