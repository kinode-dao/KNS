// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console, console2} from "forge-std/Test.sol";

import "../src/lib/BytesUtils.sol";

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