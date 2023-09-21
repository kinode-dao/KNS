// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { Script, console } from "forge-std/Script.sol";

import { QNSRegistry } from "../src/QNSRegistry.sol";
import { UqNFT } from "../src/UqNFT.sol";

contract QNSScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        QNSRegistry qnsRegistryImpl = new QNSRegistry();

        QNSRegistry qnsRegistry = QNSRegistry(
            address(
                new ERC1967Proxy(
                    address(qnsRegistryImpl),
                    abi.encodeWithSelector(
                        QNSRegistry.initialize.selector
                    )
                )
            )
        );

        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = "uq";
        bytes memory baseNode = vm.ffi(inputs);

        UqNFT uqNftImpl = new UqNFT();
        UqNFT uqNft = UqNFT(
            address(
                new ERC1967Proxy(
                    address(uqNftImpl),
                    abi.encodeWithSelector(
                        UqNFT.initialize.selector,
                        qnsRegistry,
                        baseNode
                    )
                )
            )
        );

        qnsRegistry.registerSubdomainContract(
            baseNode,
            address(uqNft)
        );
    }
}