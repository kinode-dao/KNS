// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

import "./interfaces/IQNS.sol";
import "./lib/BytesUtils.sol";

error MustChooseStaticOrRouted();

// TODO lets see what inspiration we can take from VersionableResolver? Not really sure what the point of it is but maybe...

contract QNSRegistry is IQNS, ERC165Upgradeable, UUPSUpgradeable, OwnableUpgradeable { // TODO should be multicallable
    using BytesUtils for bytes;

    // Has pointers to NFT contract (ownership) and protocols
    mapping (uint => Record) public records;

    // Websocket information
    mapping(uint256 => WsRecord) ws_records;

    // TODO do we need to include a storage slot here for upgradability? something something...


    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();

        records[0].owner = msg.sender; // TODO probably not correct 
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getInitializedVersion() public view returns (uint8) { return
        _getInitializedVersion();
    }

    /**
     * Sets the NFT and protocol information associated with the QNS name
     * @param fqdn fully qualified domain name to register
     * @param _protocols bitmap of which protocols this node supports
     */
    function setRecord (
        bytes calldata fqdn,
        uint32 _protocols
        // continuation calls?
    ) public {
        (uint node, uint parentNode) = _getNodeAndParent();

        // only parent NFT contract can setRecords
        //      E.g. only .uq's NFT contract can setRecords for my-name.uq
        // OR if ERC721(nft).ownerOf(node) == msg.sender THEN...
        address parentOwner = records[uint(parentNode)].nft;
        require(parentOwner == msg.sender);

        records[node] = Record({
            // TODO I think this is correct...might want to let them specify something for subdomains?
            // this basically means that .uq handles ALL subdomaining. We should probably implement some logic
            // for that in the UqRegistrar contract. Also logic for specifying your own NFT if you want that
            nft: msg.sender,
            protocols: _protocols
        });

        emit ProtocolsChanged(node, fqdn, _protocols);
    }

    /**
     * Sets the Ws information associated with the QNS node.
     * @param node The node to update.
     * @param _publicKey The networking key of the QNS node
     * @param _ip The IP address of the QNS node (0 if indirect node)
     * @param _port The port of the QNS node (0 if indirect node)
     * @param _routers The allowed routers of the QNS node (empty if direct node)
     */
    function setWs(
        uint256 node,
        bytes32 _publicKey,
        uint32 _ip,
        uint16 _port,
        bytes32[] calldata _routers
    ) external virtual authorised(node) {

        if ((_ip != 0 || _port != 0) && _routers.length != 0) {
            revert MustChooseStaticOrRouted();
        }
        if (_ip == 0 && _port == 0 && _routers.length == 0) {
            revert MustChooseStaticOrRouted();
        }

        uint48 _ipAndPort = combineIpAndPort(_ip, _port);

        ws_records[node] = WsRecord(
            _publicKey,
            _ipAndPort,
            _routers
        );
        emit WsChanged(node, _publicKey, _ipAndPort, _routers);
    }

    /**
     * Returns the Ws routing information associated with the QNS node.
     * @param node The ENS node to query
     * @return record The record information from the resolver
     */
    function ws(
        uint256 node
    ) external view virtual override returns (WsRecord memory) {
        return ws_records[node];
    }


    function _getNodeAndParent() internal view returns (uint node, uint parentNode) {
        (bytes32 labelhash, uint256 offset) = msg.data.readLabel(0);
        parentNode = msg.data.namehash(offset);
        node = _makeNode(parentNode, labelhash);
    }

    function _makeNode(
        bytes32 node,
        bytes32 labelhash
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(node, labelhash));
    }

    function combineIpAndPort(uint32 ip, uint16 port) internal pure returns (uint48) {
        return uint48((uint48(ip) << 16) | port);
    }

    // TODO might want functions to change resolver...though actually I think just one permanent but upgradable resolver is best...TODO
}
