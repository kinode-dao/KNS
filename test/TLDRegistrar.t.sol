// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";
import { console2 } from "forge-std/console2.sol";

import { TestUtils } from "./Utils.sol";

import { TLDRegistrar } from "../src/TLDRegistrar.sol";

contract TLDShim is TLDRegistrar {

    function mint (address user, uint node) public {
        _mint(user, node);
    }

    function node (uint node) public view returns (bytes32) { 
        return _node(node); 
    }

    function setAttributes(bytes32 _attributes, uint node) public view returns (bytes32) {
        return _setAttributes(_attributes, _node(node));
    }

    function setAttributesWrite(bytes32 _attributes, uint node) public returns (bytes32) {
        return _setNode(_setAttributes(_attributes, _node(node)), node);
    }

    function getAttributes(uint256 node) public view returns (bytes32) {
        return _getAttributes(_node(node));
    }

    function setOwner (address _newOwner, uint node) public view returns (bytes32) {
        return _setOwner(_newOwner, _node(node));
    }

    function setOwnerWrite (address _newOwner, uint node) public returns (bytes32) {
        return _setNode(_setOwner(_newOwner, _node(node)), node);
    }

}

contract TLDRegistrarTest is TestUtils {

    bytes12 constant BYTES12 = 0xFFFFFFFFFFFFFFFFFFFFFFFF;

    uint constant NODE = type(uint).max;
    bytes32 constant ATTRIBUTES1 = 0x0000000000000000000000000000000000000000101010101010101010101010;
    bytes32 constant ATTRIBUTES2 = 0x0000000000000000000000000000000000000000111111111111111111111111;

    TLDShim public tld = new TLDShim();

    function setUp() public { 

        tld.mint(address(this), NODE);

    }

    function testTransferFrom () public { 

        bytes32 node = tld.node(NODE);
        address owner = tld.ownerOf(NODE);

        assertEq(owner, address(this), "owner should be this contract");

        tld.transferFrom(address(this), msg.sender, NODE);

        node = tld.node(NODE);
        owner = tld.ownerOf(NODE);

        assertEq(owner, msg.sender, "owner should be msg.sender of test");

    }

    function testSetAttributes () public {

        bytes32 withAttrs1 = tld.setAttributesWrite(ATTRIBUTES1, NODE);
        bytes32 withNewOwner = tld.setOwnerWrite(msg.sender, NODE);
        bytes32 end = tld.node(NODE);

        assertEq(tld.getAttributes(NODE), ATTRIBUTES1, "unexpected attributes");
        assertEq(tld.ownerOf(NODE), msg.sender, "owner should be msg.sender");

    }

}
