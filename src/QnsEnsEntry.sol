//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import { ILayerZeroEndpoint } from "layer-zero/interfaces/ILayerZeroEndpoint.sol";

contract QnsEnsEntry {

    ILayerZeroEndpoint public lz;
    uint16 public lzc;
    address endpoint;

    constructor (address _endpoint, address _lz, uint16 _lzc) {

        endpoint = _endpoint;
        lz = ILayerZeroEndpoint(_lz);
        lzc = _lzc;

    }

}