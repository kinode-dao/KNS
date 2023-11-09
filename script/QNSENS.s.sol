// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import { IETHRegistrarController } from "ens-contracts/ethregistrar/IETHRegistrarController.sol";
import { IPriceOracle } from "ens-contracts/ethregistrar/IPriceOracle.sol";

import { QnsEnsExit } from "../src/QnsEnsExit.sol";
import { QnsEnsEntry } from "../src/QnsEnsEntry.sol";

contract EnvironmentAndScript is Script {

    uint ENTRY_RPC = vm.createFork(vm.envString("RPC_GOERLI"));
    uint EXIT_RPC = vm.createFork(vm.envString("RPC_SEPOLIA"));

}

contract DeployENSEntry is EnvironmentAndScript {

    function run() public { }

}

contract DeployENSExit is EnvironmentAndScript {

    function run() public { }

}

contract DeployEnsEntryExitPair is EnvironmentAndScript {

    QnsEnsExit exit;
    QnsEnsEntry entry;

    function run() public {

        vm.selectFork(EXIT_RPC);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        exit = new QnsEnsExit(
            vm.envAddress("LZ_EP_SEPOLIA"),
            uint16(vm.envUint("LZ_CID_SEPOLIA"))
        );

        vm.stopBroadcast();
        vm.selectFork(ENTRY_RPC);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        entry = new QnsEnsEntry(
            vm.envAddress("LZ_EP_GOERLI"),
            uint16(vm.envUint("LZ_CID_GOERLI")),
            address(exit),
            uint16(vm.envUint("LZ_CID_SEPOLIA"))
        );
        address(entry).call{value: .25 ether }("");

        vm.stopBroadcast();
        vm.selectFork(EXIT_RPC);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        exit.setEntry(
            address(entry), 
            uint16(vm.envUint("LZ_CID_GOERLI"))
        );

        vm.stopBroadcast();
        vm.selectFork(ENTRY_RPC);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        entry.ping();

        vm.stopBroadcast();

    }
}