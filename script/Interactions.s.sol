// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubcription is Script {
    function createSubcriptionUsingConfig() public returns (uint256, address) {
        // create subcription
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        (uint256 subId,) = createSubcription(config.vrfCoordinatorV2_5);

        return (subId, config.vrfCoordinatorV2_5);
    }

    function createSubcription(address _vrfCoordinator) public returns (uint256, address) {
        console2.log("Creating Subcription on chain id: ", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(_vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console2.log("Subcription created with id: ", subId);
        console2.log("Please update the subId in the HelperConfig contract");

        return (subId, _vrfCoordinator);
    }

    function run() external {
        createSubcriptionUsingConfig();
    }
}

contract FundSubcription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; // 3 LINK

    function fundSubcriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vftCoordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;

        fundSubcription(vftCoordinator, subscriptionId, linkToken);
    }

    function fundSubcription(address _vrfCoordinator, uint256 _subscriptionId, address _linkToken) public {
        console2.log("Funding subscription:", _subscriptionId);
        console2.log("Using vrfCoordinator:", _vrfCoordinator);
        console2.log("On chainId:", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(_vrfCoordinator).fundSubscription(_subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(_linkToken).transferAndCall(_vrfCoordinator, FUND_AMOUNT, abi.encode(_subscriptionId));
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubcriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeployedContract) public {
        HelperConfig helperConfig = new HelperConfig();
        address vftCoordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;

        addConsumer(mostRecentlyDeployedContract, vftCoordinator, subscriptionId);
    }

    function addConsumer(address contractToAddress, address vrfCoordinator, uint256 subId) public {
        console2.log("Adding consumer to contract:", contractToAddress);
        console2.log("Using vrfCoordinator:", vrfCoordinator);
        console2.log("On chainId:", block.chainid);

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddress);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployedContract = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployedContract);
    }
}
