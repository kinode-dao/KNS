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

contract QNSRegistry is IQNS, ERC165Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
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

    // this function is called once on mint by the NFT contract
    function registerNode(
        bytes calldata fqdn
    ) external {
        (uint256 node, uint256 parentNode) = _getNodeAndParent(fqdn);

        address nftContract = records[uint256(parentNode)].nft;
        require(
            msg.sender == nftContract,
            "QNSRegistry: only NFT contract can register node for a subdomain"
        );

        // NOTE if we don't trust the nft contract, we also need to check this:
        //      IERC721(nftContract).ownerOf(node) != address(0)

        records[node] = Record({
            // TODO I think this is correct...might want to let them specify something for subdomains?
            // this basically means that .uq handles ALL subdomaining. We should probably implement some logic
            // for that in the UqRegistrar contract. Also logic for specifying your own NFT if you want that
            nft: nftContract,
            protocols: 0
        });

        emit NodeRegistered(node, fqdn);
    }

    function setWsRecord(
        uint256 node,
        bytes32 publicKey,
        uint32 ip,
        uint16 port,
        bytes32[] calldata routers
    ) external {
        address nftContract = records[uint256(node)].nft;
        
        require(
            msg.sender == nftContract || msg.sender == IERC721(nftContract).ownerOf(node),
            "QNSRegistry: only NFT contract or NFT owner can set ws records for a subdomain"
        );

        // NOTE if we don't trust the nft contract, we also need to check this:
        //      IERC721(nftContract).ownerOf(node) != address(0)

        require(publicKey != bytes32(0), "QNSRegistry: public key cannot be 0");

        if ((ip == 0 || port == 0) && routers.length == 0) {
            revert MustChooseStaticOrRouted();
        }

        uint48 ipAndPort = combineIpAndPort(ip, port);

        ws_records[node] = WsRecord(
            publicKey,
            ipAndPort,
            routers
        );

        Record storage record = records[node];
        record.protocols = record.protocols | WEBSOCKETS;

        emit WsChanged(node, record.protocols, publicKey, ipAndPort, routers);
    }

    function clearProtocol(uint256 node, uint32 protocols) external {
        address nftContract = records[uint256(node)].nft;
        
        require(
            // TODO ownerOf reverts when a token hasn't minted so nftContract has to handle all changes
            msg.sender == nftContract, // || msg.sender == IERC721(nftContract).ownerOf(node),
            "QNSRegistry: only NFT contract or NFT owner can clear records for a subdomain"
        );
        
        Record storage record = records[node];
        record.protocols = record.protocols & ~protocols; // TODO is this right
    }

    //
    // views
    //

    function ws(
        uint256 node
    ) external view virtual override returns (WsRecord memory) {
        require(
            records[node].protocols & WEBSOCKETS != 0,
            "QNSRegistry: node does not support websockets"
        );
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

    //
    // ERC165
    //

    function supportsInterface(bytes4 interfaceID) public view override returns (bool) {
        return
            interfaceID == type(IQNS).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}
