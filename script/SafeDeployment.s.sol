// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@safe/safe-contracts/libraries/CreateCall.sol";
import "@safe/safe-contracts/libraries/MultiSend.sol";

import { Script, console } from "forge-std/Script.sol";
import { VmSafe } from "forge-std/Vm.sol";

import { QNSRegistryResolver } from "../src/QNSRegistryResolver.sol";
import { DotUqRegistrar } from "../src/DotUqRegistrar.sol";
import { ITLDRegistrar } from "../src/interfaces/ITLDRegistrar.sol";
import { IQNSRegistryResolver } from "../src/interfaces/IQNSRegistryResolver.sol";
import { BytesUtils } from "../src/lib/BytesUtils.sol";

contract SafeDeployment is Script {

    struct Tx {
        uint8 operation; /// operation as a uint8 with 0 for a call or 1 for a delegatecall (=> 1 byte),
        address to; /// to as a address (=> 20 bytes),
        uint256 value; /// value as a uint256 (=> 32 bytes),
        uint256 dataLength; /// data length as a uint256 (=> 32 bytes),
        bytes data; /// data as bytes
    }

    address CREATE_CALL = 0xB19D6FFc2182150F8Eb585b79D4ABcd7C5640A9d;
    address MULTISEND = 0x998739BFdAAdde7C933B942a68053933098f9EDa;
    address SAFE = 0x8E2f51D2992382080652B86eC7425A7dFC338055;

    function run() public {

        bytes memory r;

        vm.prank(SAFE);

        bytes memory qnsRegistryImplDeploycode = abi.encodeWithSelector(
            CreateCall.performCreate2.selector,
            uint256(0),
            vm.getCode("QNSRegistryResolver.sol:QNSRegistryResolver"),
            keccak256("NECTAR")
        );

        console.log("qns reg impl");
        console.logBytes(qnsRegistryImplDeploycode);

        (,bytes memory r) = CREATE_CALL.call(qnsRegistryImplDeploycode);
        address qnsRegistryImplAddress = abi.decode(r, (address));

        bytes memory qnsRegistryProxyDeployCode = abi.encodeWithSelector(
            CreateCall.performCreate2.selector,
            uint256(0),
            abi.encodePacked(
                vm.getCode("ERC1967Proxy.sol:ERC1967Proxy"),
                abi.encode(
                    qnsRegistryImplAddress,
                    abi.encodeWithSelector(QNSRegistryResolver.initialize.selector)
                )
            ),
            keccak256("NECTAR")
        );

        console.log("qns prox addr");
        console.logBytes(qnsRegistryProxyDeployCode);

        (,bytes memory r) = CREATE_CALL.call(qnsRegistryProxyDeployCode);
        address sqnsRegistryAddress = abi.decode(r, (address));

        bytes memory dotUqImplDeployCode = abi.encodeWithSelector(
            CreateCall.performCreate2.selector,
            uint256(0),
            vm.getCode("DotUqRegistrar.sol:DotUqRegistrar"),
            keccak256("NECTAR")
        );

        console.log("dot uq impl");
        console.logBytes(dotUqImplDeployCode);

        txs = abi.encodePacked(txs, abi.encodePacked(
            uint8(1),
            CREATE_CALL,
            uint256(0),
            uint256(dotUqImplDeployCode.length),
            dotUqImplDeployCode
        ));

        (,bytes memory r) = CREATE_CALL.call(dotUqImplDeployCode);
        address dotUqImplAddress = abi.decode(r, (address));

        bytes memory dotUqProxyDeployCode = abi.encodeWithSelector(
            CreateCall.performCreate2.selector,
            uint256(0),
            abi.encodePacked(
                vm.getCode("ERC1967Proxy.sol:ERC1967Proxy"),
                abi.encode(
                    dotUqImplAddress,
                    abi.encodeWithSelector(
                        DotUqRegistrar.initialize.selector,
                        qnsRegistryAddress
                    )
                )
            ),
            keccak256("NECTAR")
        );

        console.log("dot uq proxy");
        console.logBytes(dotUqProxyDeployCode);

        (,bytes memory r) = CREATE_CALL.call(dotUqProxyDeployCode);
        address dotUqProxyAddress = abi.decode(r, (address));

        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = "uq";
        bytes memory baseNode = vm.ffi(inputs);

        bytes memory setDotUqCallCode = abi.encodeWithSelector(
            QNSRegistryResolver.registerTLD.selector,
            baseNode,
            dotUqProxyAddress
        );

        console.log("set dot uq");
        console.logBytes(setDotUqCallCode);

    }
}
