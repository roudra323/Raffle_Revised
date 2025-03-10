// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// Foundry imports
import {Test} from "forge-std/Test.sol"; // The Test contract provides testing utilities and assertions
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Vm} from "forge-std/Vm.sol"; // Virtual Machine interface for cheatcodes
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

// Test contract inherits from Foundry's Test contract to get access to testing utilities
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

    // Using Foundry's makeAddr cheatcode to create a deterministic address for testing
    // This creates a labeled address with a private key that can be used with prank
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    // Events are declared here to be used with vm.expectEmit()
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    // The setUp function is a special Foundry function that runs before each test
    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();

        // vm is a special object provided by Foundry that gives access to cheatcodes
        // vm.deal gives ETH to an address
        vm.deal(PLAYER, STARTING_USER_BALANCE);

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        entranceFee = config.raffleEntranceFee;
        interval = config.automationUpdateInterval;
        vrfCoordinator = config.vrfCoordinatorV2_5;
        keyHash = config.gasLane;
        subId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
    }

    // In Foundry, test functions must start with "test_"
    // Functions with "view" are read-only and don't modify state
    function test_RaffleInitializesInOpenState() public view {
        // Foundry's assert is used for boolean checks
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function test_RaffleRevertsWhenYouDontSendEnoughEth() public {
        // vm.prank sets msg.sender for the next transaction
        vm.prank(PLAYER);

        // vm.expectRevert checks that the next call reverts with a specific error
        // The .selector converts the error to its function selector (first 4 bytes of the error signature)
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function test_RaffleStoresPlayerAddressIfEnteredCorrectly() public {
        // Arrange section: Set up the test conditions
        vm.prank(PLAYER);

        // Act section: Perform the action being tested
        // Use the {} syntax to send ETH with a function call
        raffle.enterRaffle{value: entranceFee}();

        // Assert section: Check the results
        address playerRecorded = raffle.getPlayer(0);
        // assertEq compares values and provides a clearer error message than assert
        assertEq(playerRecorded, PLAYER);
    }

    function test_EnteringRaffleEmitsEvent() public {
        vm.prank(PLAYER);

        // vm.expectEmit checks that the next call emits a specific event
        // Parameters: (topic1Check, topic2Check, topic3Check, dataCheck, emitter)
        // Here, only checking the first topic (indexed parameter) and the emitter address
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER); // The event signature we expect

        raffle.enterRaffle{value: entranceFee}();
    }

    // This test uses a custom modifier 'raffleEntered' to set up the test state
    function test_DontAllowPlayersWhileRaffleIsCalculating() public raffleEntered {
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    /*//////////////////////////////////////////////////////////////
                              CHECK UPKEEP
    //////////////////////////////////////////////////////////////*/

    function test_checkUpKeepReturnsFalseIfBalanceIsZero() public {
        // vm.warp sets the block timestamp
        vm.warp(block.timestamp + interval + 1);
        // vm.roll sets the block number
        vm.roll(block.number + 1);

        // Destructuring the return values from the function call
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function test_checkUpKeepReturnsFalseIfRaffleIsClosed()
        public
        raffleEntered // Using the custom modifier
    {
        raffle.performUpkeep("");

        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    /*//////////////////////////////////////////////////////////////
                             PERFORM UPKEEP
    //////////////////////////////////////////////////////////////*/

    function test_performUpKeepFailsIfUpkeepNeededIsFalse() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // vm.expectRevert with abi.encodeWithSelector allows testing for errors with parameters
        // This is useful for custom errors that take arguments
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpKeepNotNeeded.selector,
                address(raffle).balance,
                raffle.getNumberOfPlayers(),
                Raffle.RaffleState.OPEN
            )
        );
        raffle.performUpkeep("");
    }

    // Custom modifier pattern in Foundry tests
    // This modifier encapsulates common setup code used by multiple tests
    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _; // The underscore represents where the test function code will be executed
    }

    function test_performUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEntered {
        // vm.recordLogs starts recording emitted events
        vm.recordLogs();
        raffle.performUpkeep("");
        // vm.getRecordedLogs retrieves all recorded events
        Vm.Log[] memory entries = vm.getRecordedLogs();
        // Access topics (indexed parameters) from the emitted events
        // topics[0] is the event signature hash, topics[1] is the first indexed parameter
        bytes32 requestId = entries[1].topics[1];

        // Checking that the event signature matches the expected one
        assertEq(entries[1].topics[0], keccak256("RequestedRaffleWinner(uint256)"));
        assert(requestId != 0);
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
    }

    /*//////////////////////////////////////////////////////////////
                          FULLFULL RANDOMWORDS
    //////////////////////////////////////////////////////////////*/

    // Foundry's stateless fuzz testing
    // The parameter _requestId will be randomly generated for each test run
    function test_fullfillRandomWordsCanOnlyBeCalledAfterPerformupkeep(uint256 _requestId) public raffleEntered {
        // Testing that the fulfillRandomWords function reverts when called directly
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(_requestId, address(raffle));
    }

    function test_fullfillRandomWordsPicksAWinnerResetsAndSendsMoney() public raffleEntered {
        // Arrange
        address expectedWinner = address(1);
        uint256 additionalEntrances = 3; // 4 players total
        uint256 startingIndex = 1;

        for (startingIndex; startingIndex <= additionalEntrances; startingIndex++) {
            hoax(address(uint160(startingIndex)), 1 ether);
            raffle.enterRaffle{value: entranceFee}();
        }
        uint256 startingtimeStamp = raffle.getLastTimeStamp();
        uint256 winnerStartingBalance = expectedWinner.balance;
        uint256 lotteryMoney = entranceFee * (additionalEntrances + 1);
        // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        // Assert
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        assert(raffle.getLastTimeStamp() > startingtimeStamp);
        assert(raffle.getRecentWinner() == expectedWinner);
        assert(raffle.getNumberOfPlayers() == 0);
        assert(address(raffle).balance == 0);
        assertEq(expectedWinner.balance, winnerStartingBalance + lotteryMoney);
    }
}
