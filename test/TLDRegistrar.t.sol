// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";
import { console2 } from "forge-std/console2.sol";

import { TestUtils } from "./Utils.sol";

import { ITLDRegistrar } from "../src/interfaces/ITLDRegistrar.sol";

import { QNSRegistryResolver } from "../src/QNSRegistryResolver.sol";
import { TLDRegistrar } from "../src/TLDRegistrar.sol";
import { BytesUtils } from "../src/lib/BytesUtils.sol";

error TLD401();

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

    function init (address _qns, string memory _name, string memory _symbol) public {
        __TLDRegistrar_init(_qns, _name, _symbol);
    }

    function register (bytes calldata name, address owner, bytes[] calldata data) external returns (uint256) {
        return _register(name, owner, data);
    }

}

contract User {

    TLDShim public tld;
    QNSRegistryResolver public qns;

    constructor (QNSRegistryResolver _qns, TLDShim _tld) {
        qns = _qns;
        tld = _tld;
    }

    function setKey(bytes32 _node, bytes32 _key) public {
        qns.setKey(_node, _key);
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
    User webmaster = new User(qns, tld);
    User operator = new User(qns, tld);
    User approved = new User(qns, tld);

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

    function testRegisteringNodeMintsToken () public {

        bytes memory fqdn = dnsStringToWire("sub.tld");

        uint256 _nodeId = tld.register(fqdn, address(this), new bytes[](0));

        (ITLDRegistrar _tld, ) = qns.nodes(bytes32(_nodeId));

        assertEq(address(_tld), address(tld), "wrong QNS node tld");

        bytes32 tldNode = tld.getNode(_nodeId);

        assertEq(tldNode, bytes32(uint(uint160(address(this))) << 96),
            "tldNode should be equal to msg.sender with no attributes");

    }

    function testRegisteringNodeMintsTokenAndSetsRecords () public {

    }

    function testSettingRecordAuthsForOwnerOfNode () public {

        testRegisteringNodeMintsToken();

        bytes32 node = dnsStringToNode("sub.tld");

        qns.setKey(node, bytes32("key"));

        bytes32 key = qns.key(node);

        assertEq(key, bytes32("key"), "key was not set");

    }

    function testAuthWhenSettingRecordsAsWebmaster () public {

        testRegisteringNodeMintsToken();

        tld.setWebmaster(address(webmaster), true);

        bytes32 node = dnsStringToNode("sub.tld");

        webmaster.setKey(node, bytes32("key"));

        bytes32 key = qns.key(node);

        assertEq(key, bytes32("key"), "key was not set by webmaster");

        tld.setWebmaster(address(webmaster), false);

        vm.expectRevert(TLD401.selector);

        approved.setKey(node, bytes32(0));

    }

    function testAuthWhenSettingRecordsAsOperator () public {

        testRegisteringNodeMintsToken();

        tld.setApprovalForAll(address(operator), true);

        bytes32 node = dnsStringToNode("sub.tld");

        operator.setKey(node, bytes32("key"));

        bytes32 key = qns.key(node);

        assertEq(key, bytes32("key"), "key was not set by operator");

        tld.setApprovalForAll(address(operator), false);

        vm.expectRevert(TLD401.selector);

        approved.setKey(node, bytes32(0));

    }

    function testAuthWhenSettingRecordsAsApproved () public {

        testRegisteringNodeMintsToken();

        bytes32 node = dnsStringToNode("sub.tld");

        tld.approve(address(approved), uint(node));

        approved.setKey(node, bytes32("key"));

        bytes32 key = qns.key(node);

        assertEq(key, bytes32("key"), "key was not set by approved");

        tld.approve(address(0), uint(node));

        vm.expectRevert(TLD401.selector);

        approved.setKey(node, bytes32(0));

    }

    function testTransferFrom () public { 

        bytes32 node = tld.getNode(NODE);
        address owner = tld.ownerOf(NODE);

        assertEq(owner, address(this), "owner should be this contract");

        tld.transferFrom(address(this), msg.sender, NODE);

        node = tld.getNode(NODE);
        owner = tld.ownerOf(NODE);

        assertEq(owner, msg.sender, "owner should be msg.sender of test");

    }

    function testSetAttributes () public {

        bytes32 withAttrs1 = tld.setAttributesWrite(ATTRIBUTES1, NODE);
        bytes32 withNewOwner = tld.setOwnerWrite(msg.sender, NODE);
        bytes32 end = tld.getNode(NODE);

        assertEq(tld.getAttributes(NODE), ATTRIBUTES1, "unexpected attributes");
        assertEq(tld.ownerOf(NODE), msg.sender, "owner should be msg.sender");

    }

}
