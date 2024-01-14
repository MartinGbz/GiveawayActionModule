// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {LensGiveawayOpenAction} from "../src/LensGiveawayOpenAction.sol";
import {LensGiveaway} from "../src/LensGiveaway.sol";
import {Types} from 'lens/Types.sol';
import {Types as GiveawayTypes} from 'lens-giveaway/Types.sol';

abstract contract USDC {
    function approve(address spender, uint256 value) public virtual returns (bool);
    function balanceOf(address account) public view virtual returns (uint256);
}

contract LensGiveawayOpenActionTest is Test {
    LensGiveaway public lensGiveaway;
    LensGiveawayOpenAction public lensGiveawayOpenAction;

    USDC internal usdc;

    // Mumbai
    // address public postAuthor = address(0xabEA470fb28074C7122585D289F658C5aC978B12); // profileId 17
    // address public me = address(0xFa3ED20a82df27DF4b1a01dfb7EFC9b1b0848241); // profileId 1041

    // Polygon
    address public postAuthor = address(0x7241DDDec3A6aF367882eAF9651b87E1C7549Dff); // profileId 5
    address public me = address(0xa7073ca54734faBa5aFa5F1e01Cd31a03Ff7699F); // profileId 45190
    address public usdcAddress = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);

    // address public lensHubProxyMumbai = address(0x4fbffF20302F3326B20052ab9C217C44F6480900); // Mumbai
    address public lensHubProxyMumbai = address(0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d); // Polygon

    uint256 pubId = 1;

    // uint256 meProfileIdMumbai = 1041;
    uint256 meProfileIdPolygon = 45190;
    uint256 authorProfileIdPolygon = 5;

    function setUp() public {
        lensGiveaway = new LensGiveaway();
        lensGiveawayOpenAction = new LensGiveawayOpenAction(lensHubProxyMumbai, address(lensGiveaway), me);
        usdc = USDC(usdcAddress);
    }

    function testInit() public {
        console.log("Start testInit");

        vm.startPrank(lensHubProxyMumbai); // OnlyHub

        lensGiveawayOpenAction.initializePublicationAction(5, pubId, postAuthor,  abi.encode(usdcAddress, 1));
        
        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).rewardAmount, 1);
        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).rewardCurrency, usdcAddress);
        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).usersRegistered, new address[](0));
        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).giveawayClosed, false);

        console.log("End testInit");
    }

    function testProcess() public {
        vm.startPrank(lensHubProxyMumbai); // OnlyHub
        lensGiveawayOpenAction.initializePublicationAction(authorProfileIdPolygon, pubId, postAuthor,  abi.encode(usdcAddress, 1));

        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).rewardAmount, 1);
        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).rewardCurrency, 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).usersRegistered, new address[](0));
        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).giveawayClosed, false);

        Types.ProcessActionParams memory params = Types.ProcessActionParams(authorProfileIdPolygon, pubId, authorProfileIdPolygon, postAuthor, me, new uint256[](0), new uint256[](0), new Types.PublicationType[](0), abi.encode(meProfileIdPolygon));
        lensGiveawayOpenAction.processPublicationAction(params);

        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).usersRegistered.length, 1);

        assertEq(usdc.balanceOf(me), 0);

        vm.stopPrank();
        vm.startPrank(postAuthor);
        usdc.approve(address(lensGiveawayOpenAction), 1);
        vm.stopPrank();
        vm.startPrank(lensHubProxyMumbai); // OnlyHub

        // postAuthor has USDC.e on Polygon on 14/01/2024
        Types.ProcessActionParams memory paramsDraw = Types.ProcessActionParams(authorProfileIdPolygon, pubId, authorProfileIdPolygon, postAuthor, postAuthor, new uint256[](0), new uint256[](0), new Types.PublicationType[](0), abi.encode(authorProfileIdPolygon));
        lensGiveawayOpenAction.processPublicationAction(paramsDraw);

        assertEq(usdc.balanceOf(me), 1);
    }
}