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

error NotAuthorizedToMintName();
error CannotRevokeControlFromTLD();
error NotAuthorized();

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
            ".uq TLD should not be able to control"
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

    function testRegister3LDNameFailsWhenSenderIsNotAuthorizedFor2LD () public {

        bytes memory _fqdn2l = dnsStringToWire("sub.uq");

        uint _2LNodeId = dotuq.register(_fqdn2l, new bytes[](0));

        dotuq.transferFrom(address(this), msg.sender, _2LNodeId);

        bytes memory _fqdn3l = dnsStringToWire("sub.sub.uq");

        vm.expectRevert(NotAuthorizedToMintName.selector);

        dotuq.register(_fqdn3l, new bytes[](0));

    }

    function testRegister3LDNameWhenOwning2LD () public {

        bytes memory _fqdn2l = dnsStringToWire("sub.uq");

        uint _2LNodeId = dotuq.register(_fqdn2l, new bytes[](0));

        bytes memory _fqdn3l = dnsStringToWire("sub.sub.uq");

        uint _3LNodeId = dotuq.register(_fqdn3l, new bytes[](0));

        assertEq(dotuq.ownerOf(_2LNodeId), address(this), "wrong 2l node owner");

        assertEq(dotuq.ownerOf(_3LNodeId), address(this), "wrong 3l node owner");

    }

    function testRegister3LDWhenApprovedFor2LD () public {

        bytes memory _fqdn2l = dnsStringToWire("sub.uq");

        uint _2LNodeId = dotuq.register(_fqdn2l, new bytes[](0));

        dotuq.approve(msg.sender, _2LNodeId);

        bytes memory _fqdn3l = dnsStringToWire("sub.sub.uq");

        vm.prank(msg.sender);

        uint _3LNodeId = dotuq.register(_fqdn3l, new bytes[](0));

        assertEq(dotuq.ownerOf(_2LNodeId), address(this), "wrong 2l node owner");

        assertEq(dotuq.ownerOf(_3LNodeId), msg.sender, "wrong 3l node owner");

    }

    function test2LDCanRelinquishControlOf3LD () public {

        bytes memory _fqdn2l = dnsStringToWire("sub.uq");

        uint _2LNodeId = dotuq.register(_fqdn2l, new bytes[](0));

        bytes memory _fqdn3l = dnsStringToWire("sub.sub.uq");

        uint _3LNodeId = dotuq.register(_fqdn3l, new bytes[](0));

        bytes32 _3LDNode = dotuq.getNode(_3LNodeId);

        assertEq(
            _3LDNode & PARENT_CANNOT_CONTROL, 
            bytes32(0),
            "3LD node should be controllable by parent before revocation"
        );

        dotuq.revokeControlOverSubdomain(_fqdn3l);

        _3LDNode = dotuq.getNode(_3LNodeId);

        assertEq(
            _3LDNode & PARENT_CANNOT_CONTROL, 
            PARENT_CANNOT_CONTROL,
            "3LD node should have parent control revoked"
        );

    }

    function test3LDCanNotCompel2LDToRelinquish () public {

        bytes memory _fqdn2l = dnsStringToWire("sub.uq");

        uint _2LNodeId = dotuq.register(_fqdn2l, new bytes[](0));

        bytes memory _fqdn3l = dnsStringToWire("sub.sub.uq");

        uint _3LNodeId = dotuq.register(_fqdn3l, new bytes[](0));

        dotuq.transferFrom(
            address(this),
            msg.sender,
            _3LNodeId
        );

        vm.prank(msg.sender);

        vm.expectRevert(NotAuthorized.selector);

        dotuq.revokeControlOverSubdomain(_fqdn3l);

        // _3LDNode = dotuq.getNode(_3LNodeId);

        // assertEq(
        //     _3LDNode & PARENT_CANNOT_CONTROL, 
        //     PARENT_CANNOT_CONTROL,
        //     "3LD node should have parent control revoked"
        // );

    }


    function testQNSAuthsWhenChangingRecord () public {

        bytes memory _fqdn = dnsStringToWire("sub.uq");

        uint _nodeId = dotuq.register(_fqdn, new bytes[](0));

        qns.setKey(bytes32(_nodeId), keccak256("key"));

        assertEq(qns.key(bytes32(_nodeId)), keccak256("key"));

    }

    function testQNSAuthsWhenChanging3LDRecordFrom2LD () public {

        bytes memory _fqdn2l = dnsStringToWire("sub.uq");

        uint _2LNodeId = dotuq.register(_fqdn2l, new bytes[](0));

        bytes memory _fqdn3l = dnsStringToWire("sub.sub.uq");

        uint _3LNodeId = dotuq.register(_fqdn3l, new bytes[](0));

        dotuq.transferFrom(address(this), msg.sender, _2LNodeId);

        vm.prank(msg.sender);

        qns.setKey(bytes32(_3LNodeId), keccak256("key"));

        assertEq(qns.key(bytes32(_3LNodeId)), keccak256("key"));

    }

}
