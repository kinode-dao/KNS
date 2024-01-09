//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import { ILayerZeroEndpoint } from "layer-zero/interfaces/ILayerZeroEndpoint.sol";

import { ExcessivelySafeCall } from "./lib/ExcessivelySafeCall.sol";
import { BytesUtils } from "./lib/BytesUtils.sol";
import { INDNSEnsExit } from "./interfaces/INDNSEnsExit.sol";
import { INDNSRegistryResolver } from "./interfaces/INDNSRegistryResolver.sol";

contract NDNSEnsExit is INDNSEnsExit {

    error NotEthName();
    error EthNameTooShort();
    error ParentNotRegistered();

    event Error(bytes4 error);

    using BytesUtils for bytes;

    bytes32 constant DOT_ETH_HASH = 0xc65934a88d283a635602ca15e14e8b9a9a3d150eacacca3b07f4a85f5fdbface;

    ILayerZeroEndpoint 
            immutable public lz;
    uint16  immutable public lzc;
    address immutable public ndns;

    address immutable public owner;

    mapping (uint => address) public ensowners;

    mapping (uint16 => bytes) public trustedentries;

    modifier onlyowner () { require(msg.sender == owner); _; }
    modifier onlythis () { require(msg.sender == address(this)); _; }

    constructor (
        address _ndns,
        address _lz, 
        uint16 _lzc
    ) {

        owner = msg.sender;

        ndns = _ndns;
        lz = ILayerZeroEndpoint(_lz);
        lzc = _lzc;

        ensowners[uint(DOT_ETH_HASH)] = address(this);

    }

    function setEntry (address _entry, uint16 _entrychain) public onlyowner {
        trustedentries[_entrychain] = abi.encodePacked(_entry, address(this));
    }

    function setNDNSRecords (
        address owner,
        bytes calldata fqdn,
        bytes[] calldata data
    ) external onlythis {

        // if (fqdn.length < 5) 
        //     revert EthNameTooShort();

        // if (DOT_ETH_HASH != keccak256(fqdn[fqdn.length-5:fqdn.length]))
        //     revert NotEthName();
        
        // ( uint parent, uint child ) = 
        //     _getParentAndChildNodes(fqdn);

        // if (ensowners[parent] == address(0))
        //     revert ParentNotRegistered();

        // ensowners[child] = owner;

        // INDNSRegistryResolver(ndns).registerNode(fqdn);

        // if (data.length != 0) 
        //     INDNSRegistryResolver(ndns).multicallWithNodeCheck(child, data);

    }

    function ownerOf (
        uint256 node
    ) public returns (
        address
    ) {
        return ensowners[node];
    }

    function simulate (bytes calldata _payload) external {

        ExcessivelySafeCall.excessivelySafeCall
            ( address(this), gasleft(), 150, _payload );

    }

    function ping () public onlythis {

        emit Pinged(address(this));

    }

    function setBaseNode (uint256 node) public { }

    function lzReceive (
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

        ( bool success, bytes memory data) = 
            ExcessivelySafeCall.excessivelySafeCall
                ( address(this), gasleft(), 150, _payload );
        
        if (!success) {
            bytes4 selector;
            assembly { selector := mload(add(data, 0x20)) }
            emit Error(selector);
        }
        
    }

    function _getParentAndChildNodes(bytes memory fqdn) internal pure returns (uint256 node, uint256 parentNode) {
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