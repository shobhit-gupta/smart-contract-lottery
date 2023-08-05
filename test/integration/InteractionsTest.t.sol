// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18 <0.9.0;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract InteractionTest is Test {
    // Skip for this project.
    // Focus primarily on using various Foundry testing features in unit/RaffleTest.t.sol instead.
}
