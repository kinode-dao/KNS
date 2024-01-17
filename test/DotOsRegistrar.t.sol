// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import {console2} from "forge-std/console2.sol";

import {BytesUtils} from "../src/lib/BytesUtils.sol";

import {DotOsShim, User, TestUtils} from "./Utils.sol";

import {IDotOsRegistrar} from "../src/interfaces/IDotOsRegistrar.sol";
import {DotOsRegistrar} from "../src/DotOsRegistrar.sol";
import {KNSRegistryResolver} from "../src/KNSRegistryResolver.sol";

bytes32 constant PARENT_CANNOT_CONTROL = bytes32(uint(1));
bytes32 constant CANNOT_CREATE_SUBDOMAIN = bytes32(uint(2));
bytes32 constant CANNOT_TRANSFER = bytes32(uint(4));

error NotAuthorizedToMintName();
error CannotRevokeControlFromTLD();
error NotAuthorized();
error SecondLevelDomainNot9CharactersOrMore();

contract DotOsTest is TestUtils {
    using BytesUtils for bytes;

    bytes32 public constant ATTRIBUTES1 =
        0x0000000000000000000000000000000000000000101010101010101010101010;
    bytes32 public constant ATTRIBUTES2 =
        0x0000000000000000000000000000000000000000111111111111111111111111;

    KNSRegistryResolver public kns = new KNSRegistryResolver();
    DotOsShim public dotuq = new DotOsShim();

    function setUp() public {
        dotuq.initialize(address(kns), address(this));

        kns.initialize(address(this));
        kns.registerTLD(dnsStringToWire("os"), address(dotuq));
    }

    function testRegister2LDName() public {
        bytes memory _fqdn = dnsStringToWire("sub123abc.os");

        uint _nodeId = dotuq.register(_fqdn, address(this), new bytes[](0));

        bytes32 _node = dotuq.getNode(_nodeId);

        assertEq(
            _node & PARENT_CANNOT_CONTROL,
            PARENT_CANNOT_CONTROL,
            ".os TLD should not be able to control"
        );

        address _owner = dotuq.ownerOf(_nodeId);

        assertEq(_owner, address(this), "owner should be testing contract");
    }

    function testRegister2LDNameFailsWhenLessThan9Characters() public {
        bytes memory _fqdn = dnsStringToWire("12345678.os");

        vm.expectRevert(SecondLevelDomainNot9CharactersOrMore.selector);

        uint _nodeId = dotuq.register(_fqdn, address(this), new bytes[](0));
    }

    function testRegister3LDName() public {
        bytes memory _fqdn = dnsStringToWire("sub.sub123abc.os");

        uint _nodeId = dotuq.register(_fqdn, address(this), new bytes[](0));

        bytes32 _node = dotuq.getNode(_nodeId);

        assertEq(
            _node & PARENT_CANNOT_CONTROL,
            bytes32(0),
            "parent should be able to control"
        );
    }

    function testRegister3LDNameFailsWhenSenderIsNotAuthorizedFor2LD() public {
        bytes memory _fqdn2l = dnsStringToWire("sub123abc.os");

        uint _2LNodeId = dotuq.register(_fqdn2l, address(this), new bytes[](0));

        dotuq.transferFrom(address(this), msg.sender, _2LNodeId);

        bytes memory _fqdn3l = dnsStringToWire("sub.sub123abc.os");

        vm.expectRevert(NotAuthorizedToMintName.selector);

        dotuq.register(_fqdn3l, address(this), new bytes[](0));
    }

    function testRegister3LDNameWhenOwning2LD() public {
        bytes memory _fqdn2l = dnsStringToWire("sub123abc.os");

        uint _2LNodeId = dotuq.register(_fqdn2l, address(this), new bytes[](0));

        bytes memory _fqdn3l = dnsStringToWire("sub.sub123abc.os");

        uint _3LNodeId = dotuq.register(_fqdn3l, address(this), new bytes[](0));

        assertEq(
            dotuq.ownerOf(_2LNodeId),
            address(this),
            "wrong 2l node owner"
        );

        assertEq(
            dotuq.ownerOf(_3LNodeId),
            address(this),
            "wrong 3l node owner"
        );
    }

    function testRegister3LDWhenApprovedFor2LD() public {
        bytes memory _fqdn2l = dnsStringToWire("sub123abc.os");

        uint _2LNodeId = dotuq.register(_fqdn2l, address(this), new bytes[](0));

        dotuq.approve(msg.sender, _2LNodeId);

        bytes memory _fqdn3l = dnsStringToWire("sub.sub123abc.os");

        vm.prank(msg.sender);

        uint _3LNodeId = dotuq.register(_fqdn3l, msg.sender, new bytes[](0));

        assertEq(
            dotuq.ownerOf(_2LNodeId),
            address(this),
            "wrong 2l node owner"
        );

        assertEq(dotuq.ownerOf(_3LNodeId), msg.sender, "wrong 3l node owner");
    }

    function test2LDCanRelinquishControlOf3LD() public {
        bytes memory _fqdn2l = dnsStringToWire("sub123abc.os");

        uint _2LNodeId = dotuq.register(_fqdn2l, address(this), new bytes[](0));

        bytes memory _fqdn3l = dnsStringToWire("sub.sub123abc.os");

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

    function test3LDCanNotCompel2LDToRelinquish() public {
        bytes memory _fqdn2l = dnsStringToWire("sub123abc.os");

        uint _2LNodeId = dotuq.register(_fqdn2l, address(this), new bytes[](0));

        bytes memory _fqdn3l = dnsStringToWire("sub.sub123abc.os");

        uint _3LNodeId = dotuq.register(_fqdn3l, address(this), new bytes[](0));

        dotuq.transferFrom(address(this), msg.sender, _3LNodeId);

        vm.prank(msg.sender);

        vm.expectRevert(NotAuthorized.selector);

        dotuq.revokeControlOverSubdomain(_fqdn3l);
    }

    function testKNSAuthsWhenChangingRecord() public {
        bytes memory _fqdn = dnsStringToWire("sub123abc.os");

        uint _nodeId = dotuq.register(_fqdn, address(this), new bytes[](0));

        kns.setKey(bytes32(_nodeId), keccak256("key"));

        assertEq(kns.key(bytes32(_nodeId)), keccak256("key"));
    }

    function testKNSAuthsWhenChanging3LDRecordFrom2LD() public {
        bytes memory _fqdn2l = dnsStringToWire("sub123abc.os");

        uint _2LNodeId = dotuq.register(_fqdn2l, address(this), new bytes[](0));

        bytes memory _fqdn3l = dnsStringToWire("sub.sub123abc.os");

        uint _3LNodeId = dotuq.register(_fqdn3l, address(this), new bytes[](0));

        dotuq.transferFrom(address(this), msg.sender, _2LNodeId);

        vm.prank(msg.sender);

        kns.setKey(bytes32(_3LNodeId), keccak256("key"));

        assertEq(kns.key(bytes32(_3LNodeId)), keccak256("key"));
    }

    function testRegisterWithRecordData() public {
        bytes memory _fqdn = dnsStringToWire("sub123abc.os");

        bytes32 _nodeHash = _fqdn.namehash(0);

        bytes32[] memory _routers = new bytes32[](3);
        _routers[0] = keccak256(abi.encodePacked(uint(0)));
        _routers[1] = keccak256(abi.encodePacked(uint(1)));
        _routers[2] = keccak256(abi.encodePacked(uint(2)));

        bytes[] memory _data = new bytes[](7);

        _data[0] = abi.encodeWithSelector(
            KNSRegistryResolver.setKey.selector,
            _nodeHash,
            keccak256("key")
        );

        _data[1] = abi.encodeWithSelector(
            KNSRegistryResolver.setRouters.selector,
            _nodeHash,
            _routers
        );

        _data[2] = abi.encodeWithSelector(
            KNSRegistryResolver.setIp.selector,
            _nodeHash,
            type(uint128).max
        );

        _data[3] = abi.encodeWithSelector(
            KNSRegistryResolver.setWs.selector,
            _nodeHash,
            type(uint16).max
        );

        _data[4] = abi.encodeWithSelector(
            KNSRegistryResolver.setWt.selector,
            _nodeHash,
            type(uint16).max
        );

        _data[5] = abi.encodeWithSelector(
            KNSRegistryResolver.setTcp.selector,
            _nodeHash,
            type(uint16).max
        );

        _data[6] = abi.encodeWithSelector(
            KNSRegistryResolver.setUdp.selector,
            _nodeHash,
            type(uint16).max
        );

        bytes32 _node = bytes32(dotuq.register(_fqdn, address(this), _data));

        assertEq(
            dotuq.ownerOf(uint(_node)),
            address(this),
            "owner should be testing contract"
        );

        bytes32[] memory _setRouters = kns.routers(_node);

        assertEq(_setRouters.length, 3, "routers should be set with 3 routers");
        assertEq(_setRouters[0], _routers[0], "unexpected first router");
        assertEq(_setRouters[1], _routers[1], "unexpected second router");
        assertEq(_setRouters[2], _routers[2], "unexpected third router");

        assertEq(kns.key(_node), keccak256("key"), "key should be set");

        (uint128 _ip, uint16 _ws, uint16 _wt, uint16 _tcp, uint16 _udp) = kns
            .ip(_node);
        assertEq(_ip, type(uint128).max, "unexpected ip");
        assertEq(_ws, type(uint16).max, "unexpected ws");
        assertEq(_wt, type(uint16).max, "unexpected wt");
        assertEq(_tcp, type(uint16).max, "unexpected tcp");
        assertEq(_udp, type(uint16).max, "unexpected udp");
    }
}
