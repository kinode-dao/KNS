// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "./QNSRegistry.sol";
import "./lib/BytesUtils.sol";
import "./interfaces/IQNS.sol";
import "./interfaces/IQNSNFT.sol";
import "./interfaces/IMulticallable.sol";

contract UqNFT is
    IQNSNFT,
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using BytesUtils for bytes;
    using ECDSAUpgradeable for bytes32;

    QNSRegistry public qns;
    uint        public baseNode;
    address     public signer;

    function initialize (
        QNSRegistry _qns, 
        uint256 _baseNode,
        address _signer
    ) public initializer {

        __UUPSUpgradeable_init();
        __Ownable_init();
        __ERC721_init("Uqbar Name Service", "UQNS");

        qns = _qns;
        baseNode = _baseNode;
        signer = _signer;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // TODO what is this
    function getInitializedVersion() public view returns (uint8) {
        return  _getInitializedVersion();
    }

    //
    // externals
    //

    // TODO probably want two versions of this: a payable versions and an invite code version
    function register(
        bytes calldata name,
        address owner,
        bytes calldata signature
    ) public {
        (uint256 node, uint256 parentNode) = _getNodeAndParent(name);

        bytes32 ethSignedHash = bytes32("1").toEthSignedMessageHash();
        // bytes32 ethSignedHash = bytes32(node).toEthSignedMessageHash();
        address recovered = ethSignedHash.recover(signature);
        require(
            recovered == signer,
            "UqNFT: invalid signature, cannot mint"
        );

        require(
            parentNode == baseNode,
            "UqNFT: only subdomains of baseNode can be registered"
        );

        _safeMint(owner, node, "");
        qns.registerNode(name);
    }

    function allowSubdomains(
        bytes calldata name,
        address nft
    ) public {
        (uint256 node, uint256 parentNode) = _getNodeAndParent(name);
        require(
            parentNode == baseNode,
            "UqNFT: only subdomains of baseNode can be registered"
        );
        require(
            msg.sender == ownerOf(node),
            "UqNFT: only owner of node can allow subdomains"
        );

        // TODO check that nft is actually an NFT? Use ERC165?
        qns.registerSubdomainContract(name, nft);
    }

    //
    // overrides
    //

    // TODO make this optional
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override {
        if (from == address(0)) return; // ignore minting
        qns.clearProtocol(firstTokenId, WEBSOCKETS);
    }

    //
    // internals
    //

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
}