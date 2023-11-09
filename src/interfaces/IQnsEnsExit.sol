// SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

interface IQnsEnsExit {

    event Pinged(address);

    function setEntry (
        address _entry,
        uint16 _entryChain
    ) external;

    function ping () external;

}