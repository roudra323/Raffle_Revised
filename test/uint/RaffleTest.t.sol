// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    // vrf values
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 keyHash;
    uint256 subId;
    uint32 callbackGasLimit;

    // Mock addresses
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        vm.deal(PLAYER, STARTING_USER_BALANCE);

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        entranceFee = config.raffleEntranceFee;
        interval = config.automationUpdateInterval;
        vrfCoordinator = config.vrfCoordinatorV2_5;
        keyHash = config.gasLane;
        subId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
    }

    function test_RaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function test_RaffleRevertsWhenYouDontSendEnoughEth() public {
        //Arrange
        vm.prank(PLAYER);
        //Act
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector); // custom error
        raffle.enterRaffle();
    }

    function test_RaffleStoresPlayerAddressIfEnteredCorrectly() public {
        //Arrange
        vm.prank(PLAYER);
        //Act
        raffle.enterRaffle{value: entranceFee}();
        //Assert
        address playerRecorded = raffle.getPlayer(0);
        assertEq(playerRecorded, PLAYER);
    }

    function test_EnteringRaffleEmitsEvent() public {
        //Arrange
        vm.prank(PLAYER);
        //Act
        // one indexed value (Topic)
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        //Assert
        raffle.enterRaffle{value: entranceFee}();
    }

    function test_DontAllowPlayersWhileRaffleIsCalculating()
        public
        raffleEntered
    {
        raffle.performUpkeep("");
        //Act / Assert
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector); // custom error

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    /*//////////////////////////////////////////////////////////////
                              CHECK UPKEEP
    //////////////////////////////////////////////////////////////*/

    function test_checkUpKeepReturnsFalseIfBalanceIsZero() public {
        //Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        //Assert
        assert(!upkeepNeeded);
    }

    function test_checkUpKeepReturnsFalseIfRaffleIsClosed()
        public
        raffleEntered
    {
        raffle.performUpkeep("");
        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        //Assert
        assert(!upkeepNeeded);
    }

    /*//////////////////////////////////////////////////////////////
                             PERFORM UPKEEP
    //////////////////////////////////////////////////////////////*/

    function test_performUpKeepFailsIfUpkeepNeededIsFalse() public {
        //Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        //Act
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpKeepNotNeeded.selector,
                address(raffle).balance,
                raffle.getNumberOfPlayers(),
                Raffle.RaffleState.OPEN
            )
        ); // custom error
        raffle.performUpkeep("");
    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function test_performUpkeepUpdatesRaffleStateAndEmitsRequestId()
        public
        raffleEntered
    {
        // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // Assert
        assertEq(
            entries[1].topics[0],
            keccak256("RequestedRaffleWinner(uint256)")
        );
        assert(requestId != 0);
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
    }

    /*//////////////////////////////////////////////////////////////
                          FULLFULL RANDOMWORDS
    //////////////////////////////////////////////////////////////*/

    // stateless fuzz testing
    function test_fullfillRandomWordsCanOnlyBeCalledAfterPerformupkeep(
        uint256 _requestId
    ) public raffleEntered {
        //Act
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            _requestId,
            address(raffle)
        );
    }
}
