pragma solidity >=0.8.4;

import { IQNSNFT } from "./IQNSNFT.sol";


// Record types
uint32 constant WEBSOCKETS = 1;

interface IQNS {
    // QNS node data
    struct Record {
        // contract that controls ownership logic of QNS id
        address owner;
        // room for 96 protocols
        uint96 protocols;
    }

    // Websocket data associated with a QNS node
    struct WsRecord {
        bytes32 publicKey;
        uint48 ipAndPort;
        bytes32[] routers;
    }

    // Logged whenever a QNS node is created
    event NodeRegistered(uint256 indexed node, bytes name);

    // Logged whenever a QNS adds/drops support for subdomaining
    event NewSubdomainContract(uint256 indexed node, bytes name, address nft);

    // Logged whenever a QNS node's websocket information is updated.
    event WsChanged(
        uint256 indexed node,
        uint96 indexed protocols, // TODO do we need this?
        bytes32 publicKey,
        uint48 ipAndPort,
        bytes32[] routers
    );

    function registerSubdomainContract(
        bytes calldata fqdn,
        IQNSNFT nft
    ) external;

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
