// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import { BytesUtils } from "../src/lib/BytesUtils.sol";

import { IETHRegistrarController } from "ens-contracts/ethregistrar/IETHRegistrarController.sol";
import { IPriceOracle } from "ens-contracts/ethregistrar/IPriceOracle.sol";
import { INameWrapper } from "ens-contracts/wrapper/INameWrapper.sol";

contract EnvironmentAndScript is Script {
    uint PRIVKEY = vm.envUint("PRIVATE_KEY");
    string name = "testuq";
    string subname = "qutset";
    string namesubname = "qutset.testuq";
    string ethname = "testuq.eth";
    address owner = vm.createWallet(PRIVKEY).addr;
    uint256 duration = 31536000;
    bytes32 secret = keccak256("secret");
    address resolver = vm.envAddress("ENS_GOERLI_PUBLIC_RESOLVER");
    bytes[] data;
    bool reverse = false;
    uint16 fuses = 0;

    IETHRegistrarController ethRegistrar =
        IETHRegistrarController(vm.envAddress("ENS_GOERLI_ETH_CONTROLLER"));
    INameWrapper nameWrapper = 
        INameWrapper(vm.envAddress("ENS_GOERLI_NAME_WRAPPER"));
    uint RPC_GOERLI = vm.createFork(vm.envString("RPC_GOERLI"));

    bytes namednswire;
    bytes32 namelabel;
    bytes subnamednswire;
    bytes32 subnamelabel;
    bytes namesubnamednswire;
    bytes ethnamednswire;

    constructor () {
        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = name;
        namednswire = vm.ffi(inputs);
        ( namelabel, ) = BytesUtils.readLabel(namednswire, 0);
        inputs[2] = subname;
        subnamednswire = vm.ffi(inputs);
        ( subnamelabel, ) = BytesUtils.readLabel(namednswire, 0);
        inputs[2] = namesubname;
        namesubnamednswire = vm.ffi(inputs);
        inputs[2] = ethname;
        ethnamednswire = vm.ffi(inputs);
    }
}

contract MakeCommitmentForETHName is EnvironmentAndScript {
    function run() public {

        vm.selectFork(RPC_GOERLI);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        ethRegistrar.commit(ethRegistrar.makeCommitment(
            name, owner, duration, secret, resolver, data, reverse, fuses
        ));
            
        vm.stopBroadcast();

    }
}

contract RegisterETHNameFromCommitment is EnvironmentAndScript {
    function run() public {

        vm.selectFork(RPC_GOERLI);

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        IPriceOracle.Price memory price = ethRegistrar.rentPrice(name, duration);

        ethRegistrar.register{ value: price.base }(
            name, owner, duration, secret, resolver, data, reverse, fuses
        );

        vm.stopBroadcast();

    }
}

contract UnwrapEthName is EnvironmentAndScript {
    function run() public {

        vm.selectFork(RPC_GOERLI);
        vm.broadcast(PRIVKEY);
        nameWrapper.unwrapETH2LD(
            namelabel,
            owner,
            owner
        );

    }
}

contract RegisterSubNodeWithWrapper is EnvironmentAndScript {
    function run () public {
        vm.selectFork(RPC_GOERLI);
        vm.broadcast(PRIVKEY);
        bytes32 node = nameWrapper.setSubnodeOwner(
            BytesUtils.namehash(ethnamednswire, 0),
            subname,
            owner,
            0,
            uint64(duration)
        );

    }
}