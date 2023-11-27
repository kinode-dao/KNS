// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";
import { console2 } from "forge-std/console2.sol";

import { TestUtils } from "./Utils.sol";

import { DotUqRegistrar } from "../src/DotUqRegistrar.sol";

contract DotUqShim is DotUqRegistrar {

    function mint (address user, uint _node) public {
        _mint(user, _node);
    }

    function node (uint _node) public view returns (bytes32) { 
        return _getNode(_node); 
    }

    function setAttributes(bytes32 _attributes, uint _node) public view returns (bytes32) {
        return _setAttributes(_attributes, _getNode(_node));
    }

    function setAttributesWrite(bytes32 _attributes, uint _node) public returns (bytes32) {
        return _setNode(_setAttributes(_attributes, _getNode(_node)), _node);
    }

    function getAttributes(uint256 _node) public view returns (bytes32) {
        return _getAttributes(_getNode(_node));
    }

    function setOwner (address _newOwner, uint _node) public view returns (bytes32) {
        return _setOwner(_newOwner, _getNode(_node));
    }

    function setOwnerWrite (address _newOwner, uint _node) public returns (bytes32) {
        return _setNode(_setOwner(_newOwner, _getNode(_node)), _node);
    }

    function fuses () public view {
        _fuses();
    }

}

contract DotUqTest is TestUtils {

    bytes12 constant BYTES12 = 0xFFFFFFFFFFFFFFFFFFFFFFFF;

    uint constant NODE = type(uint).max;
    bytes32 constant ATTRIBUTES1 = 0x0000000000000000000000000000000000000000101010101010101010101010;
    bytes32 constant ATTRIBUTES2 = 0x0000000000000000000000000000000000000000111111111111111111111111;

    DotUqShim public dotUq = new DotUqShim();

    function setUp() public { 

        dotUq.fuses();

    }

    function testThis () public {
        dotUq.fuses();
    }

}
