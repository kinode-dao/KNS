// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console, console2} from "forge-std/Test.sol";

import "../src/lib/BytesUtils.sol";
import "../src/TLDRegistrar.sol";
import "../src/DotNecRegistrar.sol";
import "../src/NDNSREgistryResolver.sol";

contract TestUtils is Test {

    function dnsStringToWire (string memory name) public returns (bytes memory) {

        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = name;
        return vm.ffi(inputs);

    }

    function dnsStringToNode (string memory name) public returns (bytes32) {
        bytes memory wire = dnsStringToWire(name);
        return BytesUtils.namehash(wire);
    }

    function dnsStringToNodeId (string memory name) public returns (uint256) {
        return uint(dnsStringToNode(name));
    }

    function onERC721Received (address, address,uint256,bytes calldata) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract TLDShim is TLDRegistrar {

    function mint (address user, uint256 _node) public {
        _mint(user, _node);
    }

    function getNode (uint256 _node) public view returns (bytes32) { 
        return _getNode(_node); 
    }

    function setAttributes(bytes32 _attributes, uint256 _node) public view returns (bytes32) {
        return _setAttributes(_attributes, _getNode(_node));
    }

    function setAttributesWrite(bytes32 _attributes, uint256 _node) public returns (bytes32) {
        return _setNode(_setAttributes(_attributes, _getNode(_node)), _node);
    }

    function getAttributes(uint256 _node) public view returns (bytes32) {
        return _getAttributes(_getNode(_node));
    }

    function setOwner (address _newOwner, uint256 _node) public view returns (bytes32) {
        return _setOwner(_newOwner, _getNode(_node));
    }

    function setOwnerWrite (address _newOwner, uint256 _node) public returns (bytes32) {
        return _setNode(_setOwner(_newOwner, _getNode(_node)), _node);
    }

    function init (address _ndns, string memory _name, string memory _symbol) public {
        __TLDRegistrar_init(_ndns, _name, _symbol);
    }

    function register (bytes calldata _name, address _owner, bytes[] calldata _data) external returns (uint256) {
        return _register(_name, _owner, bytes32(0), _data);
    }

    function register (bytes calldata _name, address _owner, bytes32 _attributes, bytes[] calldata _data) external returns (uint256) {
        return _register(_name, _owner, _attributes, _data);
    }

}

contract DotNecShim is DotNecRegistrar {

    function mint (address user, uint _node) public {
        _mint(user, _node);
    }

    function getNode (uint _node) public view returns (bytes32) { 
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

}

contract User {

    TLDShim public tld;
    DotNecShim public dotuq;
    NDNSRegistryResolver public ndns;

    constructor (address _ndns, address _dotuq, address _tld) {
        ndns = NDNSRegistryResolver(_ndns);
        dotuq = DotNecShim(_dotuq);
        tld = TLDShim(_tld);
    }

    function setKey(bytes32 _node, bytes32 _key) public {
        ndns.setKey(_node, _key);
    }

}