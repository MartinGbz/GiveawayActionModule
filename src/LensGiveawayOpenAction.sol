// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {HubRestricted} from 'lens/HubRestricted.sol';
import {Types} from 'lens/Types.sol';
import {IPublicationActionModule} from 'lens/IPublicationActionModule.sol';
import {LensModuleMetadata} from 'lens/LensModuleMetadata.sol';

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

    LensHub internal lensHub;

    using SafeERC20 for IERC20;
    
    constructor(address lensHubProxyContract, address moduleOwner) HubRestricted(lensHubProxyContract) LensModuleMetadata(moduleOwner) {
        lensHub = LensHub(lensHubProxyContract);
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

        address winner;
        
        address publicationOwner = lensHub.ownerOf(params.publicationActedProfileId);
        if(params.transactionExecutor != publicationOwner) {
            if(!lensHub.isFollowing(
                senderProfileId, params.publicationActedProfileId)) {
                revert("The sender is not following the publication owner");
            }
            
            _giveawayInfos[params.publicationActedId].usersRegistered.push(params.transactionExecutor);
        } else {
            uint256 randomNumber = 286532976532;
            winner = _giveawayInfos[params.publicationActedId].usersRegistered[randomNumber % _giveawayInfos[params.publicationActedId].usersRegistered.length];

            IERC20 token = IERC20(_giveawayInfos[params.publicationActedId].rewardCurrency);
            token.safeTransferFrom(
                params.actorProfileOwner,
                winner,
                _giveawayInfos[params.publicationActedId].rewardAmount
            );

            _giveawayInfos[params.publicationActedId].giveawayClosed = true;
        }
        
        return abi.encode(winner, _giveawayInfos[params.publicationActedId].usersRegistered.length);
    }
}