// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {LensGiveawayOpenAction} from "../src/LensGiveawayOpenAction.sol";
import {Types} from 'lens/Types.sol';
import {Types as GiveawayTypes} from '@lens-giveaway/Types.sol';
import {VRFCoordinatorV2Mock} from '@chainlink/vrf/mocks/VRFCoordinatorV2Mock.sol';
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {FakeUSDCe} from "src/fakeUsdce.sol";

contract LensGiveawayOpenActionTest is Test {
    LensGiveawayOpenAction public lensGiveawayOpenAction;
    VRFCoordinatorV2Mock public vrfCoordinatorV2Mock;

    FakeUSDCe internal usdce;
    
    address public usdceAddress;

    // Mumbai
    address public publicationAuthor = address(0xC231640418afea6B1bc88e4CFCF4677937584DD3); // profileId 1093
    address public participant = address(0xFa3ED20a82df27DF4b1a01dfb7EFC9b1b0848241); // profileId 1041
    address public lensHubProxy = address(0x4fbffF20302F3326B20052ab9C217C44F6480900); // Mumbai
    // address public usdceAddress = address(0x8502E527fC79928C5cA59F98d09B0B8732591e97); // fake USDCe
    address public participant2 = address(0x6732778Aff84B7493D235eaCE9C2B67FDA35E8b6); // profileId 1147
    address public participant3 = address(0xE9cA0ecA17C24E7AfeAc507c6B7508672D8F218B); // profileId 1148

    // Polygon
    // address public publicationAuthor = address(0x7241DDDec3A6aF367882eAF9651b87E1C7549Dff); // profileId 5
    // address public participant = address(0xa7073ca54734faBa5aFa5F1e01Cd31a03Ff7699F); // profileId 45190
    // address public lensHubProxy = address(0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d); // Polygon
    // address public usdceAddress = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174); // USDCe

    uint256 pubId = 1;

    uint256 participantProfileId = 1041;
    uint256 participant2ProfileId = 1147;
    uint256 participant3ProfileId = 1148;
    uint256 authorProfileId = 1093;

    function setUp() public {
        vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(100000000000000000, 1000000000);
        uint64 subId = vrfCoordinatorV2Mock.createSubscription();
        vrfCoordinatorV2Mock.fundSubscription(subId, 1000000000000000000);

        lensGiveawayOpenAction = new LensGiveawayOpenAction(lensHubProxy, participant, subId, address(vrfCoordinatorV2Mock));

        vrfCoordinatorV2Mock.addConsumer(subId, address(lensGiveawayOpenAction));
        
        usdce = new FakeUSDCe();
        usdceAddress = address(usdce);
    }

    function testInit() public {
        vm.startPrank(lensHubProxy); // OnlyHub

        lensGiveawayOpenAction.initializePublicationAction(5, pubId, publicationAuthor,  abi.encode(usdceAddress, 1));
        
        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).rewardAmount, 1);
        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).rewardCurrency, usdceAddress);
        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).usersRegistered, new address[](0));
        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).giveawayClosed, false);
    }

    function testInitAndEnterGiveaway() public {
        vm.startPrank(lensHubProxy); // OnlyHub
        lensGiveawayOpenAction.initializePublicationAction(authorProfileId, pubId, publicationAuthor,  abi.encode(usdceAddress, 1));

        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).rewardAmount, 1);
        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).rewardCurrency, usdceAddress);
        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).usersRegistered, new address[](0));
        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).giveawayClosed, false);

        Types.ProcessActionParams memory params = Types.ProcessActionParams(authorProfileId, pubId, authorProfileId, publicationAuthor, participant, new uint256[](0), new uint256[](0), new Types.PublicationType[](0), abi.encode(participantProfileId));
        lensGiveawayOpenAction.processPublicationAction(params);

        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).usersRegistered.length, 1);

        assertEq(usdce.balanceOf(participant), 0);
    }

    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event WinnerDrawn(uint256 pubId, address winner);

    function testFullFlow() public {
        vm.recordLogs();

        vm.startPrank(lensHubProxy); // OnlyHub

        // Initialize giveaway
        lensGiveawayOpenAction.initializePublicationAction(authorProfileId, pubId, publicationAuthor,  abi.encode(usdceAddress, 1));

        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).rewardAmount, 1);
        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).rewardCurrency, usdceAddress);
        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).usersRegistered, new address[](0));
        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).giveawayClosed, false);

        // Enter giveaway
        Types.ProcessActionParams memory params = Types.ProcessActionParams(authorProfileId, pubId, authorProfileId, publicationAuthor, participant, new uint256[](0), new uint256[](0), new Types.PublicationType[](0), abi.encode(participantProfileId));
        lensGiveawayOpenAction.processPublicationAction(params);

        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).usersRegistered.length, 1);

        assertEq(usdce.balanceOf(participant), 0);

        // --- Approve USDCe ---
        vm.stopPrank();
        vm.startPrank(publicationAuthor);
        usdce.approve(address(lensGiveawayOpenAction), 1);
        vm.stopPrank();
        vm.startPrank(lensHubProxy);
        // --------------------

        // Draw winner
        Types.ProcessActionParams memory paramsDraw = Types.ProcessActionParams(authorProfileId, pubId, authorProfileId, publicationAuthor, publicationAuthor, new uint256[](0), new uint256[](0), new Types.PublicationType[](0), abi.encode(authorProfileId));
        bytes memory requestIdBytes = lensGiveawayOpenAction.processPublicationAction(paramsDraw);
        uint256 requestId = abi.decode(requestIdBytes, (uint256));

        // vm.expectEmit(false, false, false, false);
        // uint256[] memory randomWords;
        // emit RequestFulfilled(0, randomWords);

        vm.expectEmit(false, false, false, false);
        emit WinnerDrawn(pubId, participant);

        // generate random number and fulfill the request of the open action contract
        vrfCoordinatorV2Mock.fulfillRandomWords(requestId, address(lensGiveawayOpenAction));

        assertEq(usdce.balanceOf(participant), 1);
    }

    function testFullFlow3participants() public {
        vm.startPrank(lensHubProxy); // OnlyHub

        // Initialize giveaway
        lensGiveawayOpenAction.initializePublicationAction(authorProfileId, pubId, publicationAuthor,  abi.encode(usdceAddress, 1));

        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).rewardAmount, 1);
        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).rewardCurrency, usdceAddress);
        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).usersRegistered, new address[](0));
        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).giveawayClosed, false);

        // Enter giveaway 1
        Types.ProcessActionParams memory params = Types.ProcessActionParams(authorProfileId, pubId, authorProfileId, publicationAuthor, participant, new uint256[](0), new uint256[](0), new Types.PublicationType[](0), abi.encode(participantProfileId));
        lensGiveawayOpenAction.processPublicationAction(params);
        
        // Enter giveaway 2
        Types.ProcessActionParams memory params2 = Types.ProcessActionParams(authorProfileId, pubId, authorProfileId, publicationAuthor, participant2, new uint256[](0), new uint256[](0), new Types.PublicationType[](0), abi.encode(participant2ProfileId));
        lensGiveawayOpenAction.processPublicationAction(params2);

        // Enter giveaway 3
        Types.ProcessActionParams memory params3 = Types.ProcessActionParams(authorProfileId, pubId, authorProfileId, publicationAuthor, participant3, new uint256[](0), new uint256[](0), new Types.PublicationType[](0), abi.encode(participant3ProfileId));
        lensGiveawayOpenAction.processPublicationAction(params3);

        assertEq(lensGiveawayOpenAction.giveawayInfos(pubId).usersRegistered.length, 3);

        assertEq(usdce.balanceOf(participant3), 0);

        // --- Approve USDCe ---
        vm.stopPrank();
        vm.startPrank(publicationAuthor);
        usdce.approve(address(lensGiveawayOpenAction), 1);
        vm.stopPrank();
        vm.startPrank(lensHubProxy);
        // --------------------

        // Draw winner
        Types.ProcessActionParams memory paramsDraw = Types.ProcessActionParams(authorProfileId, pubId, authorProfileId, publicationAuthor, publicationAuthor, new uint256[](0), new uint256[](0), new Types.PublicationType[](0), abi.encode(authorProfileId));
        bytes memory requestIdBytes = lensGiveawayOpenAction.processPublicationAction(paramsDraw);
        uint256 requestId = abi.decode(requestIdBytes, (uint256));

        vm.expectEmit(false, false, false, false);
        uint256[] memory randomWords;
        emit RequestFulfilled(0, randomWords);

        // generate random number and fulfill the request of the open action contract
        vrfCoordinatorV2Mock.fulfillRandomWords(requestId, address(lensGiveawayOpenAction));

        if(usdce.balanceOf(participant) == 1) {
            console.log("participant1 winner");
        } else if(usdce.balanceOf(participant2) == 1) {
            console.log("participant2 winner");
        } else if (usdce.balanceOf(participant3) == 1) {
            console.log("participant3 winner");
        }
        
        assertEq(usdce.balanceOf(participant3), 1);
    }
}