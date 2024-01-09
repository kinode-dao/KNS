// SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

interface INDNSEnsExit {

    event Pinged(address);

    function setEntry (
        address _entry,
        uint16 _entryChain
    ) external;

    function setNDNSRecords (
        address owner,
        bytes calldata fqdn,
        bytes[] calldata data
    ) external;

    function ping () external;

}