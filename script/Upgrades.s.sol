// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script, console } from "forge-std/Script.sol";

import { QNSRegistryResolver } from "../src/QNSRegistryResolver.sol";

contract Upgrade is Script {
    function run() public {

        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        QNSRegistryResolver qns = QNSRegistryResolver(vm.envAddress("QNS_REGISTRY"));

        QNSRegistryResolver newQnsRegistryImpl = new QNSRegistryResolver();

        qns.upgradeTo(address(newQnsRegistryImpl));

    }
}