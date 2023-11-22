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
}

contract TLDRegistrarTest is TestUtils {

    uint NODE = type(uint).max;

    TLDShim public tld = new TLDShim();

    function setUp() public { 

        tld.mint(address(this), NODE);

    }

    function testTransferWorks () public { 

        bytes32 node = tld.node(NODE);
        address owner = tld.ownerOf(NODE);

        assertEq(owner, address(this), "owner should be this contract");

        tld.transferFrom(address(this), msg.sender, NODE);

        node = tld.node(NODE);
        owner = tld.ownerOf(NODE);

        assertEq(owner, msg.sender, "owner should be msg.sender of test");

    }

}
