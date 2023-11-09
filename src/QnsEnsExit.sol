//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import { ILayerZeroEndpoint } from "layer-zero/interfaces/ILayerZeroEndpoint.sol";
import { ExcessivelySafeCall } from "./lib/ExcessivelySafeCall.sol";
import { IQnsEnsExit } from "./interfaces/IQnsEnsExit.sol";

contract QnsEnsExit is IQnsEnsExit {

    address immutable public owner;
    ILayerZeroEndpoint public lz;
    uint16 public lzc;

    mapping (uint16 => bytes) public trustedentries;

    constructor (address _lz, uint16 _lzc) {

        owner = msg.sender;

        lz = ILayerZeroEndpoint(_lz);
        lzc = _lzc;

    }

    function setEntry (address _entry, uint16 _entrychain) public {
        require(msg.sender == owner);

        trustedentries[_entrychain] = 
            abi.encodePacked(_entry, address(this));
    }

    function ping () public {

        emit Pinged(address(this));

    }

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

}