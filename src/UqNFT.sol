// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import "./QNSRegistry.sol";
import "./lib/BytesUtils.sol";
import "./interfaces/IQNS.sol";
import "./interfaces/IQNSNFT.sol";
import "./interfaces/IMulticallable.sol";

contract UqNFT is IQNSNFT, Initializable, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using BytesUtils for bytes;

    QNSRegistry public qns;
    uint256     public baseNode;

    function initialize (
        QNSRegistry _qns
    ) public initializer {

        __UUPSUpgradeable_init();
        __Ownable_init();
        __ERC721_init("Uqbar Name Service", "UQNS");

        qns = _qns;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getInitializedVersion() public view returns (uint8) {
        return  _getInitializedVersion();
    }

    //
    // externals
    //

    function setBaseNode(uint256 _baseNode) external override {
        require(msg.sender == address(qns), "UqNFT: only QNS can set baseNode");
        require(baseNode == 0, "UqNFT: baseNode already set");
        baseNode = _baseNode;
    }

    // TODO probably want two versions of this: a payable versions and an invite code version
    function register(
        bytes calldata name,
        address owner,
        bytes[] calldata recordCallData
    ) public {
        // TODO check that name is >= 9 characters
        (uint256 node, uint256 parentNode) = _getNodeAndParent(name);
        require(
            parentNode == baseNode,
            "UqNFT: only subdomains of baseNode can be registered"
        );

        _safeMint(owner, node, "");
        qns.registerNode(name);

        if (recordCallData.length > 0) 
            qns.multicallWithNodeCheck(node, recordCallData);

    }

    function allowSubdomains(
        bytes calldata name,
        IQNSNFT nft
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

        qns.registerSubdomainContract(name, nft);
    }

    function transferFromAndClearProtocols(
        address from,
        address to,
        uint256 tokenId
    ) public {
        qns.clearProtocols(tokenId, 0xFFFFFFFF);
        safeTransferFrom(from, to, tokenId);
    }

    //
    // internals
    //

    function _getNodeAndParent(bytes memory fqdn) internal pure returns (uint256 node, uint256 parentNode) {
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