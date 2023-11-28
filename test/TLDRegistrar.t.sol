// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";
import { console2 } from "forge-std/console2.sol";

import { TestUtils } from "./Utils.sol";

import { QNSRegistryResolver } from "../src/QNSRegistryResolver.sol";
import { TLDRegistrar } from "../src/TLDRegistrar.sol";
import { BytesUtils } from "../src/lib/BytesUtils.sol";

contract TLDShim is TLDRegistrar {

    function mint (address user, uint256 _node) public {
        _mint(user, _node);
    }

    function node (uint256 _node) public view returns (bytes32) { 
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

    function init (address _qns, string memory _name, string memory _symbol) public {
        __TLDRegistrar_init(_qns, _name, _symbol);
    }

}

contract TLDRegistrarTest is TestUtils {

    using BytesUtils for bytes;

    bytes12 constant BYTES12 = 0xFFFFFFFFFFFFFFFFFFFFFFFF;

    uint constant NODE = type(uint).max;
    bytes32 constant ATTRIBUTES1 = 0x0000000000000000000000000000000000000000101010101010101010101010;
    bytes32 constant ATTRIBUTES2 = 0x0000000000000000000000000000000000000000111111111111111111111111;

    TLDShim public tld = new TLDShim();
    QNSRegistryResolver qns = new QNSRegistryResolver();

    function setUp() public { 

        qns.initialize();

        tld.init(address(qns), "tld", "tld");

        qns.registerTLD(dnsStringToWire("tld"), address(tld));

    }

    function testTLDRegistrarSetupSuccessful () public {

        bytes memory tldFqdn = dnsStringToWire("tld");
        bytes32 tldHash = tldFqdn.namehash();
        assertEq(tld.TLD_HASH(), tldHash, "unexpected tld hash in setup");
        assertEq(
            keccak256(tld.TLD_DNS_WIRE()), 
            keccak256(tldFqdn),
            "unexpected tld dns wire in setup"
        );

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
