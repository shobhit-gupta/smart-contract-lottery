// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18 <0.9.0;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         EVENTS                             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    event EnteredRaffle(address indexed player);
    event RequestedRaffleWinner(uint256 requestId);
    event PickedWinner(address indexed winner);

    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    Raffle s_raffle;
    HelperConfig s_helper;
    address public s_player = makeAddr("player");

    uint256 s_entranceFee;
    uint256 s_interval;
    address s_vrfCoordinator;
    // bytes32 s_gasLane;
    uint64 s_subscriptionId;
    uint32 s_callbackGasLimit;
    address s_linkToken;
    uint256 s_deployerKey;

    function setUp() external {
        // DeployRaffle deployer = new DeployRaffle();
        // (s_raffle, s_helper) = deployer.run();
        // (
        //     s_entranceFee,
        //     s_interval,
        //     s_vrfCoordinator,
        //     ,
        //     s_subscriptionId,
        //     s_callbackGasLimit,
        //     s_linkToken,
        //     s_deployerKey
        // ) = s_helper.activeNetworkConfig();
        // vm.deal(s_player, STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(s_raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        ENTER RAFFLE                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function test_EnterRaffle_RevertWhen_YouDontPay() public {
        vm.prank(s_player);
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        s_raffle.enterRaffle();
    }

    function test_EnterRaffle_RevertWhen_YouDontPayEnough() public {
        vm.prank(s_player);
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        s_raffle.enterRaffle{value: s_entranceFee - 1}();
    }

    function test_EnterRaffle_ListsPlayer() public {
        vm.prank(s_player);
        s_raffle.enterRaffle{value: s_entranceFee}();
        assertEq(s_raffle.getPlayer(0), s_player);
    }

    function test_EnterRaffle_EmitsEvent() public {
        vm.prank(s_player);
        vm.expectEmit(true, false, false, false, address(s_raffle));
        emit EnteredRaffle(s_player);
        s_raffle.enterRaffle{value: s_entranceFee}();
    }

    function test_EnterRaffle_RevertsWhen_StateNotOpen() public {
        vm.prank(s_player);
        s_raffle.enterRaffle{value: s_entranceFee}();

        // Simulate performUpkeep & thus checkUpkeep
        vm.warp(block.timestamp + s_interval + 1);
        vm.roll(block.number + 1);
        s_raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(s_player);
        s_raffle.enterRaffle{value: s_entranceFee}();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CHECK UPKEEP                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    modifier enteredRaffle() {
        vm.prank(s_player);
        s_raffle.enterRaffle{value: s_entranceFee}();
        _;
    }

    modifier timeHasPassed() {
        vm.warp(block.timestamp + s_interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function test_CheckUpkeep_FalseWhen_BalanceIsZero() public timeHasPassed {
        (bool upkeepNeeded, ) = s_raffle.checkUpkeep("");
        assertFalse(upkeepNeeded);
    }

    function test_CheckUpkeep_FalseWhen_StateNotOpen()
        public
        enteredRaffle
        timeHasPassed
    {
        s_raffle.performUpkeep("");
        (bool upkeepNeeded, ) = s_raffle.checkUpkeep("");
        assertFalse(upkeepNeeded);
    }

    function test_CheckUpkeep_FalseWhen_EnoughTimeHasntPassed()
        public
        enteredRaffle
    {
        vm.warp(block.timestamp + s_interval - 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = s_raffle.checkUpkeep("");
        assertFalse(upkeepNeeded);
    }

    function test_CheckUpkeep_TrueWhen_AllConditionsAreMet()
        public
        enteredRaffle
        timeHasPassed
    {
        (bool upkeepNeeded, ) = s_raffle.checkUpkeep("");
        assertTrue(upkeepNeeded);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       PERFORM UPKEEP                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function test_PerformUpkeep_RunsWhen_CheckUpkeepIsTrue()
        public
        enteredRaffle
        timeHasPassed
    {
        s_raffle.performUpkeep("");
    }

    function test_PerformUpkeep_RevertsWhen_CheckUpkeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        uint256 raffleState = uint256(Raffle.RaffleState.OPEN);
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                raffleState
            )
        );
        s_raffle.performUpkeep("");
    }

    function test_PerformUpkeep_UpdatesRaffleStateAndEmitsEvent()
        public
        enteredRaffle
        timeHasPassed
    {
        vm.recordLogs();
        s_raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        // entries[0] contains RandomWordsRequested event from VRFCordinatorV2.sol
        // entries[1] should contain the redundant event we defined in Raffle.sol
        // entries[1].topics[0] contains the entire event. First topic will be the second element.
        bytes32 requestId = entries[1].topics[1];

        assert(requestId > 0);
        assert(s_raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    FulFill Random Words                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function testFuzz_FulfillRandomWords_CallableOnlyAfterPerformUpkeep(
        uint256 randomRequestId
    ) public enteredRaffle timeHasPassed skipFork {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(s_vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(s_raffle)
        );
    }

    function test_FulfillRandomWords_PicksWinnerResetsAndSendsMoney()
        public
        enteredRaffle
        timeHasPassed
        skipFork
    {
        uint256 additionalEntrants = 5;
        uint256 prizePot = s_entranceFee * (additionalEntrants + 1);

        // i starts from 1 because address(0) might have unintended consequences
        for (uint160 i = 1; i <= additionalEntrants; i++) {
            address player = address(i);
            hoax(player, STARTING_USER_BALANCE);
            s_raffle.enterRaffle{value: s_entranceFee}();
        }

        vm.recordLogs();
        s_raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        uint256 previousLastTimeStamp = s_raffle.getLastTimestamp();

        // pretend to be Chainlink VRF to get random number & pick winner
        VRFCoordinatorV2Mock(s_vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(s_raffle)
        );

        assert(s_raffle.getRecentWinner() != address(0));
        assert(s_raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        assertEq(s_raffle.getNumPlayers(), 0);
        assert(s_raffle.getLastTimestamp() > previousLastTimeStamp);
        assertEq(
            s_raffle.getRecentWinner().balance,
            STARTING_USER_BALANCE + prizePot - s_entranceFee
        );
    }
}
