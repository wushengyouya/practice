// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HackQuest.sol";
import "../src/HQKitty.sol";
import "../src/StakeSystem.sol";

contract StakeSystemScript is Script {
    function run() external {
        vm.startBroadcast();
        HackQuest hackQuest = new HackQuest();
        HQKitty hqk = new HQKitty();
        new StakeSystem(hqk, hackQuest);
        vm.stopBroadcast();
    }
}
