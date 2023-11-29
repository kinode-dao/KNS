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
        bytes calldata _name,
        bytes[] calldata _data
    ) external payable returns (
        uint256 nodeId
    ) {

        bytes32 _attributes = _authAndGetRegistrationAttributes(_name, msg.sender);

        return _register(_name, msg.sender, _attributes, _data);

    }

    function _authAndGetRegistrationAttributes (
        bytes calldata _name,
        address _minter
    ) internal view returns (bytes32 attributes_) {

        ( , uint _offset ) = _name.readLabel(0);

        ( bytes32 _parent, bool _auth ) = _authRegister(_name, _offset, _minter);

        if (!_auth) revert NotAuthorizedToMintName();

        attributes_ = _parent == TLD_HASH
            ? PARENT_CANNOT_CONTROL
            : bytes32(0);

    }

    function _authRegister (
        bytes calldata _name,
        uint256 _offset,
        address _minter
    ) internal view returns (bytes32 node_, bool auth_) {

        ( bytes32 _label, uint _newOffset) = _name.readLabel(_offset);

        if (_label == bytes32(0)) return ( bytes32(0), false);

        ( node_, auth_ ) = _authRegister(_name, _newOffset, _minter);

        node_ = keccak256(abi.encodePacked(_node, _label));

        if (auth_ && !_controllableViaParent(uint(node_))) auth_ = false;

        if (node_ != TLD_HASH) auth_ = super.auth(uint(node_), _minter);

    }

    function auth (
        bytes32 _nodeId,
        address _sender
    ) public override(TLDRegistrar) view returns (bool) {

        return auth(uint(_nodeId), _sender);

    }

    function auth (
        uint _nodeId,
        address _sender
    ) public override(TLDRegistrar) view returns (bool authed) {

        while (!authed_) {

            authed_ = super.auth(_nodeId, _sender);

            if (authed_) break;
            else if (_controllableViaParent(_nodeId)) _nodeId = parents[_nodeId];
            else return false;

        }

    }

    function _controllableViaParent (
        uint _nodeId
    ) internal view returns (bool) {

        bytes32 _node = _getNode(_nodeId);

        bytes32 _attributes = _getAttributes(_node);

        return false;

    }

    //
    // internals
    //

}