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
    event NodeRegistered(uint256 indexed node, bytes name);

    // Logged whenever a QNS node is created.
    event NewTld(uint256 indexed node, bytes name, address nft);

    // Logged whenever a QNS node's websocket information is updated.
    event WsChanged(
        uint256 indexed node,
        uint32 indexed protocols,
        bytes32 publicKey,
        uint48 ipAndPort,
        bytes32[] routers // TODO maybe string?
    );

    function registerNode (
        bytes calldata fqdn
    ) external;

    function setWsRecord(
        uint256 node,
        bytes32 publicKey,
        uint32 ip,
        uint16 port,
        bytes32[] calldata routers
    ) external;

    function ws(
        uint256 node
    ) external view returns (WsRecord memory);
}
