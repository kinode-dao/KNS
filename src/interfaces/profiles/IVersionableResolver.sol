// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IVersionableResolver {
    event VersionChanged(uint256 indexed node, uint64 newVersion);

    function recordVersions(uint256 node) external view returns (uint64);
}
