// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";

import { QNSRegistry } from "../src/registry/QNSRegistry.sol";

contract PQIScript is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();

        QNSRegistry qnsRegistry = new QNSRegistry();

        vm.stopBroadcast();
    }

}