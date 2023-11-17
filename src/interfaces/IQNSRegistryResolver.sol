pragma solidity >=0.8.4;

import { ITLDRegistrar } from "./ITLDRegistrar.sol";
import { IMulticallable } from "./IMulticallable.sol";

// Record types
uint32 constant WEBSOCKETS = 1;

uint96 constant KEYED = 1 << 0;
uint96 constant ROUTED = 1 << 1;
uint96 constant IP = 1 << 2;
uint96 constant WS = 1 << 3;
uint96 constant WT = 1 << 4;
uint96 constant TCP = 1 << 5;
uint96 constant UDP = 1 << 6;

interface IQNSRegistryResolver is IMulticallable {

    // QNS node data
    struct Node {
        ITLDRegistrar tld; // contract that controls ownership logic of QNS id
        uint96 records; // room for 96 records
    }

    // Logged whenever a QNS adds/drops support for subdomaining
    event NewTLD(uint256 indexed node, bytes name, address tld);

    // Logged whenever a QNS node is created
    event NodeRegistered(uint256 indexed node, bytes name);

    event KeyUpdate(bytes32 indexed node, bytes32 key);
    event RoutingUpdate(bytes32 indexed node, bytes32[] routers);
    event IpUpdate(bytes32 indexed node, uint128 ip);
    event WsUpdate(bytes32 indexed node, uint16 port);
    event WtUpdate(bytes32 indexed node, uint16 port);
    event TcpUpdate(bytes32 indexed node, uint16 port);
    event UdpUpdate(bytes32 indexed node, uint16 port);

    // externals

    function registerTLDRegistrar(bytes calldata fqdn, ITLDRegistrar registrar) external;

    function registerNode(bytes calldata fqdn) external;

    function setKey(bytes32 node, bytes32 key) external;
    function setRouting(bytes32 node, bytes32[] calldata routers);
    function setIp(bytes32 node, uint128 ip) external;
    function setWs(bytes32 node, uint16 port) external;
    function setWt(bytes32 node, uint16 port) external;
    function setTcp(bytes32 node, uint16 port) external;
    function setUdp(bytes32 node, uint16 port) external;

    //
    // views
    //

    function routing(uint256 node) external returns (uint256[] memory);
    function ip(uint256 node) external returns (uint128);
    function ws(uint256 node) external returns (uint16);
    function wt(uint256 node) external returns (uint16);
    function tcp(uint256 node) external returns (uint16);
    function udp(uint256 node) external returns (uint16);

    function ws(
        uint256 node
    ) external view returns (WsRecord memory);

    function resolve(
        bytes calldata fqdn
    ) external view returns (address);
}
