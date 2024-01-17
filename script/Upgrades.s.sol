// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {KNSRegistryResolver} from "../src/KNSRegistryResolver.sol";

contract Upgrade is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        KNSRegistryResolver kns = KNSRegistryResolver(
            vm.envAddress("KNS_REGISTRY")
        );

        KNSRegistryResolver newKNSRegistryImpl = new KNSRegistryResolver();

        kns.upgradeTo(address(newKNSRegistryImpl));
    }
}
