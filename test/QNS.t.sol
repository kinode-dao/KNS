// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";

import { QNSRegistry } from "../src/registry/QNSRegistry.sol";

contract QNSTest is Test {

    QNSRegistry public qnsRegistry;

    function setUp() public {

        qnsRegistry = new QNSRegistry();

    }

}
