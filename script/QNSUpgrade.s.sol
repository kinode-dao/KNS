// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { Script, console } from "forge-std/Script.sol";

import { QNSRegistry } from "../src/QNSRegistry.sol";
import { UqNFT } from "../src/UqNFT.sol";
import { IQNSNFT } from "../src/interfaces/IQNSNFT.sol";

contract QNSUpgrade is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        QNSRegistry qnsRegistryImpl = new QNSRegistry();

        UqNFT uqNft = new UqNFT();

        // just go on etherscan to `upgradeTo` the implementations deployed here
    }
}