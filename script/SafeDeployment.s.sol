// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@safe/safe-contracts/libraries/CreateCall.sol";

import {Script, console} from "forge-std/Script.sol";
import {VmSafe} from "forge-std/Vm.sol";

import {KNSRegistryResolver} from "../src/KNSRegistryResolver.sol";
import {DotOsRegistrar} from "../src/DotOsRegistrar.sol";
import {ITLDRegistrar} from "../src/interfaces/ITLDRegistrar.sol";
import {IKNSRegistryResolver} from "../src/interfaces/IKNSRegistryResolver.sol";
import {BytesUtils} from "../src/lib/BytesUtils.sol";

contract SafeDeployment is Script {
    address CREATE_CALL = 0xB19D6FFc2182150F8Eb585b79D4ABcd7C5640A9d;
    address SAFE = 0xBF7cF30D01AeCb69A34e4173d625b09ea43487d6;

    bytes _KECCAK_UNIQUE = "KNSv1";

    function run() public {
        bytes memory r;

        vm.prank(SAFE);

        bytes memory knsRegistryImplDeploycode = abi.encodeWithSelector(
            CreateCall.performCreate2.selector,
            uint256(0),
            vm.getCode("KNSRegistryResolver.sol:KNSRegistryResolver"),
            keccak256(_KECCAK_UNIQUE)
        );

        console.log("kns reg impl");
        console.logBytes(knsRegistryImplDeploycode);

        (, r) = CREATE_CALL.call(knsRegistryImplDeploycode);
        address knsRegistryImplAddress = abi.decode(r, (address));

        bytes memory knsRegistryProxyDeployCode = abi.encodeWithSelector(
            CreateCall.performCreate2.selector,
            uint256(0),
            abi.encodePacked(
                vm.getCode("ERC1967Proxy.sol:ERC1967Proxy"),
                abi.encode(
                    knsRegistryImplAddress,
                    abi.encodeWithSelector(
                        KNSRegistryResolver.initialize.selector,
                        SAFE
                    )
                )
            ),
            keccak256(_KECCAK_UNIQUE)
        );

        console.log("kns prox addr");
        console.logBytes(knsRegistryProxyDeployCode);

        (, r) = CREATE_CALL.call(knsRegistryProxyDeployCode);
        address knsRegistryAddress = abi.decode(r, (address));

        bytes memory dotOsImplDeployCode = abi.encodeWithSelector(
            CreateCall.performCreate2.selector,
            uint256(0),
            vm.getCode("DotOsRegistrar.sol:DotOsRegistrar"),
            keccak256(_KECCAK_UNIQUE)
        );

        console.log("dot os impl");
        console.logBytes(dotOsImplDeployCode);

        (, r) = CREATE_CALL.call(dotOsImplDeployCode);
        address dotOsImplAddress = abi.decode(r, (address));

        bytes memory dotOsProxyDeployCode = abi.encodeWithSelector(
            CreateCall.performCreate2.selector,
            uint256(0),
            abi.encodePacked(
                vm.getCode("ERC1967Proxy.sol:ERC1967Proxy"),
                abi.encode(
                    dotOsImplAddress,
                    abi.encodeWithSelector(
                        DotOsRegistrar.initialize.selector,
                        knsRegistryAddress,
                        SAFE
                    )
                )
            ),
            keccak256(_KECCAK_UNIQUE)
        );

        console.log("dot os proxy");
        console.logBytes(dotOsProxyDeployCode);

        (, r) = CREATE_CALL.call(dotOsProxyDeployCode);
        address dotOsProxyAddress = abi.decode(r, (address));

        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = "os";
        bytes memory baseNode = vm.ffi(inputs);

        bytes memory setDotOsCallCode = abi.encodeWithSelector(
            KNSRegistryResolver.registerTLD.selector,
            baseNode,
            dotOsProxyAddress
        );

        console.log("set dot os", knsRegistryAddress);
        console.logBytes(setDotOsCallCode);
    }
}

contract VerificationConstructorArgs {
    address SAFE = 0x8E2f51D2992382080652B86eC7425A7dFC338055;
    address KNS_IMPL = 0x1F2a95Db4927a84978A3A37827c4f7C954bfB32B;
    address KNS_PROXY = 0x6e22E7b9f5a99D5921c14A88Aaf954502aC17B90;
    address DOTOS_IMPL = 0x4C18DDb7fd0c8EaB356fA1dE088a9861ca1A9931;

    function run() public {
        bytes memory knsRegistryConstructorArgs = abi.encode(
            KNS_IMPL,
            abi.encodeWithSelector(
                KNSRegistryResolver.initialize.selector,
                SAFE
            )
        );

        bytes memory dotOsConstructorArgs = abi.encode(
            DOTOS_IMPL,
            abi.encodeWithSelector(
                DotOsRegistrar.initialize.selector,
                KNS_PROXY,
                SAFE
            )
        );

        console.log("kns registry constructor args");
        console.logBytes(knsRegistryConstructorArgs);
        console.log("dot nec constructor args");
        console.logBytes(dotOsConstructorArgs);
    }
}
