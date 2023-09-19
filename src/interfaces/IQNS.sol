pragma solidity >=0.8.4;

// Record types
uint32 constant WEBSOCKETS = 1;

interface IQNS {
    // uint32 const WEBSOCKETS = 1;

    // QNS node data
    struct Record {
        address nft;
        uint32 protocols; // uint32 lets us use 32 different protocols...I think that's good enough? TODO
    }

    // Websocket data
    struct WsRecord {
        bytes32 publicKey;
        uint48 ipAndPort;
        bytes32[] routers; // TODO maybe string[] instead?
    }

    // Logged whenever a QNS node's protocol information is updated.
    event ProtocolsChanged(uint256 indexed node, bytes name, uint32 protocols);

    // Logged whenever a QNS node's websocket information is updated.
    event WsChanged(
        uint256 indexed node,
        bytes32 publicKey,
        uint48 ipAndPort,
        bytes32[] routers // TODO maybe string?
    );

    function setRecord(
        bytes calldata node,
        address nft,
        address resolver
    ) external;

    function setWs(
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
