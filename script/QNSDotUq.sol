// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { Script, console } from "forge-std/Script.sol";

import { QNSRegistryResolver } from "../src/QNSRegistryResolver.sol";
import { DotUqRegistrar } from "../src/DotUqRegistrar.sol";
import { ITLDRegistrar } from "../src/interfaces/ITLDRegistrar.sol";
import { BytesUtils } from "../src/lib/BytesUtils.sol";

contract QNSDotUqScript is Script {
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

        DotUqRegistrar dotUqImpl = new DotUqRegistrar();
        DotUqRegistrar dotUq = DotUqRegistrar(
            address(
                new ERC1967Proxy(
                    address(dotUqImpl),
                    abi.encodeWithSelector(
                        DotUqRegistrar.initialize.selector,
                        address(qnsRegistry)
                    )
                )
            )
        );

        qnsRegistry.registerTLD(baseNode, address(dotUq));
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

contract QueryRouters is Script {

    function run () public {

        address QNS = vm.envAddress("QNS_REGISTRY");
        address DOTUQ = vm.envAddress("DOT_UQ_REGISTRAR");

        QNSRegistryResolver qns = QNSRegistryResolver(QNS);
        DotUqRegistrar dotuq = DotUqRegistrar(DOTUQ);

        string memory node1 = "uqbar-router-11.uq";
        string memory node2 = "uqbar-router-21.uq";
        string memory node3 = "uqbar-router-31.uq";

        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = node1;

        bytes memory name = vm.ffi(inputs);
        bytes32 node = BytesUtils.namehash(name, 0);

        ( uint128 ip, uint16 ws,,,) = qns.ip(node);
        console.log(ip, ws);
        node = BytesUtils.namehash(name, 0);
        ( ip, ws,,,) = qns.ip(node);
        console.log(ip, ws);

        node = BytesUtils.namehash(name, 0);
        ( ip, ws,,,) = qns.ip(node);
        console.log(ip, ws);

    }
}

contract SetRouters is Script {

    function run () public {

        address QNS = vm.envAddress("QNS_REGISTRY");

        address DOTUQ = vm.envAddress("DOT_UQ_REGISTRAR");

        uint32 WS_IP = 2130706433;
        uint16 WS_PORT = 3000;

        string memory node1 = "uqbar-router-11.uq";
        string memory node2 = "uqbar-router-21.uq";
        string memory node3 = "uqbar-router-31.uq";

        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = node1;

        DotUqRegistrar dotuq = DotUqRegistrar(DOTUQ);

        bytes memory name;
        bytes[] memory records;
        bytes32 node;

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        name = vm.ffi(inputs);
        node = BytesUtils.namehash(name, 0);

        records = new bytes[](3);
        records[0] = abi.encodeWithSelector
            ( QNSRegistryResolver.setKey.selector, node, bytes32(0) );
        records[1] = abi.encodeWithSelector
            ( QNSRegistryResolver.setIp.selector, node, WS_IP );
        records[2] = abi.encodeWithSelector
            ( QNSRegistryResolver.setWs.selector, node, WS_PORT );

        dotuq.register(name, address(this), records);

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

        dotuq.register(name, address(this), records);

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

        dotuq.register(name, address(this), records);

        vm.stopBroadcast();

    }
}