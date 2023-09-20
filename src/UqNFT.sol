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
    uint        public baseNode; // TODO not clear that we need this

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

    function register (
        bytes calldata name,
        address owner
        // TODO signature for permissioned minting
    ) public payable {
        uint id = uint(name.namehash(0));

        _safeMint(owner, id, "");

        qns.registerNode(name);
    }

    //
    // overrides
    //

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override {
        if (from == address(0)) return; // ignore minting
        qns.clearProtocol(firstTokenId, WEBSOCKETS);
    }
}