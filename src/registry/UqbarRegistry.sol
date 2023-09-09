// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ENSRegistry } from "ens-contracts/registry/ENSRegistry.sol";

contract UqbarRegistry is ENSRegistry {

    constructor() ENSRegistry() { }

}
