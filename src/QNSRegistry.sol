// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/IQNS.sol";
import "./interfaces/IQNSNFT.sol";
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

        records[0].owner = msg.sender; // TODO double check this
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getInitializedVersion() public view returns (uint8) {
        return _getInitializedVersion();
    }

    //
    // externals
    //

    function registerSubdomainContract(bytes calldata fqdn, IQNSNFT nft) external {
        (uint256 node, uint256 parentNode) = _getNodeAndParent(fqdn);
        
        nft.setBaseNode(node);
        
        address owner = records[uint256(parentNode)].owner;
        require(
            msg.sender == owner,
            "QNSRegistry: only parent domain owner can register subdomain contract"
        );

        records[node] = Record({
            owner: address(nft),
            protocols: 0
        });

        emit NewSubdomainContract(node, fqdn, address(nft));
    }

    // this function is called once on mint by the NFT contract
    function registerNode(
        bytes calldata fqdn
    ) external {
        (uint256 node, uint256 parentNode) = _getNodeAndParent(fqdn);

        address parentOwner = records[uint256(parentNode)].owner;
        require(
            msg.sender == parentOwner,
            "QNSRegistry: only NFT contract can register node for a subdomain"
        );

        // NOTE if we don't trust the owner contract, we also need to check this:
        //      IERC721(parentOwner).ownerOf(node) != address(0)

        records[node] = Record({
            // TODO I think this is correct...might want to let them specify something for subdomains?
            // this basically means that .uq handles ALL subdomaining. We should probably implement some logic
            // for that in the UqRegistrar contract. Also logic for specifying your own NFT if you want that
            owner: msg.sender,
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
        address parentOwner = records[uint256(node)].owner;
        
        require(
            msg.sender == parentOwner || msg.sender == IERC721(parentOwner).ownerOf(node),
            "QNSRegistry: only NFT contract or NFT owner can set ws records for a subdomain"
        );

        // NOTE if we don't trust parentOwner contract, we also need to check this:
        //      IERC721(parentOwner).ownerOf(node) != address(0)

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
        address parentOwner = records[uint256(node)].owner;
        
        require(
            // TODO ownerOf reverts when a token hasn't minted so parentOwner has to handle all changes
            msg.sender == parentOwner, // || msg.sender == IERC721(parentOwner).ownerOf(node),
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

    function _getNodeAndParent(bytes memory fqdn) public pure returns (uint256, uint256) { // TODO internal
        (bytes32 labelhash, uint256 offset) = fqdn.readLabel(0);
        bytes32 parentNode = fqdn.namehash(offset);
        bytes32 node = _makeNode(parentNode, labelhash);
        return (uint256(node), uint256(parentNode));
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
