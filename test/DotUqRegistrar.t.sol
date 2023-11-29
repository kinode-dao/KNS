// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";
import { console2 } from "forge-std/console2.sol";

import { DotUqShim, User, TestUtils } from "./Utils.sol";

import { IDotUqRegistrar } from "../src/interfaces/IDotUqRegistrar.sol";
import { DotUqRegistrar } from "../src/DotUqRegistrar.sol";
import { QNSRegistryResolver } from "../src/QNSRegistryResolver.sol"; 

bytes32 constant PARENT_CANNOT_CONTROL = bytes32(uint(1));
bytes32 constant CANNOT_CREATE_SUBDOMAIN = bytes32(uint(2));
bytes32 constant CANNOT_TRANSFER = bytes32(uint(4));

contract DotUqTest is TestUtils {

    bytes32 constant public ATTRIBUTES1 = 0x0000000000000000000000000000000000000000101010101010101010101010;
    bytes32 constant public ATTRIBUTES2 = 0x0000000000000000000000000000000000000000111111111111111111111111;

    QNSRegistryResolver public qns = new QNSRegistryResolver();
    DotUqShim public dotuq = new DotUqShim();

    function setUp() public { 

        dotuq.initialize(address(qns));

        qns.initialize();
        qns.registerTLD(dnsStringToWire("uq"), address(dotuq));

    }

    function testRegister2LDName () public {

        bytes memory _fqdn = dnsStringToWire("sub.uq");

        uint _nodeId = dotuq.register(_fqdn, new bytes[](0));

        bytes32 _node = dotuq.getNode(_nodeId);

        assertEq(
            _node & PARENT_CANNOT_CONTROL, 
            PARENT_CANNOT_CONTROL,
            "Parent cannot control is not set on second level domain name"
        );

        address _owner = dotuq.ownerOf(_nodeId);

        assertEq(_owner, address(this), "owner should be testing contract");

    }

    function testRegister3LDName () public {

        bytes memory _fqdn = dnsStringToWire("sub.sub.uq");

        uint _nodeId = dotuq.register(_fqdn, new bytes[](0));

        bytes32 _node = dotuq.getNode(_nodeId);

        assertEq(
            _node & PARENT_CANNOT_CONTROL, 
            bytes32(0),
            "parent should be able to control"
        );

    }

}
