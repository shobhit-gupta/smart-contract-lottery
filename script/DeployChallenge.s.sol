// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18 <0.9.0;

/*=============================================================
 *  This is a quick solution for a challenge to call a
 * contract's method & get an NFT as a reward
 *
 *  >>> IGNORE this file. Instead check DeployRaffle.s.sol
 *=============================================================*/

import {Script, console} from "forge-std/Script.sol";
import {Challenge} from "../src/Challenge.sol";

contract DeployChallenge is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        new Challenge();
        vm.stopBroadcast();
    }
}
