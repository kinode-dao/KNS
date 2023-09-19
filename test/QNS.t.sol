// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { TestUtils } from "./Utils.sol";

import { QNSRegistry } from "../src/QNSRegistry.sol";
import { IQNS } from "../src/interfaces/IQNS.sol";

import { UqRegistrar } from "../src/UqRegistrar.sol";
import { IQNSRegistrar } from "../src/interfaces/IQNSRegistrar.sol";

import { PublicResolver } from "../src/PublicResolver.sol";

contract QNSTest is TestUtils {

    IQNS public qnsRegistry;
    IQNSRegistrar baseRegistrar;
    PublicResolver publicResolver;

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

        UqRegistrar baseRegistrarImpl = new UqRegistrar();

        baseRegistrar = IQNSRegistrar(
            address(
                new ERC1967Proxy(
                    address(baseRegistrarImpl),
                    abi.encodeWithSelector(
                        UqRegistrar.initialize.selector,
                        qnsRegistry,
                        getDNSWire("uq.")
                    )
                )
            )
        );

        PublicResolver publicResolverImpl = new PublicResolver();

        publicResolver = PublicResolver(
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
