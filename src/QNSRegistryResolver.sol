// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/IQNS.sol";
import "./interfaces/IQNSNFT.sol";
import "./lib/Multicallable.sol";
import "./lib/BytesUtils.sol";

error MustChooseStaticOrRouted();

// TODO lets see what inspiration we can take from VersionableResolver?

contract QNSRegistry is Multicallable, IQNS, ERC165Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
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
        if (!nodes[node].tld.auth(msg.sender)) revert TLD401();
        _;
    }
    
    modifier onlyTLD (Node storage node) {
        if (address(node.tld) != msg.sender) revert OnlyTLD();
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

        TLDS[tld] = nodes[tld].tld = registrar;

        // TODO could check that registrar implements IQNSNFT via ERC165
        emit NewTLD(node, fqdn, registrar);

    }

    // this function is called once on mint by the NFT contract
    function registerNode(bytes calldata fqdn) external {

        ( bytes32 node, bytes32 tld ) = fqdn.namehashAndTLDhash();

        if (msg.sender != TLDs[tld]) revert TLDRegistrarOnly();

        nodes[node] = Node(tlds[tld], 0);

        emit NodeRegistered(node, fqdn);

    }

    function setKey (bytes32 _node, bytes32 key) external tldAuth(nodes[_node]) {

        bytes32(0) == key[_node] = key
            ? nodes[_node].records &= KEYED
            : nodes[_node].records |= KEYED;

        emit KeyUpdate(_node, key);

    }

    function setRouting (
        bytes32 _node, 
        bytes32[] calldata _routers
    ) external tldAuth(nodes[_node]) {

        0 == (routing[_node] = _routers).length
            ? nodes[_node].records &= ROUTED
            : nodes[_node].records |= ROUTED;

        emit RoutingUpdate(_node, _routers);

    }

    function setIp (bytes32 _node, uint128 _ip) external tldAuth(nodes[_node]) {

        0 == ip[_node] = _ip
            ? nodes[_node].records &= IP
            : nodes[_node].records |= IP;
        
        emit IpUpdated(_node, _ip);

    }

    function setWs (bytes32 _node, uint16 _ws) external tldAuth(nodes[_node]) {

        0 == ws[_node] = _ws
            ? nodes[_node].records &= WS
            : nodes[_node].records |= WS;
        
        emit WsUpdated(_node, _ws);

    }

    function setWt (bytes32 _node, uint16 _wt) external tldAuth(nodes[_node]) {

        0 == wt[_node] = _wt
            ? nodes[_node].records &= WT
            : nodes[_node].records |= WT;
        
        emit WtUpdated(_node, _ws);

    }

    function setTcp (bytes32 _node, uint16 _tcp) external tldAuth(nodes[_node]) {

        0 == _tcp[_node] = _tcp 
            ? nodes[_node].records &= TCP
            : nodes[_node].records |= TCP;
        
        emit TcpUpdated(_node, _tcp);

    }

    function setUdp (bytes32 _node, uint16 _udp) external tldAuth(nodes[_node]) {

        0 == _udp[_node] = _udp 
            ? nodes[_node].records &= UDP
            : nodes[_node].records |= UDP;
        
        emit UdpUpdated(_node, _udp);

    }

    function clearRecords (
        bytes32 _node, 
        uint96 _records
    ) external tldAuth(nodes[_node]) {

        nodes[_node].records &= ~records;

        emit ProtocolsCleared(node);

    }

    //
    // internals
    //

    function _getNodeAndParent (
        bytes memory fqdn
    ) internal pure returns (uint256, uint256) {

        (bytes32 labelhash, uint256 offset) = fqdn.readLabel(0);
        bytes32 parentNode = fqdn.namehash(offset);
        bytes32 node = _makeNode(parentNode, labelhash);
        return (uint256(node), uint256(parentNode));

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
            interfaceID == type(IQNS).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}
