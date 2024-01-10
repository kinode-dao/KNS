// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@safe/safe-contracts/libraries/CreateCall.sol";
import "@safe/safe-contracts/libraries/MultiSend.sol";

import { Script, console } from "forge-std/Script.sol";
import { VmSafe } from "forge-std/Vm.sol";

import { NDNSRegistryResolver } from "../src/NDNSRegistryResolver.sol";
import { DotNecRegistrar } from "../src/DotNecRegistrar.sol";
import { ITLDRegistrar } from "../src/interfaces/ITLDRegistrar.sol";
import { INDNSRegistryResolver } from "../src/interfaces/INDNSRegistryResolver.sol";
import { BytesUtils } from "../src/lib/BytesUtils.sol";

contract SafeDeployment is Script {

    address CREATE_CALL = 0xB19D6FFc2182150F8Eb585b79D4ABcd7C5640A9d;
    address MULTISEND = 0x998739BFdAAdde7C933B942a68053933098f9EDa;
    address SAFE = 0x8E2f51D2992382080652B86eC7425A7dFC338055;

    function run() public {

        bytes memory r;

        vm.prank(SAFE);

        bytes memory ndnsRegistryImplDeploycode = abi.encodeWithSelector(
            CreateCall.performCreate2.selector,
            uint256(0),
            vm.getCode("NDNSRegistryResolver.sol:NDNSRegistryResolver"),
            keccak256("NECTAR_OS")
        );

        console.log("ndns reg impl");
        console.logBytes(ndnsRegistryImplDeploycode);

        (,r) = CREATE_CALL.call(ndnsRegistryImplDeploycode);
        address ndnsRegistryImplAddress = abi.decode(r, (address));

        bytes memory ndnsRegistryProxyDeployCode = abi.encodeWithSelector(
            CreateCall.performCreate2.selector,
            uint256(0),
            abi.encodePacked(
                vm.getCode("ERC1967Proxy.sol:ERC1967Proxy"),
                abi.encode(
                    ndnsRegistryImplAddress,
                    abi.encodeWithSelector(
                        NDNSRegistryResolver.initialize.selector,
                        SAFE
                    )
                )
            ),
            keccak256("NECTAR_OS")
        );

        console.log("ndns prox addr");
        console.logBytes(ndnsRegistryProxyDeployCode);

        (,r) = CREATE_CALL.call(ndnsRegistryProxyDeployCode);
        address ndnsRegistryAddress = abi.decode(r, (address));

        bytes memory dotNecImplDeployCode = abi.encodeWithSelector(
            CreateCall.performCreate2.selector,
            uint256(0),
            vm.getCode("DotNecRegistrar.sol:DotNecRegistrar"),
            keccak256("NECTAR_OS")
        );

        console.log("dot nec impl");
        console.logBytes(dotNecImplDeployCode);

        (,r) = CREATE_CALL.call(dotNecImplDeployCode);
        address dotNecImplAddress = abi.decode(r, (address));

        bytes memory dotNecProxyDeployCode = abi.encodeWithSelector(
            CreateCall.performCreate2.selector,
            uint256(0),
            abi.encodePacked(
                vm.getCode("ERC1967Proxy.sol:ERC1967Proxy"),
                abi.encode(
                    dotNecImplAddress,
                    abi.encodeWithSelector(
                        DotNecRegistrar.initialize.selector,
                        ndnsRegistryAddress,
                        SAFE
                    )
                )
            ),
            keccak256("NECTAR_OS")
        );

        console.log("dot nec proxy");
        console.logBytes(dotNecProxyDeployCode);

        (,r) = CREATE_CALL.call(dotNecProxyDeployCode);
        address dotNecProxyAddress = abi.decode(r, (address));

        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = "nec";
        bytes memory baseNode = vm.ffi(inputs);

        bytes memory setDotNecCallCode = abi.encodeWithSelector(
            NDNSRegistryResolver.registerTLD.selector,
            baseNode,
            dotNecProxyAddress
        );

        console.log("set dot nec", ndnsRegistryAddress);
        console.logBytes(setDotNecCallCode);

    }
}


contract VerificationConstructorArgs {

    address SAFE = 0x8E2f51D2992382080652B86eC7425A7dFC338055;
    address NDNS_IMPL = 0x1F2a95Db4927a84978A3A37827c4f7C954bfB32B;
    address NDNS_PROXY = 0x6e22E7b9f5a99D5921c14A88Aaf954502aC17B90;
    address DOTNEC_IMPL = 0x4C18DDb7fd0c8EaB356fA1dE088a9861ca1A9931;

    function run () public {

        bytes memory ndnsRegistryConstructorArgs = abi.encode(
            NDNS_IMPL,
            abi.encodeWithSelector(
                NDNSRegistryResolver.initialize.selector,
                SAFE
            )
        );

        bytes memory dotNecConstructorArgs = abi.encode(
            DOTNEC_IMPL,
            abi.encodeWithSelector(
                DotNecRegistrar.initialize.selector,
                NDNS_PROXY,
                SAFE
            )
        );

        console.log("ndns registry constructor args");
        console.logBytes(ndnsRegistryConstructorArgs);
        console.log("dot nec constructor args");
        console.logBytes(dotNecConstructorArgs);

    }

}