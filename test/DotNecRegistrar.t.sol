// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";
import { console2 } from "forge-std/console2.sol";

import { BytesUtils } from "../src/lib/BytesUtils.sol";

import { DotNecShim, User, TestUtils } from "./Utils.sol";

import { IDotNecRegistrar } from "../src/interfaces/IDotNecRegistrar.sol";
import { DotNecRegistrar } from "../src/DotNecRegistrar.sol";
import { NDNSRegistryResolver } from "../src/NDNSRegistryResolver.sol"; 

bytes32 constant PARENT_CANNOT_CONTROL = bytes32(uint(1));
bytes32 constant CANNOT_CREATE_SUBDOMAIN = bytes32(uint(2));
bytes32 constant CANNOT_TRANSFER = bytes32(uint(4));

error NotAuthorizedToMintName();
error CannotRevokeControlFromTLD();
error NotAuthorized();
error SecondLevelDomainNot9CharactersOrMore();

contract DotNecTest is TestUtils {
    using BytesUtils for bytes;

    bytes32 constant public ATTRIBUTES1 = 0x0000000000000000000000000000000000000000101010101010101010101010;
    bytes32 constant public ATTRIBUTES2 = 0x0000000000000000000000000000000000000000111111111111111111111111;

    NDNSRegistryResolver public ndns = new NDNSRegistryResolver();
    DotNecShim public dotuq = new DotNecShim();

    function setUp() public { 

        dotuq.initialize(address(ndns), address(this));

        ndns.initialize(address(this));
        ndns.registerTLD(dnsStringToWire("nec"), address(dotuq));

    }

    function testRegister2LDName () public {

        bytes memory _fqdn = dnsStringToWire("sub123abc.nec");

        uint _nodeId = dotuq.register(_fqdn, address(this), new bytes[](0));

        bytes32 _node = dotuq.getNode(_nodeId);

        assertEq(
            _node & PARENT_CANNOT_CONTROL, 
            PARENT_CANNOT_CONTROL,
            ".nec TLD should not be able to control"
        );

        address _owner = dotuq.ownerOf(_nodeId);

        assertEq(_owner, address(this), "owner should be testing contract");

    }

    function testRegister2LDNameFailsWhenLessThan9Characters () public {

        bytes memory _fqdn = dnsStringToWire("12345678.nec");

        vm.expectRevert(SecondLevelDomainNot9CharactersOrMore.selector);

        uint _nodeId = dotuq.register(_fqdn, address(this), new bytes[](0));

    }

    function testRegister3LDName () public {

        bytes memory _fqdn = dnsStringToWire("sub.sub123abc.nec");

        uint _nodeId = dotuq.register(_fqdn, address(this), new bytes[](0));

        bytes32 _node = dotuq.getNode(_nodeId);

        assertEq(
            _node & PARENT_CANNOT_CONTROL, 
            bytes32(0),
            "parent should be able to control"
        );

    }

    function testRegister3LDNameFailsWhenSenderIsNotAuthorizedFor2LD () public {

        bytes memory _fqdn2l = dnsStringToWire("sub123abc.nec");

        uint _2LNodeId = dotuq.register(_fqdn2l, address(this), new bytes[](0));

        dotuq.transferFrom(address(this), msg.sender, _2LNodeId);

        bytes memory _fqdn3l = dnsStringToWire("sub.sub123abc.nec");

        vm.expectRevert(NotAuthorizedToMintName.selector);

        dotuq.register(_fqdn3l, address(this), new bytes[](0));

    }

    function testRegister3LDNameWhenOwning2LD () public {

        bytes memory _fqdn2l = dnsStringToWire("sub123abc.nec");

        uint _2LNodeId = dotuq.register(_fqdn2l, address(this), new bytes[](0));

        bytes memory _fqdn3l = dnsStringToWire("sub.sub123abc.nec");

        uint _3LNodeId = dotuq.register(_fqdn3l, address(this), new bytes[](0));

        assertEq(dotuq.ownerOf(_2LNodeId), address(this), "wrong 2l node owner");

        assertEq(dotuq.ownerOf(_3LNodeId), address(this), "wrong 3l node owner");

    }

    function testRegister3LDWhenApprovedFor2LD () public {

        bytes memory _fqdn2l = dnsStringToWire("sub123abc.nec");

        uint _2LNodeId = dotuq.register(_fqdn2l, address(this), new bytes[](0));

        dotuq.approve(msg.sender, _2LNodeId);

        bytes memory _fqdn3l = dnsStringToWire("sub.sub123abc.nec");

        vm.prank(msg.sender);

        uint _3LNodeId = dotuq.register(_fqdn3l, msg.sender, new bytes[](0));

        assertEq(dotuq.ownerOf(_2LNodeId), address(this), "wrong 2l node owner");

        assertEq(dotuq.ownerOf(_3LNodeId), msg.sender, "wrong 3l node owner");

    }

    function test2LDCanRelinquishControlOf3LD () public {

        bytes memory _fqdn2l = dnsStringToWire("sub123abc.nec");

        uint _2LNodeId = dotuq.register(_fqdn2l, address(this), new bytes[](0));

        bytes memory _fqdn3l = dnsStringToWire("sub.sub123abc.nec");

        uint _3LNodeId = dotuq.register(_fqdn3l, address(this), new bytes[](0));

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

        bytes memory _fqdn2l = dnsStringToWire("sub123abc.nec");

        uint _2LNodeId = dotuq.register(_fqdn2l, address(this), new bytes[](0));

        bytes memory _fqdn3l = dnsStringToWire("sub.sub123abc.nec");

        uint _3LNodeId = dotuq.register(_fqdn3l, address(this), new bytes[](0));

        dotuq.transferFrom(
            address(this),
            msg.sender,
            _3LNodeId
        );

        vm.prank(msg.sender);

        vm.expectRevert(NotAuthorized.selector);

        dotuq.revokeControlOverSubdomain(_fqdn3l);

    }


    function testNDNSAuthsWhenChangingRecord () public {

        bytes memory _fqdn = dnsStringToWire("sub123abc.nec");

        uint _nodeId = dotuq.register(_fqdn, address(this), new bytes[](0));

        ndns.setKey(bytes32(_nodeId), keccak256("key"));

        assertEq(ndns.key(bytes32(_nodeId)), keccak256("key"));

    }

    function testNDNSAuthsWhenChanging3LDRecordFrom2LD () public {

        bytes memory _fqdn2l = dnsStringToWire("sub123abc.nec");

        uint _2LNodeId = dotuq.register(_fqdn2l, address(this), new bytes[](0));

        bytes memory _fqdn3l = dnsStringToWire("sub.sub123abc.nec");

        uint _3LNodeId = dotuq.register(_fqdn3l, address(this), new bytes[](0));

        dotuq.transferFrom(address(this), msg.sender, _2LNodeId);

        vm.prank(msg.sender);

        ndns.setKey(bytes32(_3LNodeId), keccak256("key"));

        assertEq(ndns.key(bytes32(_3LNodeId)), keccak256("key"));

    }

    function testRegisterWithRecordData () public {

        bytes memory _fqdn = dnsStringToWire("sub123abc.nec");

        bytes32 _nodeHash = _fqdn.namehash(0);

        bytes32[] memory _routers = new bytes32[](3);
        _routers[0] = keccak256(abi.encodePacked(uint(0)));
        _routers[1] = keccak256(abi.encodePacked(uint(1)));
        _routers[2] = keccak256(abi.encodePacked(uint(2)));

        bytes[] memory _data = new bytes[](7);

        _data[0] = abi.encodeWithSelector(
            NDNSRegistryResolver.setKey.selector,
            _nodeHash, keccak256("key"));

        _data[1] = abi.encodeWithSelector(
            NDNSRegistryResolver.setRouters.selector,
            _nodeHash, _routers);

        _data[2] = abi.encodeWithSelector(
            NDNSRegistryResolver.setIp.selector,
            _nodeHash, type(uint128).max);

        _data[3] = abi.encodeWithSelector(
            NDNSRegistryResolver.setWs.selector,
            _nodeHash, type(uint16).max);

        _data[4] = abi.encodeWithSelector(
            NDNSRegistryResolver.setWt.selector,
            _nodeHash, type(uint16).max); 

        _data[5] = abi.encodeWithSelector(
            NDNSRegistryResolver.setTcp.selector,
            _nodeHash, type(uint16).max);

        _data[6] = abi.encodeWithSelector(
            NDNSRegistryResolver.setUdp.selector,
            _nodeHash, type(uint16).max);

        bytes32 _node = bytes32(dotuq.register(_fqdn, address(this), _data));

        assertEq(dotuq.ownerOf(uint(_node)), address(this), "owner should be testing contract");

        bytes32[] memory _setRouters = ndns.routers(_node);

        assertEq(_setRouters.length, 3, "routers should be set with 3 routers");
        assertEq(_setRouters[0], _routers[0], "unexpected first router");
        assertEq(_setRouters[1], _routers[1], "unexpected second router");
        assertEq(_setRouters[2], _routers[2], "unexpected third router");

        assertEq(ndns.key(_node), keccak256("key"), "key should be set");

        ( uint128 _ip, uint16 _ws, uint16 _wt, uint16 _tcp, uint16 _udp ) = ndns.ip(_node);
        assertEq(_ip, type(uint128).max, "unexpected ip");
        assertEq(_ws, type(uint16).max, "unexpected ws");
        assertEq(_wt, type(uint16).max, "unexpected wt");
        assertEq(_tcp, type(uint16).max, "unexpected tcp");
        assertEq(_udp, type(uint16).max, "unexpected udp");

    }

}
