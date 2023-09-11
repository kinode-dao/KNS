// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IABIResolver {
    event ABIChanged(uint256 indexed node, uint256 indexed contentType);

    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(
        uint256 node,
        uint256 contentTypes
    ) external view returns (uint256, bytes memory);
}
