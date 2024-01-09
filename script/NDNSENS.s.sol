// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import { IETHRegistrarController } from "ens-contracts/ethregistrar/IETHRegistrarController.sol";
import { IPriceOracle } from "ens-contracts/ethregistrar/IPriceOracle.sol";

import { BytesUtils } from "../src/lib/BytesUtils.sol";

import { INDNSRegistryResolver } from "../src/interfaces/INDNSRegistryResolver.sol";
import { NDNSEnsExit } from "../src/NDNSEnsExit.sol";
import { NDNSEnsEntry } from "../src/NDNSEnsEntry.sol";

contract EnvironmentAndScript is Script {

    uint ENTRY_RPC = vm.createFork(vm.envString("RPC_GOERLI"));
    uint EXIT_RPC = vm.createFork(vm.envString("RPC_SEPOLIA"));
    uint PRIVKEY = vm.envUint("PRIVATE_KEY");
    INDNSRegistryResolver ndns = INDNSRegistryResolver(vm.envAddress("NDNS_TEST_NDNS_REGISTRY"));
    NDNSEnsExit exit = NDNSEnsExit(vm.envAddress("NDNS_SEPOLIA_ENS_EXIT"));
    NDNSEnsEntry entry = NDNSEnsEntry(payable(vm.envAddress("NDNS_GOERLI_ENS_ENTRY")));
    address ensregistry = vm.envAddress("ENS_GOERLI_REGISTRY");
    address ensnamewrapper = vm.envAddress("ENS_GOERLI_NAME_WRAPPER");

}

contract DeployENSEntry is EnvironmentAndScript 
    { function run() public { } }

contract DeployENSExit is EnvironmentAndScript 
    { function run() public { } }

contract DeployEnsEntryExitPair is EnvironmentAndScript {

    function run() public {

        vm.selectFork(EXIT_RPC);
        vm.startBroadcast(PRIVKEY);
        exit = new NDNSEnsExit(
            address(ndns),
            vm.envAddress("LZ_EP_SEPOLIA"),
            uint16(vm.envUint("LZ_CID_SEPOLIA"))
        );

        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = "eth";
        bytes memory eth = vm.ffi(inputs);

        ndns.registerTLD(eth, address(exit));

        vm.stopBroadcast();
        vm.selectFork(ENTRY_RPC);
        vm.startBroadcast(PRIVKEY);
        entry = new NDNSEnsEntry(
            ensregistry,
            ensnamewrapper,
            vm.envAddress("LZ_EP_GOERLI"),
            uint16(vm.envUint("LZ_CID_GOERLI")),
            address(exit),
            uint16(vm.envUint("LZ_CID_SEPOLIA"))
        );
        address(entry).call{value: .25 ether }("");

        vm.stopBroadcast();
        vm.selectFork(EXIT_RPC);
        vm.startBroadcast(PRIVKEY);
        exit.setEntry(
            address(entry), 
            uint16(vm.envUint("LZ_CID_GOERLI"))
        );

        vm.stopBroadcast();
        vm.selectFork(ENTRY_RPC);
        vm.startBroadcast(PRIVKEY);
        entry.ping();

        inputs[2] = "qutset.testuq.eth";
        bytes memory testuqbar = vm.ffi(inputs);
        uint256 testuqbarnode = uint(BytesUtils.namehash(testuqbar, 0));

        bytes[] memory data = new bytes[](3);
        data[0] = abi.encodeWithSelector
            ( INDNSRegistryResolver.setKey.selector, testuqbarnode, keccak256("yes") );
        data[1] = abi.encodeWithSelector
            ( INDNSRegistryResolver.setIp.selector, testuqbarnode, type(uint128).max );
        data[2] = abi.encodeWithSelector
            ( INDNSRegistryResolver.setWs.selector, testuqbarnode, type(uint16).max );

        entry.setNDNSRecords(
            testuqbar,
            data
        );

        vm.stopBroadcast();

    }
}

contract SetWsForEnsNameOnNDNS is EnvironmentAndScript {
    function run () public {
        vm.selectFork(EXIT_RPC);
        vm.startBroadcast(PRIVKEY);
        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = "uqtesttest.eth";
        bytes memory testuqbarnode = vm.ffi(inputs);
        bytes32 namehash = BytesUtils.namehash(testuqbarnode, 0);
        ndns.setKey(namehash, keccak256("key"));
        ndns.setIp(namehash, type(uint128).max);
        ndns.setWs(namehash, type(uint16).max);
        vm.stopBroadcast();
    }
}

contract CashNDNSEnsEntry is EnvironmentAndScript {
    function run () public {
        vm.selectFork(ENTRY_RPC);
        vm.startBroadcast(PRIVKEY);
        entry.cash();
    }
}

contract SimulateNDNSEnsExit is EnvironmentAndScript {
    function run () public {

        vm.selectFork(EXIT_RPC);

        address from = vm.createWallet(vm.envUint("PRIVATE_KEY")).addr;
        vm.startPrank(from);

        exit = new NDNSEnsExit(
            address(ndns),
            vm.envAddress("LZ_EP_SEPOLIA"),
            uint16(vm.envUint("LZ_CID_SEPOLIA"))
        );

        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = "eth";
        bytes memory eth = vm.ffi(inputs);

        ndns.registerTLD(eth, address(exit));

        exit.simulate(vm.envBytes("PAYLOAD"));

    }
}

contract NameHash is EnvironmentAndScript {
    function run () public {
        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = "eth";
        bytes memory node = vm.ffi(inputs);
        console.log("node", uint(BytesUtils.namehash(node, 0)));
    }

}

contract Thing is EnvironmentAndScript {

    error MyError(address,address);

    function run () public {
        (bool success, bytes memory data) = address(this).call(abi.encodeWithSelector(this.thing.selector));
        if (!success){ 
            console.log("!success"); 
            console.logBytes(data);
            bytes4 selector;
            assembly { selector := mload(add(data, 0x20)) }
            console.logBytes4(selector);
            // (bytes4 sel, address one, address two) = abi.decode(data, (bytes4, address,address));
            (bytes4 sel) = abi.decode(data, (bytes4));
            // console.logBytes4(abi.decode(data, (bytes4,address,address)));
            // console.log("one", one);
            // console.log("two", two);
            // console.log("sel");
            // console.logBytes8(selector);
        }
    }
    function thing () external {

        revert MyError(address(this), address(this));
    }

}