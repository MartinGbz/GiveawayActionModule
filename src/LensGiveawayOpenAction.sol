// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {HubRestricted} from 'lens/HubRestricted.sol';
import {Types} from 'lens/Types.sol';
import {IPublicationActionModule} from 'lens/IPublicationActionModule.sol';
import {LensModuleMetadata} from 'lens/LensModuleMetadata.sol';
import {ILensGiveaway} from './ILensGiveaway.sol';
import "forge-std/console.sol";

abstract contract LensHub {
    function ownerOf(uint256 profileId) public virtual view returns (address);
    function isFollowing(uint256 followerProfileId, uint256 followedProfileId) public virtual view returns (bool);
}

contract LensGiveawayOpenAction is HubRestricted, IPublicationActionModule, LensModuleMetadata {
    mapping(uint256 profileId => mapping(uint256 pubId => string initMessage)) internal _initMessages;
    ILensGiveaway internal _lensGiveaway;

    LensHub internal lensHub;
    
    constructor(address lensHubProxyContract, address lensGiveawayContract, address moduleOwner) HubRestricted(lensHubProxyContract) LensModuleMetadata(moduleOwner) {
        _lensGiveaway = ILensGiveaway(lensGiveawayContract);
        console.log(lensHubProxyContract);
        lensHub = LensHub(lensHubProxyContract);
    }

    function supportsInterface(bytes4 interfaceID) public pure override returns (bool) {
        return interfaceID == type(IPublicationActionModule).interfaceId || super.supportsInterface(interfaceID);
    }


    function initMessages(uint256 profileId, uint256 pubId) external view virtual returns (string memory) {
        return _initMessages[profileId][pubId];
    }


    function initializePublicationAction(
        uint256 profileId,
        uint256 pubId,
        address /* transactionExecutor */,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        string memory initMessage = abi.decode(data, (string));

        _initMessages[profileId][pubId] = initMessage;

        return data;
    }

    function processPublicationAction(
        Types.ProcessActionParams calldata params
    ) external override onlyHub returns (bytes memory) {

        console.log(params.publicationActedProfileId);
        address publicationOwner = lensHub.ownerOf(params.publicationActedProfileId);
        address publicationOwner2 = lensHub.ownerOf(1041);
        bool isFollowed = lensHub.isFollowing(params.publicationActedProfileId, 1041);
        console.log("isFollowed");
        console.log(isFollowed);

        console.log("publicationOwner");
        console.log(publicationOwner);
        console.log("transactionExecutor");
        console.log(params.transactionExecutor);
        console.log("publicationOwner2");
        console.log(publicationOwner2);

        string memory initMessage = _initMessages[params.publicationActedProfileId][params.publicationActedId];
        (string memory actionMessage) = abi.decode(params.actionModuleData, (string));

        bytes memory combinedMessage = abi.encodePacked(initMessage, " ", actionMessage);
        _lensGiveaway.helloWorld(string(combinedMessage), params.transactionExecutor);
        
        return combinedMessage;
    }
}