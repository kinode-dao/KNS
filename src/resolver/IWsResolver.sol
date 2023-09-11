// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

struct WsRecord {
    bytes32 publicKey;
    uint48 ipAndPort;
    bytes32[] routers; // TODO maybe string?
}


interface IWsResolver {
    event WsChanged(
        bytes32 indexed node,
        bytes32 publicKey,
        uint48 ipAndPort,
        bytes32[] routers // TODO maybe string?
    );

    /**
     * Returns the ws data associated with an ENS node
     * @param node The ENS node to query.
     * @return The associated ws routing information
     */
    function ws(
        bytes32 node
    ) external view returns (WsRecord memory);
}
