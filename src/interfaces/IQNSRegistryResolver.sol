pragma solidity >=0.8.4;

import { ITLDRegistrar } from "./ITLDRegistrar.sol";
import { IMulticallable } from "./IMulticallable.sol";

// Record types
uint32 constant WEBSOCKETS = 1;

uint96 constant KEYED_BIT = 1 << 0;
uint96 constant ROUTED_BIT = 1 << 1;
uint96 constant IP_BIT = 1 << 2;
uint96 constant WS_BIT = 1 << 3;
uint96 constant WT_BIT = 1 << 4;
uint96 constant TCP_BIT = 1 << 5;
uint96 constant UDP_BIT = 1 << 6;

interface IQNSRegistryResolver is IMulticallable {

    // QNS node data
    struct Node {
        ITLDRegistrar tld; // contract that controls ownership logic of QNS id
        uint96 records; // room for 96 records
    }

    struct IP {
        uint128 ip;
        uint16 ws;
        uint16 wt;
        uint16 tcp;
        uint16 udp;
    }

    // Logged whenever a QNS adds/drops support for subdomaining
    event NewTLD(bytes32 indexed node, bytes name, address tld);

    // Logged whenever a QNS node is created
    event NodeRegistered(bytes32 indexed node, bytes name);

    event RecordsCleared(bytes32 indexed node);

    event KeyUpdate(bytes32 indexed node, bytes32 key);
    event RoutingUpdate(bytes32 indexed node, bytes32[] routers);
    event IpUpdate(bytes32 indexed node, uint128 ip);
    event WsUpdate(bytes32 indexed node, uint16 port);
    event WtUpdate(bytes32 indexed node, uint16 port);
    event TcpUpdate(bytes32 indexed node, uint16 port);
    event UdpUpdate(bytes32 indexed node, uint16 port);

    // externals

    function registerTLD(bytes calldata fqdn, address registrar) external;

    function registerNode(bytes calldata fqdn) external returns (bytes32 nodeId);

    function setKey(bytes32 node, bytes32 key) external;
    function setAllIp(bytes32 node, uint128 ip, uint16 ws, uint16 wt, uint16 tcp, uint16 udp) external;
    function setIp(bytes32 node, uint128 ip) external;
    function setWs(bytes32 node, uint16 port) external;
    function setWt(bytes32 node, uint16 port) external;
    function setTcp(bytes32 node, uint16 port) external;
    function setUdp(bytes32 node, uint16 port) external;
    function setRouters
        (bytes32 node, bytes32[] calldata routers) external;

    //
    // views
    //

    function key(bytes32) external view returns (bytes32);
    function routers(bytes32 node) external view returns (bytes32[] memory);
    function ip(bytes32 node) external view returns 
        ( uint128 ip, uint16 ws, uint16 wt, uint16 tcp, uint16 udp);

}
