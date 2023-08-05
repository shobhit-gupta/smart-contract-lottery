// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18 <0.9.0;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";


contract CreateSubscription is Script {
    function createSubscription(address vrfCoordinator, uint256 deployerKey) public returns (uint64) {
        console.log("Creating subscription on chain id: ", block.chainid);

        // On chain
        vm.startBroadcast(deployerKey);
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Your sub id: ", subId);
        console.log("Please update subscriptionId in HelperConfig.s.sol");
        return subId;
    }

    function createSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helper = new HelperConfig();
        (,,address vrfCoordinator,,,,,uint256 deployerKey) = helper.activeNetworkConfig();
        return createSubscription(vrfCoordinator, deployerKey);
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}


contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscription(address vrfCoordinator, uint64 subId, address linkToken, uint256 deployerKey) public {
        console. log ("Funding subscription: ", subId);
        console. log ("Using vrfCoordinator: ", vrfCoordinator);
        console. log ("On ChainID: ", block.chainid);
        if (block.chainid == 31337) {
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(
                subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(deployerKey);
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }

    }

    function fundSubscriptionUsingConfig() public {
        HelperConfig helper = new HelperConfig();
        (,,address vrfCoordinator,,uint64 subId,,address linkToken, uint256 deployerKey) = helper.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subId, linkToken, deployerKey);
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}


contract AddConsumer is Script {
    function addConsumer(address raffle, address vrfCoordinator, uint64 subId, uint256 deployerKey) public {
        console. log ("Adding consumer contract: ", raffle);
        console. log ("Using vrfCoordinator: ", vrfCoordinator);
        console. log ("On ChainID: ", block.chainid);
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, raffle);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helper = new HelperConfig();
        (,,address vrfCoordinator,,uint64 subId,,, uint256 deployerKey) = helper.activeNetworkConfig();
        addConsumer(raffle, vrfCoordinator, subId, deployerKey);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(raffle);
    }

}
