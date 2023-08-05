// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18 <0.9.0;

import {Script, console} from "forge-std/Script.sol";
import {Challenge} from "../src/Challenge.sol";

contract DeployChallenge is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        new Challenge();
        vm.stopBroadcast();
    }
}
