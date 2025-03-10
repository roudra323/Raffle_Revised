// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubcription, FundSubcription, AddConsumer} from "script/Interactions.s.sol";

contract DeployRaffle is Script {
    function deployContract() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            // create subcription
            CreateSubcription createSubcription = new CreateSubcription();
            (config.subscriptionId, config.vrfCoordinatorV2_5) = createSubcription.createSubcriptionUsingConfig();
        }
        console2.log("DeployRaffle___Subcription Id: ", config.subscriptionId);

        // fund subcription
        FundSubcription fundSubcription = new FundSubcription();
        fundSubcription.fundSubcription(config.vrfCoordinatorV2_5, config.subscriptionId, config.link);

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.raffleEntranceFee,
            config.automationUpdateInterval,
            config.vrfCoordinatorV2_5,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );

        vm.stopBroadcast();
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), config.vrfCoordinatorV2_5, config.subscriptionId);

        return (raffle, helperConfig);
    }

    // function run() external returns (Raffle, HelperConfig) {
    //     return deployContract();
    // }
}
