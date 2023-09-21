// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";

import { BytesUtils } from "../src/lib/BytesUtils.sol";

contract TestUtils is Test {
    function getDNSWire (string memory name) public returns (bytes memory) {
        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire/target/debug/dnswire";
        inputs[1] = "--to-hex";
        inputs[2] = name;

        return vm.ffi(inputs);
    }

    function getNodeId (string memory name) public returns (uint256) {
        return uint256(BytesUtils.namehash(getDNSWire(name), 0));
    }

    function signMessage(uint256 nodeId) public returns (bytes memory) {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "./sign/sign.js";
        // inputs[2] = toString(nodeId);
        inputs[2] = "1";

        return vm.ffi(inputs);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Special case for 0
        if (value == 0) {
            return "0";
        }
        
        // Calculate the length of the string representation
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp /= 10;
        }
        
        // Allocate memory for the result
        bytes memory result = new bytes(length);
        
        // Construct the string representation
        for (uint256 i = 0; value != 0; i++) {
            result[length - 1 - i] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        
        return string(result);
    }
}