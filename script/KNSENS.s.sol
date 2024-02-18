// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import {IETHRegistrarController} from "ens-contracts/ethregistrar/IETHRegistrarController.sol";
import {IPriceOracle} from "ens-contracts/ethregistrar/IPriceOracle.sol";

import {BytesUtils} from "../src/lib/BytesUtils.sol";

import {IKNSRegistryResolver} from "../src/interfaces/IKNSRegistryResolver.sol";
import {KNSEnsExit} from "../src/KNSEnsExit.sol";
import {KNSEnsEntry} from "../src/KNSEnsEntry.sol";

contract EnvironmentAndScript is Script {
    uint ENTRY_RPC = vm.createFork(vm.envString("RPC_SEPOLIA"));
    uint EXIT_RPC = vm.createFork(vm.envString("RPC_SEPOLIA"));
    uint PRIVKEY = vm.envUint("PRIVATE_KEY");

    IKNSRegistryResolver kns = IKNSRegistryResolver(vm.envAddress("KNS_REGISTRY_SEPOLIA"));
    KNSEnsExit exit = KNSEnsExit(vm.envAddress("KNS_ENS_EXIT_SEPOLIA"));
    KNSEnsEntry entry = KNSEnsEntry(payable(vm.envAddress("KNS_ENS_ENTRY_SEPOLIA")));

    address ensregistry = vm.envAddress("ENS_REGISTRY_SEPOLIA");
    address ensnamewrapper = vm.envAddress("ENS_NAME_WRAPPER_SEPOLIA");
}

contract DeployENSEntry is EnvironmentAndScript {
    function run() public {}
}

contract DeployENSExit is EnvironmentAndScript {
    function run() public {}
}

contract DeployEnsEntryExitPair is EnvironmentAndScript {
    function run() public {

        vm.selectFork(ENTRY_RPC);
        vm.startBroadcast(PRIVKEY);

        exit = new KNSEnsExit(
            address(kns),
            vm.envAddress("LZ_EP_SEPOLIA"),
            uint16(vm.envUint("LZ_CID_SEPOLIA"))
        );

        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = "eth";
        bytes memory eth = vm.ffi(inputs);

        kns.registerTLD(eth, address(exit));

        entry = new KNSEnsEntry(
            ensregistry,
            ensnamewrapper,
            vm.envAddress("LZ_EP_SEPOLIA"),
            uint16(vm.envUint("LZ_CID_SEPOLIA")),
            address(exit),
            uint16(vm.envUint("LZ_CID_SEPOLIA"))
        );

        address(entry).call{value: .1 ether}("");

        exit.setEntry(address(entry), uint16(vm.envUint("LZ_CID_SEPOLIA")));

        entry.ping();

        inputs[2] = "kinotest.eth";
        bytes memory kinotest = vm.ffi(inputs);
        uint256 kinotestnode = uint(BytesUtils.namehash(kinotest, 0));

        bytes[] memory data = new bytes[](3);
        data[0] = abi.encodeWithSelector(
            IKNSRegistryResolver.setKey.selector,
            kinotestnode,
            keccak256("yes")
        );
        data[1] = abi.encodeWithSelector(
            IKNSRegistryResolver.setIp.selector,
            kinotestnode,
            type(uint128).max
        );
        data[2] = abi.encodeWithSelector(
            IKNSRegistryResolver.setWs.selector,
            kinotestnode,
            type(uint16).max
        );

        entry.setKNSRecords(kinotest, data);

        vm.stopBroadcast();
    }
}

contract SetWsForEnsNameOnKNS is EnvironmentAndScript {
    function run() public {
        vm.selectFork(EXIT_RPC);
        vm.startBroadcast(PRIVKEY);
        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = "kinotest.eth";
        bytes memory kinotestnode = vm.ffi(inputs);
        bytes32 namehash = BytesUtils.namehash(kinotestnode, 0);
        kns.setKey(namehash, keccak256("key"));
        kns.setIp(namehash, type(uint128).max);
        kns.setWs(namehash, type(uint16).max);
        vm.stopBroadcast();
    }
}

contract CashKNSEnsEntry is EnvironmentAndScript {
    function run() public {
        vm.selectFork(ENTRY_RPC);
        vm.startBroadcast(PRIVKEY);
        entry.cash();
    }
}

contract SimulateKNSEnsExit is EnvironmentAndScript {
    function run() public {
        vm.selectFork(EXIT_RPC);

        address from = vm.createWallet(vm.envUint("PRIVATE_KEY")).addr;
        vm.startPrank(from);

        KNSEnsExit code = new KNSEnsExit(
            address(kns),
            vm.envAddress("LZ_EP_SEPOLIA"),
            uint16(vm.envUint("LZ_CID_SEPOLIA"))
        );

        vm.etch(address(exit), address(code).code);

        exit.simulate(vm.envBytes("PAYLOAD"));

    }
}

interface IEndpoint {
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;
}

contract ReplayPayload is EnvironmentAndScript {
    function run() public {
        vm.selectFork(EXIT_RPC);
        vm.startBroadcast(PRIVKEY);

        IEndpoint(vm.envAddress("LZ_EP_SEPOLIA"))
            .retryPayload(
                uint16(vm.envUint("LZ_CID_SEPOLIA")),
                vm.envBytes("SRC_ADDR"),
                vm.envBytes("PAYLOAD")
            );
    }
}

contract NameHash is EnvironmentAndScript {
    function run() public {
        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = "eth";
        bytes memory node = vm.ffi(inputs);
        console.log("node", uint(BytesUtils.namehash(node, 0)));
    }
}
