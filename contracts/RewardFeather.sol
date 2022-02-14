// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AllBaaam.sol";

contract RewardFeather {
    AllBaaam allBaaam;

    constructor(address _allBaaam) {
        allBaaam = AllBaaam(_allBaaam);
    }

    mapping(address => uint) public rewardTime;

    function rewardFeather() public {
        require(rewardTime[msg.sender] < block.timestamp, "Caller can not get a reward yet.");

        uint totalReward = 0;

        for(uint i = 1; i < allBaaam.owlId(); i++) {
            totalReward = totalReward + (allBaaam.getOwlPower(i) * allBaaam.balanceOf(msg.sender, i));
        }

        require(allBaaam.balanceOf(allBaaam.serviceAddress(), 0) >= totalReward, "Service address lacks FeatherToken.");

        allBaaam.safeTransferFrom(allBaaam.serviceAddress(), msg.sender, 0, totalReward, "");
        uint currentTime = block.timestamp + (60 * 60 * 24);
        rewardTime[msg.sender] = currentTime;
        allBaaam.setTransferLock(msg.sender, currentTime);
    }
}