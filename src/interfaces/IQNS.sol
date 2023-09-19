pragma solidity >=0.8.4;

// Record types
uint32 constant WEBSOCKETS = 1;

interface IQNS {
    // QNS node data
    struct Record {
        // contract that controls ownership logic of QNS id
        address nft;
        // room for 32 protocols
        uint32 protocols;
    }

    // Websocket data associated with a QNS node
    struct WsRecord {
        bytes32 publicKey;
        uint48 ipAndPort;
        bytes32[] routers; // TODO maybe string[] instead?
    }

    // Logged whenever a QNS adds/drops support for a protocol
    event ProtocolsChanged(uint256 indexed node, bytes name, uint32 protocols);

    // Logged whenever a QNS node is created.
    event NewTld(uint256 indexed node, bytes name, address nft);

    // Logged whenever a QNS node's websocket information is updated.
    event WsChanged(
        uint256 indexed node,
        bytes32 publicKey,
        uint48 ipAndPort,
        bytes32[] routers // TODO maybe string?
    );

    function setProtocols(
        bytes calldata fqdn,
        uint32 protocols
    ) external;

    function setWsRecord(
        uint256 node,
        bytes32 _publicKey,
        uint32 _ip,
        uint16 _port,
        bytes32[] calldata _routers
    ) external;

    function ws(
        uint256 node
    ) external view returns (WsRecord memory);
}
