// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import "forge-std/console.sol";

import "./lib/BytesUtils.sol";

import "./TLDRegistrar.sol";

import "./interfaces/IDotNecRegistrar.sol";

error NotAuthorizedToMintName();
error CannotRevokeControlFromTLD();
error SecondLevelDomainNot9CharactersOrMore();
error NotDotNecTLD();

contract DotNecRegistrar is IDotNecRegistrar, TLDRegistrar, Initializable, OwnableUpgradeable, UUPSUpgradeable {

    using BytesUtils for bytes;

    mapping (uint => uint) public parents;

    function initialize (
        address _ndns,
        address _owner
    ) public initializer {

        __TLDRegistrar_init(_ndns, "Uqbar Name Service", "UNDNS");
        __UUPSUpgradeable_init();
        _transferOwnership(_owner);

    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getInitializedVersion() public view returns (uint8) {
        return  _getInitializedVersion();
    }

    function register (
        bytes calldata _name,
        address _to,
        bytes[] calldata _data
    ) external payable returns (
        uint256 nodeId_
    ) {

        ( bytes32 _attributes, ) = 
            _authAndGetRegistrationAttributes(_name, 0, msg.sender);

        nodeId_ = _register(_name, _to, _attributes, _data);

    }

    function _authAndGetRegistrationAttributes (
        bytes calldata _name,
        uint256 _offset,
        address _minter
    ) internal returns (bytes32, bool) {

        // get current label
        ( bytes32 _label, uint _newOffset) = _name.readLabel(_offset);

        // if label is TLD demand it is .nec and return
        if (_newOffset == _name.length - 1)
            if (_label != TLD_LABEL) revert NotDotNecTLD();
                else return (TLD_HASH, true);

        // recurse to retrieve parent 
        ( bytes32 _parent, bool auth_ ) = 
            _authAndGetRegistrationAttributes (_name, _newOffset, _minter);

        // if second level domain, check it is 9 characters or more
        if (_parent == TLD_HASH && _newOffset - _offset <= 9) 
            revert SecondLevelDomainNot9CharactersOrMore();

        // make current node
        bytes32 node_ = keccak256(abi.encodePacked(_parent, _label));

        // if parent is not set, set
        if (parents[uint(node_)] == 0) parents[uint(node_)] = uint(_parent);

        // if not in the first callframe of recursion, update auth and recurse
        if (_offset != 0) {

            // if current node is not controllable via parent then auth must be false
            if (!_controllableViaParent(uint(node_))) auth_ = false;

            // if auth is false then check auth for current node
            if (!auth_) auth_ = super.auth(uint(node_), _minter);

            return (node_, auth_);

        // at end of first callframe, check auth and return attributes
        } else {

            if (!auth_) revert NotAuthorizedToMintName();

            return (_parent == TLD_HASH ? PARENT_CANNOT_CONTROL : bytes32(0), true);

        }

    }

    function revokeControlOverSubdomain (
        bytes memory _name
    ) public {

        ( bytes32 _child, bytes32 _parent, bytes32 _tld ) 
            = _name.childParentAndTLD();
        
        if (_parent == _tld) revert CannotRevokeControlFromTLD();

        if (auth(_parent, msg.sender)) {

            bytes32 _node = _getNode(_child) | PARENT_CANNOT_CONTROL;

            _setNode(_node , uint(_child));

            emit ControlRevoked(uint(_child), uint(_parent), msg.sender);

        } else revert NotAuthorized();

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
    ) public override(TLDRegistrar) view returns (bool authed_) {

        while (!authed_ && _nodeId != uint(TLD_HASH)) {

            authed_ = super.auth(_nodeId, _sender);

            if (authed_) break;
            else if (_controllableViaParent(_nodeId)) _nodeId = parents[_nodeId];
            else return false;

        }

    }

    //
    // internals
    //

    function _controllableViaParent (
        uint _nodeId
    ) internal view returns (bool) {

        return _controllableViaParent(_getNode(_nodeId));

    }

    function _controllableViaParent (
        bytes32 _nodeContents
    ) internal pure returns (bool) {

        return 
            _nodeContents == bytes32(0) || 
            _nodeContents & PARENT_CANNOT_CONTROL != PARENT_CANNOT_CONTROL;

    }

}