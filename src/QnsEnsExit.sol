//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import { ILayerZeroEndpoint } from "layer-zero/interfaces/ILayerZeroEndpoint.sol";

import { ExcessivelySafeCall } from "./lib/ExcessivelySafeCall.sol";
import { BytesUtils } from "./lib/BytesUtils.sol";
import { IQnsEnsExit } from "./interfaces/IQnsEnsExit.sol";
import { IQNS } from "./interfaces/IQNS.sol";

contract QnsEnsExit is IQnsEnsExit {

    error EthNameTooShort();
    error NotEthName();

    using BytesUtils for bytes;

    bytes32 constant DOT_ETH_HASH = 0xc65934a88d283a635602ca15e14e8b9a9a3d150eacacca3b07f4a85f5fdbface;

    ILayerZeroEndpoint 
            immutable public lz;
    uint16  immutable public lzc;
    address immutable public qns;

    address immutable public owner;

    mapping (uint16 => bytes) public trustedentries;

    modifier onlyowner () { require(msg.sender == owner); _; }
    modifier onlythis () { require(msg.sender == address(this)); _; }

    constructor (
        address _qns,
        address _lz, 
        uint16 _lzc
    ) {

        owner = msg.sender;

        qns = _qns;
        lz = ILayerZeroEndpoint(_lz);
        lzc = _lzc;

    }

    function setEntry (address _entry, uint16 _entrychain) public {
        require(msg.sender == owner);

        trustedentries[_entrychain] = 
            abi.encodePacked(_entry, address(this));
    }

    function setQnsRecords (
        address owner,
        bytes calldata fqdn,
        bytes[] calldata data
    ) external onlythis {

        if (fqdn.length < 5) 
            revert EthNameTooShort();

        if (DOT_ETH_HASH != keccak256(fqdn[fqdn.length-5:fqdn.length]))
            revert NotEthName();

        IQNS(qns).registerNode(fqdn);

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

        ExcessivelySafeCall.excessivelySafeCall
            ( address(this), gasleft(), 150, _payload );
        
    }

    function _getParentAndChildNodes(bytes memory fqdn) internal pure returns (uint256 node, uint256 parentNode) {
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