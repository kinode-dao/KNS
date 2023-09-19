// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import "./QNSRegistry.sol";
import "./lib/BytesUtils.sol";
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

    // TODO what is this
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // TODO what is this
    function getInitializedVersion() public view returns (uint8) {
        return  _getInitializedVersion();
    }

    function register (
        bytes calldata name,
        address owner,
        uint32 protocols
        // bytes[]calldata resolverData // TODO for setting resovler data and minting in one transaction
        // TODO signature for permissioned minting
    ) public payable {
        uint id = uint(name.namehash(0));

        qns.setProtocols(
            name, 
            protocols
        );

        _mint(owner, id);
    }

    // TODO we might need logic before/after transfer to unset the resolver data
}