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
import {KNSEnsExit} from "../src/KNSEnsExit.sol";
import {KNSEnsEntry} from "../src/KNSEnsEntry.sol";

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
    address KNS_IMPL = 0x42D0298D742E4084F0DC1284BB87049008B61105; 
    address KNS_PROXY = 0x3807fBD692Aa5c96F1D8D7c59a1346a885F40B1C; 
    address DOTOS_IMPL = 0x76cd096Bd7006D5Bf7F60fB6a237c046C9b6cC24; 

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


contract KnsEnsExitSafeDeployment is Script {

    address CREATE_CALL = 0xB19D6FFc2182150F8Eb585b79D4ABcd7C5640A9d;
    address SAFE = 0x8E2f51D2992382080652B86eC7425A7dFC338055;

    bytes _KECCAK_UNIQUE = "KNSENSv1";

    function run () public {
        bytes memory r;

        bytes memory knsExitImplDeployCode = abi.encodeWithSelector(
            CreateCall.performCreate2.selector,
            uint256(0),
            vm.getCode("KNSEnsExit.sol:KNSEnsExit"),
            keccak256(_KECCAK_UNIQUE)
        );

        console.log("kns exit impl deploy code");
        console.logBytes(knsExitImplDeployCode);

        (, r) = CREATE_CALL.call(knsExitImplDeployCode);
        address knsEnsExitImplAddress = abi.decode(r, (address));

        bytes memory knsExitProxyConstructorArgs = abi.encode(
            knsEnsExitImplAddress,
            abi.encodeWithSelector(
                KNSEnsExit.initialize.selector,
                vm.envAddress("KNS_REGISTRY_SEPOLIA"),
                SAFE,
                vm.envAddress("LZ_EP_SEPOLIA"),
                uint16(vm.envUint("LZ_CID_SEPOLIA"))
            )
        );

        bytes memory knsExitProxyDeployCode = abi.encodeWithSelector(
            CreateCall.performCreate2.selector,
            uint256(0),
            abi.encodePacked(
                vm.getCode("ERC1967Proxy.sol:ERC1967Proxy"),
                knsExitProxyConstructorArgs
            ),
            keccak256(_KECCAK_UNIQUE)
        );

        console.log("kns exit proxy deploy code");
        console.logBytes(knsExitProxyDeployCode);

        (, r) = CREATE_CALL.call(knsExitProxyDeployCode);
        address knsEnsExitProxyAddress = abi.decode(r, (address));

        bytes memory knsEntryConstructorArgs = abi.encode(
            vm.envAddress("ENS_REGISTRY_SEPOLIA"),
            vm.envAddress("ENS_NAME_WRAPPER_SEPOLIA"),
            vm.envAddress("LZ_EP_SEPOLIA"),
            vm.envUint("LZ_CID_SEPOLIA"),
            knsEnsExitProxyAddress,
            vm.envUint("LZ_CID_SEPOLIA")
        );

        bytes memory knsEntryDeployCode = abi.encodeWithSelector(
            CreateCall.performCreate2.selector,
            uint256(0),
            abi.encodePacked(
                vm.getCode("KNSEnsEntry.sol:KNSEnsEntry"),
                knsEntryConstructorArgs
            ),
            keccak256(_KECCAK_UNIQUE)
        );

        console.log("kns entry deploy code");
        console.logBytes(knsEntryDeployCode);

        (, r) = CREATE_CALL.call(knsEntryDeployCode);
        address knsEnsEntryAddress = abi.decode(r, (address));

        IKNSRegistryResolver kns = IKNSRegistryResolver(vm.envAddress("KNS_REGISTRY_SEPOLIA"));

        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = "eth";
        bytes memory baseNode = vm.ffi(inputs);

        bytes memory setDotEthCallCode = abi.encodeWithSelector(
            KNSRegistryResolver.registerTLD.selector,
            baseNode,
            knsEnsExitProxyAddress
        );

        bytes memory setEntryOnExit = abi.encodeWithSelector(
            KNSEnsExit.setEntry.selector,
            knsEnsEntryAddress,
            uint16(vm.envUint("LZ_CID_SEPOLIA"))
        );

        console.log("set eth call code", vm.envAddress("KNS_REGISTRY_SEPOLIA"));
        console.logBytes(setDotEthCallCode);

        console.log("set entry on exit", knsEnsExitProxyAddress);
        console.logBytes(setEntryOnExit);

    }

}