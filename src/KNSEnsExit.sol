//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {ILayerZeroEndpoint} from "layer-zero/interfaces/ILayerZeroEndpoint.sol";
import {ExcessivelySafeCall} from "./lib/ExcessivelySafeCall.sol";

import {BytesUtils} from "./lib/BytesUtils.sol";
import {IKNSEnsExit} from "./interfaces/IKNSEnsExit.sol";
import {IKNSRegistryResolver} from "./interfaces/IKNSRegistryResolver.sol";

contract KNSEnsExit is 
    IKNSEnsExit,
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    error NotEthName();
    error EthNameTooShort();
    error ParentNotRegistered();

    event Error(bytes4 error);

    using BytesUtils for bytes;

    bytes32 constant DOT_ETH_LABEL = 
        0xc65934a88d283a635602ca15e14e8b9a9a3d150eacacca3b07f4a85f5fdbface;
    bytes32 constant DOT_ETH_HASH =
        0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;
    uint256 constant DOT_ETH_NODE = uint(DOT_ETH_HASH);

    ILayerZeroEndpoint public lz;
    uint16 public lzc;
    address public kns;

    mapping(uint => address) public ensowners;

    mapping(uint16 => bytes) public trustedentries;

    modifier onlythis() {
        require(msg.sender == address(this));
        _;
    }

    function initialize(address _kns, address _owner, address _lz, uint16 _lzc) public initializer {
        __UUPSUpgradeable_init();
        _transferOwnership(_owner);

        kns = _kns;
        lz = ILayerZeroEndpoint(_lz);
        lzc = _lzc;

        ensowners[uint(DOT_ETH_HASH)] = address(this);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setEntry(address _entry, uint16 _entrychain) public onlyOwner {
        trustedentries[_entrychain] = abi.encodePacked(_entry, address(this));
    }

    function deleteEntry(address _entry, uint16 _entrychain) public onlyOwner {
        delete trustedentries[_entrychain];
    }

    function setKNSRecords(
        address owner,
        bytes calldata fqdn,
        bytes[] calldata data
    ) external onlythis {

        if (fqdn.length < 5)
            revert EthNameTooShort();

        if (DOT_ETH_LABEL != keccak256(fqdn[fqdn.length-5:fqdn.length]))
            revert NotEthName();

        ( uint parent, uint child ) = _getParentAndChildNodes(fqdn);

        if (parent != DOT_ETH_NODE && ensowners[parent] == address(0))
            revert ParentNotRegistered();

        ensowners[child] = owner;

        IKNSRegistryResolver(kns).registerNode(fqdn);

        if (data.length != 0)
            IKNSRegistryResolver(kns).multicallWithNodeCheck(bytes32(child), data);

    }

    function auth(
        bytes32 _nodeId,
        address _sender
    ) public view returns (bool) {
        return 
            _sender == address(this) ||
            _sender == ensowners[uint(_nodeId)];
    }

    function ownerOf(uint256 node) public returns (address) {
        return ensowners[node];
    }

    function setBaseNode(uint256 node) public {}

    function lzReceive(
        uint16 _chain,
        bytes calldata _path,
        uint64,
        bytes calldata _payload
    ) public {
        require(msg.sender == address(lz), "!lz");

        bytes memory trustedentry = trustedentries[_chain];

        require(
            trustedentry.length != 0 &&
                trustedentry.length == _path.length &&
                keccak256(trustedentry) == keccak256(_path),
            "!trusted"
        );

        (bool success, bytes memory data) = ExcessivelySafeCall
            .excessivelySafeCall(address(this), gasleft(), 150, _payload);

        if (!success) {
            bytes4 selector;
            assembly {
                selector := mload(add(data, 0x20))
            }
            emit Error(selector);
        }
    }

    function __initTLDRegistration(bytes calldata fqdn, bytes32 tld) external { }

    function _getParentAndChildNodes(
        bytes memory fqdn
    ) internal pure returns (uint256 node, uint256 parentNode) {
        (bytes32 label, uint256 offset) = fqdn.readLabel(0);
        bytes32 parent = fqdn.namehash(offset);
        return (uint256(parent), _makeNode(parent, label));
    }

    function _makeNode(
        bytes32 node,
        bytes32 labelhash
    ) internal pure returns (uint256) {
        return uint(keccak256(abi.encodePacked(node, labelhash)));
    }
}
