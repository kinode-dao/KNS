// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";
import { console2 } from "forge-std/console2.sol";

import { User, TLDShim, TestUtils } from "./Utils.sol";

import { ITLDRegistrar } from "../src/interfaces/ITLDRegistrar.sol";

import { QNSRegistryResolver } from "../src/QNSRegistryResolver.sol";
import { TLDRegistrar } from "../src/TLDRegistrar.sol";
import { BytesUtils } from "../src/lib/BytesUtils.sol";

error TLD401();

contract TLDRegistrarTest is TestUtils {

    using BytesUtils for bytes;

    bytes12 constant public BYTES12 = 0xFFFFFFFFFFFFFFFFFFFFFFFF;

    uint constant public NODE = type(uint).max;
    bytes32 constant public ATTRIBUTES1 = 0x0000000000000000000000000000000000000000101010101010101010101010;
    bytes32 constant public ATTRIBUTES2 = 0x0000000000000000000000000000000000000000111111111111111111111111;

    TLDShim public tld = new TLDShim();
    QNSRegistryResolver qns = new QNSRegistryResolver();
    User public webmaster = new User(address(qns), address(0), address(tld));
    User public operator = new User(address(qns), address(0), address(tld));
    User public approved = new User(address(qns), address(0), address(tld));

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

        uint _nodeId = registerNodeAndMintToken();

        (ITLDRegistrar _tld, ) = qns.nodes(bytes32(_nodeId));

        assertEq(address(_tld), address(tld), "wrong QNS node tld");

        bytes32 tldNode = tld.getNode(_nodeId);

        assertEq(tldNode, bytes32(uint(uint160(address(this))) << 96),
            "tldNode should be equal to msg.sender with no attributes");

    }

    function testRegisteringNodeMintsTokenAndSetsRecords () public {

    }

    function registerNodeAndMintToken () public returns (uint256) {

        bytes memory fqdn = dnsStringToWire("sub.tld");

        return tld.register(fqdn, address(this), new bytes[](0));

    }

    function testSettingRecordAuthsForOwnerOfNode () public {

        registerNodeAndMintToken();

        bytes32 node = dnsStringToNode("sub.tld");

        qns.setKey(node, bytes32("key"));

        bytes32 key = qns.key(node);

        assertEq(key, bytes32("key"), "key was not set");

    }

    function testAuthWhenSettingRecordsAsWebmaster () public {

        registerNodeAndMintToken();

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

        registerNodeAndMintToken();

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

        registerNodeAndMintToken();

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

        uint _nodeId = registerNodeAndMintToken();

        bytes32 node = tld.getNode(_nodeId);

        console.logBytes32(node);

        address owner = tld.ownerOf(_nodeId);

        assertEq(owner, address(this), "owner should be this contract");

        tld.transferFrom(address(this), msg.sender, _nodeId);

        node = tld.getNode(_nodeId);

        owner = tld.ownerOf(_nodeId);

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
