// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";

import { BytesUtils } from "../src/lib/BytesUtils.sol";

contract TestUtils is Test {

    function encodeHexString(bytes memory buffer) public pure returns (string memory) {
        bytes memory converted = new bytes(buffer.length * 2);
        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(converted);
    }

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

}