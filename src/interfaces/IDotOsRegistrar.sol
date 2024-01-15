pragma solidity >=0.8.4;

import "./ITLDRegistrar.sol";

bytes32 constant PARENT_CANNOT_CONTROL = bytes32(uint(1));
bytes32 constant CANNOT_CREATE_SUBDOMAIN = bytes32(uint(2));
bytes32 constant CANNOT_TRANSFER = bytes32(uint(4));

interface IDotOsRegistrar {
    event ControlRevoked(uint child, uint parent, address sender);
}
