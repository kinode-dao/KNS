// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { Script, console } from "forge-std/Script.sol";
import { VmSafe } from "forge-std/Vm.sol";

import { NDNSRegistryResolver } from "../src/NDNSRegistryResolver.sol";
import { DotNecRegistrar } from "../src/DotNecRegistrar.sol";
import { ITLDRegistrar } from "../src/interfaces/ITLDRegistrar.sol";
import { INDNSRegistryResolver } from "../src/interfaces/INDNSRegistryResolver.sol";
import { BytesUtils } from "../src/lib/BytesUtils.sol";

contract NDNSDotNecScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        NDNSRegistryResolver ndnsRegistryImpl = new NDNSRegistryResolver();

        NDNSRegistryResolver ndnsRegistry = NDNSRegistryResolver(
            address(
                new ERC1967Proxy(
                    address(ndnsRegistryImpl),
                    abi.encodeWithSelector(
                        NDNSRegistryResolver.initialize.selector
                    )
                )
            )
        );

        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = "nec";
        bytes memory baseNode = vm.ffi(inputs);

        DotNecRegistrar dotUqImpl = new DotNecRegistrar();
        DotNecRegistrar dotUq = DotNecRegistrar(
            address(
                new ERC1967Proxy(
                    address(dotUqImpl),
                    abi.encodeWithSelector(
                        DotNecRegistrar.initialize.selector,
                        address(ndnsRegistry)
                    )
                )
            )
        );

        ndnsRegistry.registerTLD(baseNode, address(dotUq));
    }
}

contract NDNSTest is Script {

    function run () public { }

}

contract QueryNode is Script {

    function run () public {

        address NDNS = vm.envAddress("NDNS_REGISTRY");
        address DOTNEC = vm.envAddress("DOT_UQ_REGISTRAR");

        NDNSRegistryResolver ndns = NDNSRegistryResolver(NDNS);
        DotNecRegistrar dotuq = DotNecRegistrar(DOTNEC);

        string memory node1 = "verification.nec";

        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = node1;

        bytes memory name = vm.ffi(inputs);
        bytes32 node = BytesUtils.namehash(name, 0);

        ( uint128 ip, uint16 ws,,,) = ndns.ip(node);
        console.log(ip, ws);

        console.log(dotuq.ownerOf(uint(node)));

    }
}

contract ResetNode is Script {
    function run ( ) public {

        address NDNS = vm.envAddress("NDNS_REGISTRY");
        string memory node1 = "verification.nec";
        uint128 WS_IP = 1111111111;
        uint16 WS_PORT = 1111;
        bytes32 key = bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = node1;
        bytes memory dnsWire = vm.ffi(inputs);
        bytes32 node = BytesUtils.namehash(dnsWire, 0);

        NDNSRegistryResolver ndns = NDNSRegistryResolver(NDNS);

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        bytes[] memory data = new bytes[](3);
        data[0] = abi.encodeWithSelector(NDNSRegistryResolver.setKey.selector, node, key);
        data[1] = abi.encodeWithSelector(NDNSRegistryResolver.setIp.selector, node, WS_IP);
        data[2] = abi.encodeWithSelector(NDNSRegistryResolver.setWs.selector, node, WS_PORT);

        ndns.multicall(data);

        vm.stopBroadcast();

    }
}

contract SetNode is Script {

    function run () public {

        address NDNS = vm.envAddress("NDNS_REGISTRY");

        address DOTNEC = vm.envAddress("DOT_UQ_REGISTRAR");

        uint128 WS_IP = 2130706433;
        uint16 WS_PORT = 3000;

        string memory node1 = "verification.nec";

        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = node1;

        DotNecRegistrar dotuq = DotNecRegistrar(DOTNEC);

        bytes memory name;
        bytes[] memory records;
        bytes32 node;

        VmSafe.Wallet memory wallet = vm.createWallet(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(wallet.privateKey);

        name = vm.ffi(inputs);
        node = BytesUtils.namehash(name, 0);

        records = new bytes[](3);
        records[0] = abi.encodeWithSelector
            ( NDNSRegistryResolver.setKey.selector, node, keccak256("key") );
        records[1] = abi.encodeWithSelector
            ( NDNSRegistryResolver.setIp.selector, node, WS_IP );
        records[2] = abi.encodeWithSelector
            ( NDNSRegistryResolver.setWs.selector, node, WS_PORT );

        dotuq.register(name, wallet.addr, records);

        vm.stopBroadcast();

    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}