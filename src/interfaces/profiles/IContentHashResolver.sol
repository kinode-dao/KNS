// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IContentHashResolver {
    event ContenthashChanged(uint256 indexed node, bytes hash);

    /**
     * Returns the contenthash associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function contenthash(uint256 node) external view returns (bytes memory);
}
