// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FakeUSDCe is ERC20{
    constructor() ERC20("Fake USDCe", "USDCe"){
        _mint(0xC231640418afea6B1bc88e4CFCF4677937584DD3,1000*10**18);
    }
}