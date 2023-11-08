//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import { ILayerZeroEndpoint } from "layer-zero/interfaces/ILayerZeroEndpoint.sol";
import { ExcessivelySafeCall } from "./lib/ExcessivelySafeCall.sol";

contract QnsEnsEndpoint {

    ILayerZeroEndpoint public lz;
    uint16 public lzc;
    address entrypoint;

    constructor (address _entrypoint, address _lz, uint16 _lzc) {

        entrypoint = _entrypoint;
        lz = ILayerZeroEndpoint(_lz);
        lzc = _lzc;

    }

    function lzReceive (
        uint16 _chain, 
        bytes calldata _path, 
        uint64 _nonce, 
        bytes calldata _payload
    ) public {

        require(msg.sender == address(lz), "!lz");

        ExcessivelySafeCall.excessivelySafeCall
            ( address(this), gasleft(), 150, _payload );
        
    }

}