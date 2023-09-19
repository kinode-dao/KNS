// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {Script, console } from "forge-std/Script.sol";

import { QNSRegistry } from "../src/QNSRegistry.sol";
import { IQNS } from "../src/interfaces/IQNS.sol";

// import { UqRegistrar } from "../src/UqRegistrar.sol";
// import { IQNSRegistrar } from "../src/interfaces/IQNSRegistrar.sol"; // TODO what is this doing here

// import { IWsResolver } from "../src/interfaces/profiles/IWsResolver.sol";

contract QNSScript is Script {
    // TODO all of this will change drastically
    // /*
    //  * @dev Returns the keccak-256 hash of a byte range.
    //  * @param self The byte string to hash.
    //  * @param offset The position to start hashing at.
    //  * @param len The number of bytes to hash.
    //  * @return The hash of the byte range.
    //  */
    // function keccak(
    //     bytes memory self,
    //     uint256 offset,
    //     uint256 len
    // ) internal pure returns (bytes32 ret) {
    //     require(offset + len <= self.length);
    //     assembly {
    //         ret := keccak256(add(add(self, 32), offset), len)
    //     }
    // }

    // /**
    //  * @dev Returns the ENS namehash of a DNS-encoded name.
    //  * @param self The DNS-encoded name to hash.
    //  * @param offset The offset at which to start hashing.
    //  * @return The namehash of the name.
    //  */
    // function namehash(
    //     bytes memory self,
    //     uint256 offset
    // ) internal pure returns (bytes32) {
    //     (bytes32 labelhash, uint256 newOffset) = readLabel(self, offset);
    //     if (labelhash == bytes32(0)) {
    //         require(offset == self.length - 1, "namehash: Junk at end of name");
    //         return bytes32(0);
    //     }
    //     return
    //         keccak256(abi.encodePacked(namehash(self, newOffset), labelhash));
    // }

    // /**
    //  * @dev Returns the keccak-256 hash of a DNS-encoded label, and the offset to the start of the next label.
    //  * @param self The byte string to read a label from.
    //  * @param idx The index to read a label at.
    //  * @return labelhash The hash of the label at the specified index, or 0 if it is the last label.
    //  * @return newIdx The index of the start of the next label.
    //  */
    // function readLabel(
    //     bytes memory self,
    //     uint256 idx
    // ) internal pure returns (bytes32 labelhash, uint256 newIdx) {
    //     require(idx < self.length, "readLabel: Index out of bounds");
    //     uint256 len = uint256(uint8(self[idx]));
    //     if (len > 0) {
    //         labelhash = keccak(self, idx + 1, len);
    //     } else {
    //         labelhash = bytes32(0);
    //     }
    //     newIdx = idx + len + 1;
    // }

    // function setUp() public {}

    // function run() public {
    //     uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    //     address deployerPublicKey = vm.envAddress("PUBLIC_KEY");
    //     vm.startBroadcast(deployerPrivateKey);

    //     QNSRegistry qnsRegistryImpl = new QNSRegistry();

    //     IQNS qnsRegistry = IQNS(
    //         address(
    //             new ERC1967Proxy(
    //                 address(qnsRegistryImpl),
    //                 abi.encodeWithSelector(
    //                     QNSRegistry.initialize.selector
    //                 )
    //             )
    //         )
    //     );

    //     string[] memory inputs = new string[](3);
    //     inputs[0] = "./dnswire/target/debug/dnswire";
    //     inputs[1] = "--to-hex";
    //     inputs[2] = "uq.";
    //     bytes memory res = vm.ffi(inputs);

    //     UqRegistrar baseRegistrarImpl = new UqRegistrar();

    //     IQNSRegistrar baseRegistrar = IQNSRegistrar(
    //         address(
    //             new ERC1967Proxy(
    //                 address(baseRegistrarImpl),
    //                 abi.encodeWithSelector(
    //                     UqRegistrar.initialize.selector,
    //                     qnsRegistry,
    //                     uint(namehash(res, 0)) // TODO I don't think this is correct!!!! I think the basenode is just `.` not `uq.`
    //                 )
    //             )
    //         )
    //     );

    //     PublicResolver publicResolverImpl = new PublicResolver();

    //     PublicResolver publicResolver = PublicResolver(
    //         address(
    //             new ERC1967Proxy(
    //                 address(publicResolverImpl),
    //                 abi.encodeWithSelector(
    //                     PublicResolver.initialize.selector,
    //                     qnsRegistry,
    //                     address(baseRegistrar),
    //                     address(0)
    //                 )
    //             )
    //         )
    //     );

    //     qnsRegistry.setRecord(
    //         res,
    //         address(baseRegistrar),
    //         address(publicResolver)
    //     );

    //     inputs[2] = "foobarbaz.uq.";
    //     res = vm.ffi(inputs);

    //     bytes[] memory resolverSetters = new bytes[](1);

    //     resolverSetters[0] = abi.encodeWithSelector(
    //         IWsResolver.setWs.selector,
    //         uint(namehash(res, 0)),
    //         bytes32(uint(uint160(deployerPublicKey))),
    //         type(uint32).max,
    //         type(uint16).max,
    //         new bytes32[](0)
    //     );

    //     bytes32 commitment = baseRegistrar.makeCommitment(
    //         res,
    //         deployerPublicKey,
    //         keccak256(abi.encodePacked("secret")),
    //         address(publicResolver),
    //         resolverSetters,
    //         false,
    //         type(uint16).max
    //     );

    //     baseRegistrar.commit(commitment);

    //     baseRegistrar.register(
    //         res,
    //         deployerPublicKey,
    //         keccak256(abi.encodePacked("secret")),
    //         address(publicResolver),
    //         resolverSetters,
    //         false,
    //         type(uint16).max
    //     );

    // }

}