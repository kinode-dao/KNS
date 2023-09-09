// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";

import { UqbarRegistry } from "../src/registry/UqbarRegistry.sol";

contract UqbarPKITest is Test {

    UqbarRegistry public uqbarRegistry;

    function setUp() public {

        uqbarRegistry = new UqbarRegistry();

    }

}
