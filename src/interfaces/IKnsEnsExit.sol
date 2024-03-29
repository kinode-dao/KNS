// SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

interface IKNSEnsExit {
    event Pinged(address);

    function setEntry(address _entry, uint16 _entryChain) external;

    function setKNSRecords(
        address owner,
        bytes calldata fqdn,
        bytes[] calldata data
    ) external;

}
