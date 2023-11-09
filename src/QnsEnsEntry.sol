//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import { ILayerZeroEndpoint } from "layer-zero/interfaces/ILayerZeroEndpoint.sol";
import { IQnsEnsExit } from "./interfaces/IQnsEnsExit.sol";

contract QnsEnsEntry {

    address immutable public owner;

    ILayerZeroEndpoint 
           immutable public lz;
    uint16 immutable public lzc;

    bytes  public endpointpath;
    uint16 immutable public endpointlzc;

    modifier onlyowner () {   require(msg.sender == owner); _; }


    constructor (address _lz, uint16 _lzc, address _endpoint, uint16 _endpointlzc) {

        owner = msg.sender;
        lz = ILayerZeroEndpoint(_lz);
        lzc = _lzc;

        endpointpath = abi.encodePacked(_endpoint, address(this));
        endpointlzc = _endpointlzc;

    }

    function ping () public {

        lzSend(
            abi.encodeWithSelector(IQnsEnsExit.ping.selector),
            bytes("")
        );

    }

    function lzSend (bytes memory _payload, bytes memory _params) internal {

        lz.send{value: address(this).balance}( 
            endpointlzc, 
            endpointpath, 
            _payload, 
            payable(address(this)), address(0), 
            _params
        );

    }

    receive()  external payable {}
    fallback() external payable {}

    function cash () public onlyowner 
        { msg.sender.call{value:address(this).balance}(""); }

}