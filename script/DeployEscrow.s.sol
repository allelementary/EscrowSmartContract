// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {Escrow} from "../src/Escrow.sol";

contract DeployEscrow is Script {
    function run() external returns (Escrow) {
        vm.startBroadcast();

        Escrow escrow = new Escrow();

        vm.stopBroadcast();
        return escrow;
    }
}
