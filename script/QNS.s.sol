// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { Script, console } from "forge-std/Script.sol";

import { QNSRegistryResolver } from "../src/QNSRegistryResolver.sol";
import { UqNFT } from "../src/UqNFT.sol";
import { ITLDRegistrar } from "../src/interfaces/ITLDRegistrar.sol";
import { BytesUtils } from "../src/lib/BytesUtils.sol";

contract QNSScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        QNSRegistryResolver qnsRegistryImpl = new QNSRegistryResolver();

        QNSRegistryResolver qnsRegistry = QNSRegistryResolver(
            address(
                new ERC1967Proxy(
                    address(qnsRegistryImpl),
                    abi.encodeWithSelector(
                        QNSRegistryResolver.initialize.selector
                    )
                )
            )
        );

        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = "uq";
        bytes memory baseNode = vm.ffi(inputs);
        console.logBytes(baseNode);

        UqNFT uqNftImpl = new UqNFT();
        UqNFT uqNft = UqNFT(
            address(
                new ERC1967Proxy(
                    address(uqNftImpl),
                    abi.encodeWithSelector(
                        UqNFT.initialize.selector,
                        qnsRegistry
                    )
                )
            )
        );

        qnsRegistry.registerTLD(baseNode, address(uqNft));
    }
}

contract QNSTest is Script {

    function run () public {

        console.log("?");

        address UQNFT = vm.envAddress("UQNFT");
        address QNS = vm.envAddress("QNS_REGISTRY");
        bytes memory wsPayload = vm.envBytes("WSCD");
        bytes memory regPayload = vm.envBytes("REGCD");

        QNSRegistryResolver newQNS = new QNSRegistryResolver();
        bytes memory newcode = address(newQNS).code;
        vm.etch(QNS, newcode);

        // (bool s, bytes memory r) = QNS.call(wsPayload);

        (bool s, bytes memory r) = UQNFT.call(regPayload);

    }

}

contract SetRouters is Script {

    function run () public {

        address QNS = vm.envAddress("QNS_REGISTRY");

        address UQNFT = vm.envAddress("UQNFT");

        uint32 WS_IP = 2130706433;
        uint16 WS_PORT = 3000;

        string memory node1 = "uqbar-router-11.uq";
        string memory node2 = "uqbar-router-21.uq";
        string memory node3 = "uqbar-router-31.uq";

        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = node1;

        UqNFT nft = UqNFT(UQNFT);

        bytes memory name;
        bytes[] memory records;
        bytes32 node;

        vm.startBroadcast();

        name = vm.ffi(inputs);
        node = BytesUtils.namehash(name, 0);

        records = new bytes[](3);
        records[0] = abi.encodeWithSelector
            ( QNSRegistryResolver.setKey.selector, node, bytes32(0) );
        records[1] = abi.encodeWithSelector
            ( QNSRegistryResolver.setIp.selector, node, WS_IP );
        records[2] = abi.encodeWithSelector
            ( QNSRegistryResolver.setWs.selector, node, WS_PORT );

        nft.register(name, msg.sender, records);

        inputs[2] = node2;
        name = vm.ffi(inputs);
        node = BytesUtils.namehash(name, 0);

        records = new bytes[](3);
        records[0] = abi.encodeWithSelector
            ( QNSRegistryResolver.setKey.selector, node, bytes32(0) );
        records[1] = abi.encodeWithSelector
            ( QNSRegistryResolver.setIp.selector, node, WS_IP );
        records[2] = abi.encodeWithSelector
            ( QNSRegistryResolver.setWs.selector, node, WS_PORT );

        nft.register(name, msg.sender, records);

        inputs[2] = node3;
        name = vm.ffi(inputs);
        node = BytesUtils.namehash(name, 0);

        records = new bytes[](3);
        records[0] = abi.encodeWithSelector
            ( QNSRegistryResolver.setKey.selector, node, bytes32(0) );
        records[1] = abi.encodeWithSelector
            ( QNSRegistryResolver.setIp.selector, node, WS_IP );
        records[2] = abi.encodeWithSelector
            ( QNSRegistryResolver.setWs.selector, node, WS_PORT );

        nft.register(name, msg.sender, records);

        vm.stopBroadcast();

    }
}