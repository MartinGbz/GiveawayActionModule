// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @title Types
 * @author MartinGbz
 */
library Types {

    /**
     * @notice A struct containing giveaway infos.
     *
     * @param reward The amount of reward to give to the winner.
     * @param address The list of users registered to the giveaway.
     * @param giveawayClosed The giveawayClosed state.
     */
    struct GiveawayInfos {
        address rewardCurrency;
        uint256 rewardAmount;
        address[] usersRegistered;
        bool giveawayClosed;
    }
}