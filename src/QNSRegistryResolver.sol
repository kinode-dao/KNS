// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/IQNSRegistryResolver.sol";
import "./lib/Multicallable.sol";
import "./lib/BytesUtils.sol";

import "forge-std/console.sol";

error MustChooseStaticOrRouted();
error TLDRegistrarOnly();
error TLD401();
error NotTLD();

// TODO lets see what inspiration we can take from VersionableResolver?

contract QNSRegistryResolver is IQNSRegistryResolver, Multicallable, ERC165Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
    using BytesUtils for bytes;

    mapping (bytes32 => address) public TLDs;

    mapping (bytes32 => Node) public nodes;

    mapping (bytes32 => bytes32)   public key;
    mapping (bytes32 => bytes32[]) private _routers;
    mapping (bytes32 => IP) public ip;

    modifier tldAuth (bytes32 node) {
        if (!nodes[node].tld.auth(node, msg.sender)) revert TLD401();
        _;
    }
    
    modifier onlyTLD (Node storage node) {
        if (address(node.tld) != msg.sender) revert TLDRegistrarOnly();
        _;
    }

    function initialize(address _owner) public initializer {
        __UUPSUpgradeable_init();
        _transferOwnership(_owner);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getInitializedVersion() public view 
        returns (uint8) { return _getInitializedVersion(); }

    //
    // externals
    //

    function registerTLD (
        bytes calldata fqdn, 
        address registrar
    ) external {

        _checkOwner();

        ( bytes32 label, uint offset ) = fqdn.readLabel(0);

        if (offset != fqdn.length - 1) revert NotTLD();

        bytes32 tld = _makeNode(bytes32(0), label);

        nodes[tld].tld = ITLDRegistrar(TLDs[tld] = registrar);

        ITLDRegistrar(registrar).__initTLDRegistration(fqdn, tld);

        emit NewTLD(tld, fqdn, registrar);

    }

    // this function is called once on mint by the NFT contract
    function registerNode (
        bytes calldata fqdn
    ) external returns (
        bytes32 nodeHash
    ) {

        ( bytes32 node, bytes32 tld ) = fqdn.namehashAndTLD();

        if (msg.sender != TLDs[tld]) revert TLDRegistrarOnly();

        nodes[node] = Node(ITLDRegistrar(msg.sender), 0);

        emit NodeRegistered(node, fqdn);

        return node;

    }

    function setKey (bytes32 _node, bytes32 _key) external tldAuth(_node) {

        ( key[_node] = _key ) == 0 
            ? nodes[_node].records &= KEYED_BIT
            : nodes[_node].records |= KEYED_BIT;

        emit KeyUpdate(_node, _key);

    }

    function setRouters (bytes32 _node, bytes32[] calldata _newRouters) external tldAuth(_node) {

        ( _routers[_node] = _newRouters ).length == 0
            ? nodes[_node].records &= ROUTED_BIT
            : nodes[_node].records |= ROUTED_BIT;

        emit RoutingUpdate(_node, _newRouters);

    }

    function setDirectInfo(
        bytes32 _node,
        uint128 _ip,
        uint16 _ws,
        uint16 _wt,
        uint16 _tcp,
        uint16 _udp
    ) public {}

    function setAllIp (bytes32 _node, uint128 _ip, uint16 _ws, uint16 _wt, uint16 _tcp, uint16 _udp) external tldAuth(_node) {

        uint96 _records = nodes[_node].records;

        _records = _ip == 0 ? _records & IP_BIT : _records | IP_BIT;
        _records = _ws == 0 ? _records & WS_BIT : _records | WS_BIT;
        _records = _wt == 0 ? _records & WT_BIT : _records | WT_BIT;
        _records = _tcp == 0 ? _records & TCP_BIT : _records | TCP_BIT;
        _records = _udp == 0 ? _records & UDP_BIT : _records | UDP_BIT;

        nodes[_node].records = _records;

        ip[_node] = IP(_ip, _ws, _wt, _tcp, _udp);

        emit IpUpdate(_node, _ip);
        emit WsUpdate(_node, _ws);
        emit WtUpdate(_node, _wt);
        emit TcpUpdate(_node, _tcp);
        emit UdpUpdate(_node, _udp);

    }

    function setIp (bytes32 _node, uint128 _ip) external tldAuth(_node) {

        ( ip[_node].ip = _ip ) == 0
            ? nodes[_node].records &= IP_BIT
            : nodes[_node].records |= IP_BIT;
        
        emit IpUpdate(_node, _ip);

    }

    function setWs (bytes32 _node, uint16 _ws) external tldAuth(_node) {

        ( ip[_node].ws = _ws ) == 0
            ? nodes[_node].records &= WS_BIT
            : nodes[_node].records |= WS_BIT;
        
        emit WsUpdate(_node, _ws);

    }

    function setWt (bytes32 _node, uint16 _wt) external tldAuth(_node) {

        ( ip[_node].wt = _wt ) == 0
            ? nodes[_node].records &= WT_BIT
            : nodes[_node].records |= WT_BIT;
        
        emit WtUpdate(_node, _wt);

    }

    function setTcp (bytes32 _node, uint16 _tcp) external tldAuth(_node) {

        ( ip[_node].tcp = _tcp ) == 0
            ? nodes[_node].records &= TCP_BIT
            : nodes[_node].records |= TCP_BIT;
        
        emit TcpUpdate(_node, _tcp);

    }

    function setUdp (bytes32 _node, uint16 _udp) external tldAuth(_node) {

        ( ip[_node].udp = _udp ) == 0
            ? nodes[_node].records &= UDP_BIT
            : nodes[_node].records |= UDP_BIT;
        
        emit UdpUpdate(_node, _udp);

    }

    function clearRecords (bytes32 _node, uint96 _records) external tldAuth(_node) {

        nodes[_node].records &= ~_records;

        emit RecordsCleared(_node);

    }

    // 
    // views
    //

    function routers (bytes32 _node) external view returns (bytes32[] memory) {
        return _routers[_node];
    }

    //
    // internals
    //

    function _getNodeAndParent (
        bytes memory fqdn
    ) internal pure returns (bytes32, bytes32) {
        (bytes32 label, uint256 offset) = fqdn.readLabel(0);
        bytes32 parentNode = fqdn.namehash(offset);
        return ( _makeNode(parentNode, label), parentNode );

    }

    function _makeNode (
        bytes32 node,
        bytes32 labelhash
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(node, labelhash));
    }

    //
    // ERC165
    //

    function supportsInterface (
        bytes4 interfaceID
    ) public view override returns (bool) {
        return
            interfaceID == type(IQNSRegistryResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}
