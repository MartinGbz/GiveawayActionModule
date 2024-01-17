// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {HubRestricted} from 'lens/HubRestricted.sol';
import {Types} from 'lens/Types.sol';
import {IPublicationActionModule} from 'lens/IPublicationActionModule.sol';
import {LensModuleMetadata} from 'lens/LensModuleMetadata.sol';

import {Types as GiveawayTypes} from '@lens-giveaway/Types.sol';
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@chainlink/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/shared/access/ConfirmedOwner.sol";

abstract contract LensHub {
    function ownerOf(uint256 profileId) public virtual view returns (address);
    function isFollowing(uint256 followerProfileId, uint256 followedProfileId) public virtual view returns (bool);
}

contract LensGiveawayOpenAction is HubRestricted, IPublicationActionModule, LensModuleMetadata, VRFConsumerBaseV2 {
    mapping(uint256 publicationId => GiveawayTypes.GiveawayInfos) internal _giveawayInfos;
    mapping(uint256 requestId => Types.ProcessActionParams) internal _publicationsParams;

    LensHub internal lensHub;

    using SafeERC20 for IERC20;

    /* ---------- ChainlinkVRF ---------- */
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests;
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    uint256[] public requestIds;
    uint256 public lastRequestId;
    bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    // need to put 200000 gas limit because otherwise fulfillRandomWords() (callBack function) wouldn't have enough gas to run completely
    uint32 callbackGasLimit = 200000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    /* ---------------------------------- */
    
    constructor(address lensHubProxyContract, address moduleOwner, uint64 subscriptionId, address vrfCoordinator) HubRestricted(lensHubProxyContract) LensModuleMetadata(moduleOwner) VRFConsumerBaseV2(vrfCoordinator) {
        lensHub = LensHub(lensHubProxyContract);

        COORDINATOR = VRFCoordinatorV2Interface(
            vrfCoordinator
        );
        s_subscriptionId = subscriptionId;
    }

    function supportsInterface(bytes4 interfaceID) public pure override returns (bool) {
        return interfaceID == type(IPublicationActionModule).interfaceId || super.supportsInterface(interfaceID);
    }

    function giveawayInfos(uint256 pubId) external view virtual returns (GiveawayTypes.GiveawayInfos memory) {
        return _giveawayInfos[pubId];
    }

    function initializePublicationAction(
        uint256 /* profileId */,
        uint256 pubId,
        address /* transactionExecutor */,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        (address currency, uint256 amount) = abi.decode(data, (address, uint256));
        _giveawayInfos[pubId] = GiveawayTypes.GiveawayInfos(currency, amount, new address[](0), false);
        return data;
    }

    function processPublicationAction(
        Types.ProcessActionParams calldata params
    ) external override onlyHub returns (bytes memory) {
        
        if(_giveawayInfos[params.publicationActedId].giveawayClosed) {
            revert("The giveaway is closed");
        }
        
        uint256 senderProfileId = abi.decode(params.actionModuleData, (uint256));
        if(lensHub.ownerOf(senderProfileId) != params.transactionExecutor) {
            revert("The transactionExecutor doesn't own the profileId of the sender ");
        }
        uint256 requestId;
        address publicationOwner = lensHub.ownerOf(params.publicationActedProfileId);
        if(params.transactionExecutor != publicationOwner) {
            if(!lensHub.isFollowing(
                senderProfileId, params.publicationActedProfileId)) {
                revert("The sender is not following the publication owner");
            }
            
            _giveawayInfos[params.publicationActedId].usersRegistered.push(params.transactionExecutor);
        } else {
            requestId = requestRandomWords();
            _publicationsParams[requestId] = params;
        }
        
        return abi.encode(requestId);
    }

    function rewardWinner(uint256 _requestId, uint256 randomNumber) private {
        Types.ProcessActionParams memory params = _publicationsParams[_requestId];
        uint256 randomNumberShaped = randomNumber % _giveawayInfos[params.publicationActedId].usersRegistered.length;
        address winner = _giveawayInfos[params.publicationActedId].usersRegistered[randomNumberShaped];

        IERC20 token = IERC20(_giveawayInfos[params.publicationActedId].rewardCurrency);
        
        token.safeTransferFrom(
            params.actorProfileOwner,
            winner,
            _giveawayInfos[params.publicationActedId].rewardAmount
        );

        _giveawayInfos[params.publicationActedId].giveawayClosed = true;
    }


    /* ---------- ChainlinkVRF ---------- */
    function requestRandomWords()
        private
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        rewardWinner(_requestId, _randomWords[0]);

        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) public view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }
    /* ---------------------------------- */
}