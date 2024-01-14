// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {HubRestricted} from 'lens/HubRestricted.sol';
import {Types} from 'lens/Types.sol';
import {IPublicationActionModule} from 'lens/IPublicationActionModule.sol';
import {LensModuleMetadata} from 'lens/LensModuleMetadata.sol';
import {ILensGiveaway} from './ILensGiveaway.sol';
import {Types as GiveawayTypes} from 'lens-giveaway/Types.sol';
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "forge-std/console.sol";

abstract contract LensHub {
    function ownerOf(uint256 profileId) public virtual view returns (address);
    function isFollowing(uint256 followerProfileId, uint256 followedProfileId) public virtual view returns (bool);
}

contract LensGiveawayOpenAction is HubRestricted, IPublicationActionModule, LensModuleMetadata {
    mapping(uint256 publicationId => GiveawayTypes.GiveawayInfos) internal _giveawayInfos;

    ILensGiveaway internal _lensGiveaway;

    LensHub internal lensHub;

    using SafeERC20 for IERC20;
    
    constructor(address lensHubProxyContract, address lensGiveawayContract, address moduleOwner) HubRestricted(lensHubProxyContract) LensModuleMetadata(moduleOwner) {
        _lensGiveaway = ILensGiveaway(lensGiveawayContract);
        lensHub = LensHub(lensHubProxyContract);
    }

    function supportsInterface(bytes4 interfaceID) public pure override returns (bool) {
        return interfaceID == type(IPublicationActionModule).interfaceId || super.supportsInterface(interfaceID);
    }

    function giveawayInfos(uint256 pubId) external view virtual returns (GiveawayTypes.GiveawayInfos memory) {
        return _giveawayInfos[pubId];
    }

    function initializePublicationAction(
        uint256 profileId,
        uint256 pubId,
        address /* transactionExecutor */,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        // address currency = abi.decode(data, (address));
        (address currency, uint256 amount) = abi.decode(data, (address, uint256));
        _giveawayInfos[pubId] = GiveawayTypes.GiveawayInfos(currency, amount, new address[](0), false);
        return data;
    }

    function processPublicationAction(
        Types.ProcessActionParams calldata params
    ) external override onlyHub returns (bytes memory) {
        console.log("1");
        
        if(_giveawayInfos[params.publicationActedId].giveawayClosed) {
            revert("The giveaway is closed");
        }
        
        console.log("2");
        
        uint256 senderProfileId = abi.decode(params.actionModuleData, (uint256));
        if(lensHub.ownerOf(senderProfileId) != params.transactionExecutor) {
            revert("The transactionExecutor doesn't own the profileId of the sender ");
        }
        
        console.log("3");
        
        address publicationOwner = lensHub.ownerOf(params.publicationActedProfileId);
        if(params.transactionExecutor != publicationOwner) {
            console.log("4");
            
            if(!lensHub.isFollowing(
                senderProfileId, params.publicationActedProfileId)) {
                revert("The sender is not following the publication owner");
            }

            _giveawayInfos[params.publicationActedId].usersRegistered.push(params.transactionExecutor);
        } else {
            console.log("5");
            uint256 randomNumber = 286532976532;
            address winner = _giveawayInfos[params.publicationActedId].usersRegistered[randomNumber % _giveawayInfos[params.publicationActedId].usersRegistered.length];

            console.log(winner);
            console.log("6");

            IERC20 token = IERC20(_giveawayInfos[params.publicationActedId].rewardCurrency);
            token.safeTransferFrom(
                params.actorProfileOwner,
                winner,
                _giveawayInfos[params.publicationActedId].rewardAmount
            );

            console.log("7");
            // payable(winner).transfer(_giveawayInfos[params.publicationActedId].rewardAmount);
            _giveawayInfos[params.publicationActedId].giveawayClosed = true;

            console.log("8");
        }
        
        return abi.encode(_giveawayInfos[params.publicationActedId].usersRegistered.length, _giveawayInfos[params.publicationActedId].giveawayClosed);
    }
}