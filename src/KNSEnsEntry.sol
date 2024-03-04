//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import {ILayerZeroEndpoint} from "layer-zero/interfaces/ILayerZeroEndpoint.sol";
import {INameWrapper} from "ens-contracts/wrapper/INameWrapper.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";

import {console} from "forge-std/console.sol";

import {BytesUtils} from "./lib/BytesUtils.sol";
import {IKNSEnsExit} from "./interfaces/IKNSEnsExit.sol";

contract KNSEnsEntry {
    error NotEnsOwner();

    address public immutable owner;

    ILayerZeroEndpoint public immutable lz;
    uint16 public immutable lzc;

    bytes public exitpath;
    uint16 public immutable exitlzc;

    address public immutable ensregistry;
    address public immutable ensnamewrapper;

    modifier onlyowner() {
        require(msg.sender == owner);
        _;
    }

    constructor(
        address _ensregistry,
        address _ensnamewrapper,
        address _lz,
        uint16 _lzc,
        address _exit,
        uint16 _exitlzc
    ) {
        ensregistry = _ensregistry;
        ensnamewrapper = _ensnamewrapper;

        owner = msg.sender;
        lz = ILayerZeroEndpoint(_lz);
        lzc = _lzc;

        exitpath = abi.encodePacked(_exit, address(this));
        exitlzc = _exitlzc;
    }

    function setKNSRecords(bytes calldata fqdn, bytes[] calldata data) public {
        bytes32 node = BytesUtils.namehash(fqdn, 0);

        address owner = ENS(ensregistry).owner(node);

        if (owner == ensnamewrapper)
            owner = INameWrapper(ensnamewrapper).ownerOf(uint(node));

        if (owner != msg.sender) revert NotEnsOwner();

        bytes memory payload = abi.encodeWithSelector(
            IKNSEnsExit.setKNSRecords.selector,
            msg.sender,
            fqdn,
            data
        );

        lzSend(
            payload, 
            abi.encodePacked(uint16(1), uint(300000), uint(0), address(0))
        );

    }

    function lzSend(bytes memory _payload, bytes memory _params) internal {
        lz.send{value: address(this).balance}(
            exitlzc,
            exitpath,
            _payload,
            payable(address(this)),
            address(0),
            _params
        );
    }

    receive() external payable {}

    fallback() external payable {}

}
