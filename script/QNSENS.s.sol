// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import { IETHRegistrarController } from "ens-contracts/ethregistrar/IETHRegistrarController.sol";
import { IPriceOracle } from "ens-contracts/ethregistrar/IPriceOracle.sol";

import { QnsEnsExit } from "../src/QnsEnsExit.sol";
import { QnsEnsEntry } from "../src/QnsEnsEntry.sol";

contract DeployENSEntry is Script {

    function run() public {

    }

}

contract DeployENSExit is Script {

    function run() public {

    }

}
