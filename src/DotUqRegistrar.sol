// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import "./lib/BytesUtils.sol";

import "./TLDRegistrar.sol";

import "./interfaces/IDotUqRegistrar.sol";

contract DotUqRegistrar is IDotUqRegistrar, TLDRegistrar, Initializable, OwnableUpgradeable, UUPSUpgradeable {

    using BytesUtils for bytes;

    mapping (uint => uint) public parents;

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

    function _fuses () internal view {
        console.log("fuses");
        console.logBytes32(PARENT_CANNOT_CONTROL);
        console.logBytes32(CANNOT_CREATE_SUBDOMAIN);
        console.logBytes32(CANNOT_TRANSFER);
        console.logBytes32(PARENT_CANNOT_CONTROL | CANNOT_CREATE_SUBDOMAIN | CANNOT_TRANSFER);
    }

    function register (
        bytes calldata name,
        bytes[] calldata data
    ) external payable returns (
        uint256 nodeId
    ) {

        ( bytes32 _child, bytes32 _parent, bytes32 _tld) = 
            name.childParentAndTLD();
        
        address _owner = _parent != TLD_HASH
            ? _getOwner(_getNode(uint(_parent)))
            : msg.sender;

        _register(name, _owner, data);

    }

    function auth (
        bytes32 _nodeId,
        address sender
    ) public override(TLDRegistrar) view returns (bool) {

        return auth(uint(_nodeId), sender);

    }

    function auth (
        uint _nodeId,
        address _sender
    ) public override(TLDRegistrar) view returns (bool authed) {

        authed = super.auth(_nodeId, _sender);

        while (!authed && _nodeId != 0) {

            if (_controllableViaParent(_nodeId)) {

                _nodeId = parents[_nodeId];
                authed = super.auth(_nodeId, _sender);

            } else return false;

        }

    }

    function _controllableViaParent (
        uint _node
    ) internal view returns (bool) {

        bytes32 _attributes = _getAttributes(_getNode(_node));

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