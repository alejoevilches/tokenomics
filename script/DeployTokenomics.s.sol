//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Tokenomics} from "src/Tokenomics.sol";

contract DeployTokenomics is Script {
    function run(address treasury) public returns (Tokenomics) {
        vm.startBroadcast();
        Tokenomics tokenomics = new Tokenomics(treasury);
        vm.stopBroadcast();
        return tokenomics;
    }
}
