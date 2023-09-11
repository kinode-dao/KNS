// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";

import { QNSRegistry } from "../src/registry/QNSRegistry.sol";

contract QNSTest is Test {

    QNSRegistry public qnsRegistry;

    function setUp() public {

        qnsRegistry = new QNSRegistry();

    }

    function testQNS () public {
        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire.bin";
        inputs[1] = "--to-hex";
        inputs[2] = "abc.def.ghi";

        bytes memory res = vm.ffi(inputs);

        console2.logBytes(res);
        console2.log(string(res));

        inputs[1] = "--from-hex";
        inputs[2] = encodeHexString(res);

        console2.log("encode hex string", encodeHexString(res));

        res = vm.ffi(inputs);

        console2.log(string(res));
        console2.logBytes(res);

    }

    function encodeHexString(bytes memory buffer) public pure returns (string memory) {

        bytes memory converted = new bytes(buffer.length * 2);
        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(converted);
    }

}
