// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { TestUtils } from "./Utils.sol";

import { QNSRegistry } from "../src/registry/QNSRegistry.sol";
import { IQNS } from "../src/interfaces/IQNS.sol";

import { BaseRegistrar } from "../src/lib/BaseRegistrar.sol";
import { IBaseRegistrar } from "../src/interfaces/IBaseRegistrar.sol";

import { PublicResolver } from "../src/resolver/PublicResolver.sol";
import { IResolver } from "../src/interfaces/IResolver.sol";

contract QNSTest is TestUtils {

    IQNS public qnsRegistry;
    IBaseRegistrar baseRegistrar;
    IResolver publicResolver;

    function setUp() public {

        QNSRegistry qnsRegistryImpl = new QNSRegistry();

        qnsRegistry = IQNS(
            address(
                new ERC1967Proxy(
                    address(qnsRegistryImpl),
                    abi.encodeWithSelector(
                        QNSRegistry.initialize.selector,
                        address(0)
                    )
                )
            )
        );

        BaseRegistrar baseRegistrarImpl = new BaseRegistrar();

        baseRegistrar = IBaseRegistrar(
            address(
                new ERC1967Proxy(
                    address(baseRegistrarImpl),
                    abi.encodeWithSelector(
                        BaseRegistrar.initialize.selector,
                        qnsRegistry,
                        getDNSWire("uq.")
                    )
                )
            )
        );

        PublicResolver publicResolverImpl = new PublicResolver();

        publicResolver = IResolver(
            address(
                new ERC1967Proxy(
                    address(publicResolverImpl),
                    abi.encodeWithSelector(
                        PublicResolver.initialize.selector,
                        qnsRegistry,
                        address(baseRegistrar),
                        address(0)
                    )
                )
            )
        );

    }

    function testQNS () public { }

}
