// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/IQNSRegistryResolver.sol";
import "./interfaces/IQNSNFT.sol";
import "./lib/Multicallable.sol";
import "./lib/BytesUtils.sol";

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
    mapping (bytes32 => bytes32[]) public routing;
    mapping (bytes32 => uint128)   public ip;
    mapping (bytes32 => uint16)    public ws;
    mapping (bytes32 => uint16)    public wt;
    mapping (bytes32 => uint16)    public tcp;
    mapping (bytes32 => uint16)    public udp;

    modifier tldAuth (bytes32 node) {
        if (!nodes[node].tld.auth(node, msg.sender)) revert TLD401();
        _;
    }
    
    modifier onlyTLD (Node storage node) {
        if (address(node.tld) != msg.sender) revert TLDRegistrarOnly();
        _;
    }

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getInitializedVersion() public view 
        returns (uint8) { return _getInitializedVersion(); }

    //
    // externals
    //

    function registerTLDRegistrar (
        bytes calldata fqdn, 
        address registrar
    ) external {

        _checkOwner();

        ( bytes32 tld, uint offset ) = fqdn.readLabel(0);

        if (offset != fqdn.length) revert NotTLD();

        nodes[tld].tld = ITLDRegistrar(TLDs[tld] = registrar);

        // TODO could check that registrar implements IQNSNFT via ERC165
        emit NewTLD(tld, fqdn, registrar);

    }

    // this function is called once on mint by the NFT contract
    function registerNode(bytes calldata fqdn) external {

        ( bytes32 node, bytes32 tld ) = fqdn.namehashAndTLD();

        if (msg.sender != TLDs[tld]) revert TLDRegistrarOnly();

        nodes[node] = Node(ITLDRegistrar(TLDs[tld]), 0);

        emit NodeRegistered(node, fqdn);

    }

    function setKey (bytes32 _node, bytes32 _key) external tldAuth(_node) {

        ( key[_node] = _key ) == 0 
            ? nodes[_node].records &= KEYED
            : nodes[_node].records |= KEYED;

        emit KeyUpdate(_node, _key);

    }

    function setRouting (
        bytes32 _node, 
        bytes32[] calldata _routers
    ) external tldAuth(_node) {

        ( routing[_node] = _routers ).length == 0
            ? nodes[_node].records &= ROUTED
            : nodes[_node].records |= ROUTED;

        emit RoutingUpdate(_node, _routers);

    }

    function setIp (bytes32 _node, uint128 _ip) external tldAuth(_node) {

        ( ip[_node] = _ip ) == 0
            ? nodes[_node].records &= IP
            : nodes[_node].records |= IP;
        
        emit IpUpdate(_node, _ip);

    }

    function setWs (bytes32 _node, uint16 _ws) external tldAuth(_node) {

        ( ws[_node] = _ws ) == 0
            ? nodes[_node].records &= WS
            : nodes[_node].records |= WS;
        
        emit WsUpdate(_node, _ws);

    }

    function setWt (bytes32 _node, uint16 _wt) external tldAuth(_node) {

        ( wt[_node] = _wt ) == 0
            ? nodes[_node].records &= WT
            : nodes[_node].records |= WT;
        
        emit WtUpdate(_node, _wt);

    }

    function setTcp (bytes32 _node, uint16 _tcp) external tldAuth(_node) {

        ( tcp[_node] = _tcp ) == 0
            ? nodes[_node].records &= TCP
            : nodes[_node].records |= TCP;
        
        emit TcpUpdate(_node, _tcp);

    }

    function setUdp (bytes32 _node, uint16 _udp) external tldAuth(_node) {

        ( udp[_node] = _udp ) == 0
            ? nodes[_node].records &= UDP
            : nodes[_node].records |= UDP;
        
        emit UdpUpdate(_node, _udp);

    }

    function clearRecords (bytes32 _node, uint96 _records) external tldAuth(_node) {

        nodes[_node].records &= ~_records;

        emit RecordsCleared(_node);

    }

    // 
    // views
    //
    function resolve (bytes calldata fqdn) external view returns (address owner, address tldRegistrar) {
        bytes32 namehash = fqdn.namehash(0);
        Node storage node = nodes[namehash];
        return ( address(node.tld), node.tld.resolve(namehash) );
    }

    function routers (bytes32 _node) external view returns (bytes32[] memory) {
        return routing[_node];
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
