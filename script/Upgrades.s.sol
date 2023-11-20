// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script, console } from "forge-std/Script.sol";

import { QNSRegistryResolver } from "../src/QNSRegistryResolver.sol";
import { UqNFT } from "../src/UqNFT.sol";

contract Upgrade is Script {
    function run() public {

        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        QNSRegistryResolver qns = QNSRegistryResolver(vm.envAddress("QNS_REGISTRY"));
        UqNFT uqnft = UqNFT(vm.envAddress("UQ_NFT"));

        QNSRegistryResolver newQnsRegistryImpl = new QNSRegistryResolver();
        UqNFT newUqNftImpl = new UqNFT();

        qns.upgradeTo(address(newQnsRegistryImpl));
        uqnft.upgradeTo(address(newUqNftImpl));

    }
}