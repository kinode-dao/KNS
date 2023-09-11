// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";

import { QNSRegistry } from "../src/registry/QNSRegistry.sol";
import { FIFSRegistrar } from "../src/registry/FIFSRegsitrar.sol";
import "../src/resolver/PublicResolver.sol";

contract QNSScript is Script {

    /*
     * @dev Returns the keccak-256 hash of a byte range.
     * @param self The byte string to hash.
     * @param offset The position to start hashing at.
     * @param len The number of bytes to hash.
     * @return The hash of the byte range.
     */
    function keccak(
        bytes memory self,
        uint256 offset,
        uint256 len
    ) internal pure returns (bytes32 ret) {
        require(offset + len <= self.length);
        assembly {
            ret := keccak256(add(add(self, 32), offset), len)
        }
    }

    /**
     * @dev Returns the ENS namehash of a DNS-encoded name.
     * @param self The DNS-encoded name to hash.
     * @param offset The offset at which to start hashing.
     * @return The namehash of the name.
     */
    function namehash(
        bytes memory self,
        uint256 offset
    ) internal pure returns (bytes32) {
        (bytes32 labelhash, uint256 newOffset) = readLabel(self, offset);
        if (labelhash == bytes32(0)) {
            require(offset == self.length - 1, "namehash: Junk at end of name");
            return bytes32(0);
        }
        return
            keccak256(abi.encodePacked(namehash(self, newOffset), labelhash));
    }

    /**
     * @dev Returns the keccak-256 hash of a DNS-encoded label, and the offset to the start of the next label.
     * @param self The byte string to read a label from.
     * @param idx The index to read a label at.
     * @return labelhash The hash of the label at the specified index, or 0 if it is the last label.
     * @return newIdx The index of the start of the next label.
     */
    function readLabel(
        bytes memory self,
        uint256 idx
    ) internal pure returns (bytes32 labelhash, uint256 newIdx) {
        require(idx < self.length, "readLabel: Index out of bounds");
        uint256 len = uint256(uint8(self[idx]));
        if (len > 0) {
            labelhash = keccak(self, idx + 1, len);
        } else {
            labelhash = bytes32(0);
        }
        newIdx = idx + len + 1;
    }


    function setUp() public {}

    function run() public {
        vm.startBroadcast(address(this));

        QNSRegistry    qnsRegistry = new QNSRegistry();

        PublicResolver publicResolver = new PublicResolver(
            qnsRegistry, address(0), address(0));

        string[] memory inputs = new string[](3);
        inputs[0] = "./dnswire.bin";
        inputs[1] = "--to-hex";
        inputs[2] = "uq.";
        bytes memory res = vm.ffi(inputs);

        FIFSRegistrar fifsRegistrar = new FIFSRegistrar(
            qnsRegistry,
            uint(namehash(res, 0))
        );

        qnsRegistry.setSubnodeRecord(
            res,
            address(fifsRegistrar),
            address(publicResolver),
            type(uint64).max
        );

        inputs[2] = "bar.uq.";
        res = vm.ffi(inputs);
        fifsRegistrar.register(
            res,
            address(this),
            address(publicResolver),
            type(uint64).max
        );

        uint bardotuq = uint(namehash(res, 0));

        console.log("this", address(this));

        publicResolver.setWs(
            bardotuq,
            bytes32(uint(uint160(address(this)))),
            type(uint32).max,
            type(uint16).max,
            new bytes32[](0)
        );

        vm.stopBroadcast();
    }

}