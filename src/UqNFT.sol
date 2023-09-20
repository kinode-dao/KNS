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
    uint        public baseNode;

    function initialize (
        QNSRegistry _qns, 
        uint256 _baseNode
    ) public initializer {

        __UUPSUpgradeable_init();
        __Ownable_init();
        __ERC721_init("Uqbar Name Service", "UQNS");

        qns = _qns;
        baseNode = _baseNode;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // TODO what is this
    function getInitializedVersion() public view returns (uint8) {
        return  _getInitializedVersion();
    }

    function register(
        bytes calldata name,
        address owner
        // TODO signature for permissioned minting
    ) public payable {
        (uint256 node, uint256 parentNode) = _getNodeAndParent(name);
        require(
            parentNode == baseNode,
            "UqNFT: only subdomains of baseNode can be registered"
        );

        _safeMint(owner, node, "");
        qns.registerNode(name);
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