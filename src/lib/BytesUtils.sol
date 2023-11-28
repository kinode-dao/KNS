//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

library BytesUtils {
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

    function namehash (bytes memory self) internal pure returns (bytes32) {
        return namehash(self, 0);
    }

    function namehashAndTLD(
        bytes memory self
    ) internal pure returns (bytes32, bytes32) { 
        return namehashAndTLDHash(self, 0);
    }

    function namehashAndTLDHash(
        bytes memory self,
        uint256 offset
    ) internal pure returns (bytes32, bytes32) {

        (bytes32 labelhash, uint256 newOffset) = readLabel(self, offset);
        if (labelhash == bytes32(0)) {
            require(offset == self.length - 1, "namehash: Junk at end of name");
            return (bytes32(0), bytes32(0));
        }
        (bytes32 _namehash, bytes32 tldhash) = namehashAndTLDHash(self, newOffset);
        if (tldhash == bytes32(0))
            tldhash = keccak256(abi.encodePacked(bytes32(0), labelhash));
        return (keccak256(abi.encodePacked(_namehash, labelhash)), tldhash);

    }

    function childParentAndTLD(
        bytes memory self
    ) internal pure returns (bytes32, bytes32, bytes32) {
        (bytes32 label, uint256 offset) = readLabel(self);
        (bytes32 parent, bytes32 tld) = namehashAndTLDHash(self, offset);
        return (keccak256(abi.encodePacked(parent, label)), parent, tld);
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

    function readLabel (
        bytes memory self
    ) internal pure returns (bytes32 labelHash, uint256 newIdx) {
        return readLabel(self, 0);
    }

    function labelLen(
        bytes memory self,
        uint256 idx
    ) internal pure returns (
        uint256 len
    ) {
        len = uint256(uint8(self[idx]));
    }

}
