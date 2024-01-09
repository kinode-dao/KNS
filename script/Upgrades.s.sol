// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script, console } from "forge-std/Script.sol";

import { NDNSRegistryResolver } from "../src/NDNSRegistryResolver.sol";

contract Upgrade is Script {
    function run() public {

        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        NDNSRegistryResolver ndns = NDNSRegistryResolver(vm.envAddress("NDNS_REGISTRY"));

        NDNSRegistryResolver newNDNSRegistryImpl = new NDNSRegistryResolver();

        ndns.upgradeTo(address(newNDNSRegistryImpl));

    }
}