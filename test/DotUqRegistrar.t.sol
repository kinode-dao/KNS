// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";
import { console2 } from "forge-std/console2.sol";

import { DotUqShim, User, TestUtils } from "./Utils.sol";

import { DotUqRegistrar } from "../src/DotUqRegistrar.sol";
import { QNSRegistryResolver } from "../src/QNSRegistryResolver.sol"; 


contract DotUqTest is TestUtils {

    QNSRegistryResolver public qns = new QNSRegistryResolver();

    uint256 constant public NODE = type(uint).max;
    bytes32 constant public ATTRIBUTES1 = 0x0000000000000000000000000000000000000000101010101010101010101010;
    bytes32 constant public ATTRIBUTES2 = 0x0000000000000000000000000000000000000000111111111111111111111111;

    DotUqShim public dotUq = new DotUqShim();

    function setUp() public { 

        qns.initialize();
        qns.registerTLD(dnsStringToWire("uq"), address(dotUq));

    }

    function testSetupWasCorrect () public {

    }

    function testThis () public {

    }

}
