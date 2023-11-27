// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import "./TLDRegistrar.sol";

contract DotUqRegistrar is TLDRegistrar, Initializable, OwnableUpgradeable, UUPSUpgradeable {

    uint constant CONTROLLABLE_VIA_PARENT = 1;
    mapping (bytes32 => bytes32) public parents;

    function initialize (
        address _qns
    ) public initializer {

        __TLDRegistrar_init(_qns, "Uqbar Name Service", "UQNS");
        __UUPSUpgradeable_init();
        __Ownable_init();

    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getInitializedVersion() public view returns (uint8) {
        return  _getInitializedVersion();
    }


    function register (
        bytes calldata name,
        bytes[] calldata
    ) external payable returns (
        uint256 nodeId
    ) {

    }

    function auth (
        bytes32 _nodeId,
        address _sender
    ) public override view returns (bool) {

        bytes32 node = _node(uint(_nodeId));

    }

    function _controllableViaParent (
        bytes32 _node
    ) internal view {

        bytes32 _attributes = _getAttributes(_node);

        console.log("attributes");
        console.logBytes32(bytes32(uint(1 << 96)));
        console.logBytes32(bytes32(uint(1 << 160)));
        console.logBytes32(bytes32(uint(1 >> 96)));
        console.logBytes32(bytes32(uint(1 >> 160)));

    }

    //
    // internals
    //

}