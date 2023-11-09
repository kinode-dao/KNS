// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import { IETHRegistrarController } from "ens-contracts/ethregistrar/IETHRegistrarController.sol";
import { IPriceOracle } from "ens-contracts/ethregistrar/IPriceOracle.sol";

contract RegisterArgsAndScript is Script {
    string name = "testuqbar.eth";
    address owner = vm.createWallet(vm.envUint("PRIVATE_KEY")).addr;
    uint256 duration = 31536000;
    bytes32 secret = keccak256("secret");
    address resolver = vm.envAddress("ENS_GOERLI_PUBLIC_RESOLVER");
    bytes[] data;
    bool reverse = false;
    uint16 fuses = 0;
    IETHRegistrarController ethRegistrar =
        IETHRegistrarController(vm.envAddress("ENS_GOERLI_ETH_CONTROLLER"));

}

contract MakeCommitmentForETHName is RegisterArgsAndScript {

    function run() public {

        bytes32 commitment = ethRegistrar.makeCommitment(
            name, owner, duration, secret, resolver, data, reverse, fuses
        );

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        ethRegistrar.commit(commitment);

        vm.stopBroadcast();

    }

}

contract RegisterETHNameFromCommitment is RegisterArgsAndScript {

    function run() public {

        IPriceOracle.Price memory price = ethRegistrar.rentPrice(name, duration);

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        ethRegistrar.register{ value: price.base }(
            name, owner, duration, secret, resolver, data, reverse, fuses
        );

        vm.stopBroadcast();

    }

}