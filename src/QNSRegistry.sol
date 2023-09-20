// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/IQNS.sol";
import "./lib/BytesUtils.sol";

error MustChooseStaticOrRouted();

// TODO lets see what inspiration we can take from VersionableResolver? Not really sure what the point of it is but maybe...

contract QNSRegistry is IQNS, ERC165Upgradeable, UUPSUpgradeable, OwnableUpgradeable { // TODO should be multicallable
    using BytesUtils for bytes;

    // Has pointers to NFT contract (ownership) and protocols
    mapping (uint256 => Record) public records;

    // Websocket information
    mapping(uint256 => WsRecord) ws_records;

    // TODO do we need to include a storage slot here for upgradability? something something...

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();

        records[0].nft = msg.sender; // TODO double check this
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getInitializedVersion() public view returns (uint8) {
        return _getInitializedVersion();
    }

    //
    // externals
    //

    // TODO this should accept an 
    function newTld(bytes calldata fqdn, address nft) external onlyOwner {
        (uint256 node, uint256 parentNode) = _getNodeAndParent(fqdn);
        require(parentNode == 0, "QNSRegistry: cannot register subdomain using newTld");

        records[node] = Record({
            nft: nft,
            protocols: 0
        });

        emit NewTld(node, fqdn, nft);
    }

    function setProtocols (
        bytes calldata fqdn,
        uint32 _protocols
        // continuation calls?
    ) public {
        (uint256 node, uint256 parentNode) = _getNodeAndParent(fqdn);

        address nftContract = records[uint256(parentNode)].nft;
        address owner = IERC721(nftContract).ownerOf(node);
        require(
            msg.sender == nftContract || msg.sender == owner,
            "QNSRegistry: only NFT contract or NFT owner can set a records for a subdomain"
        );

        // NOTE if we don't trust the nft contract, we also need to check this:
        //      IERC721(nftContract).ownerOf(node) != address(0)

        records[node] = Record({
            // TODO I think this is correct...might want to let them specify something for subdomains?
            // this basically means that .uq handles ALL subdomaining. We should probably implement some logic
            // for that in the UqRegistrar contract. Also logic for specifying your own NFT if you want that
            nft: msg.sender,
            protocols: _protocols
        });

        emit ProtocolsChanged(node, fqdn, _protocols);
    }

    function setWsRecord(
        // uint256 node,
        bytes calldata fqdn, // TODO get rid of this and use continuation calls ONLY
        bytes32 _publicKey,
        uint32 _ip,
        uint16 _port,
        bytes32[] calldata _routers
    ) external virtual { // authorised(node) // TODO authorized modifier
        (uint256 node, uint256 parentNode) = _getNodeAndParent(fqdn); // TODO get rid of this

        address nftContract = records[uint256(parentNode)].nft;
        
        require(
            msg.sender == nftContract || msg.sender == IERC721(nftContract).ownerOf(node),
            "QNSRegistry: only NFT contract or NFT owner can set a records for a subdomain"
        );

        // NOTE if we don't trust the nft contract, we also need to check this:
        //      IERC721(nftContract).ownerOf(node) != address(0)

        if ((_ip != 0 || _port != 0) && _routers.length != 0) {
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

    //
    // views
    //

    function ws(
        uint256 node
    ) external view virtual override returns (WsRecord memory) {
        return ws_records[node];
    }

    //
    // internals
    //

    function _getNode(bytes memory fqdn) internal pure returns (uint256) {

    }

    // TODO does this actually work? what if it's a.b.c. not just b.c.?
    function _getNodeAndParent(bytes memory fqdn) public pure returns (uint256 node, uint256 parentNode) { // TODO internal
        (bytes32 labelhash, uint256 offset) = fqdn.readLabel(0);
        bytes32 parentNode = fqdn.namehash(offset);
        uint256 node = uint256(_makeNode(parentNode, labelhash));
        return (node, uint256(parentNode));
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
}
