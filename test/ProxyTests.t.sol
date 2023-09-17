// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { console } from "forge-std/Console.sol";

import { TestUtils } from "./Utils.sol";

import { IProxyInteraction } from "../src/interfaces/IProxyInteraction.sol";

import { QNSRegistry } from "../src/QNSRegistry.sol";
import { IQNS } from "../src/interfaces/IQNS.sol";

import { UqRegistrar } from "../src/UqRegistrar.sol";

import { PublicResolver } from "../src/PublicResolver.sol";
import { IResolver } from "../src/interfaces/IResolver.sol";

contract UpgradeTester is Initializable, UUPSUpgradeable {

    function initialize () public initializer {
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override {}

    function upgraded () public pure returns (bool) {
        return true;
    }

    function getInitializedVersion() public view returns (uint8) 
        { return  _getInitializedVersion(); }

}

contract ProxyTests is TestUtils {

    IProxyInteraction public registryProxy;
    IProxyInteraction public registrarProxy;
    IProxyInteraction public resolverProxy;

    QNSRegistry    public qnsRegistry;
    UqRegistrar  public baseRegistrar;
    PublicResolver public publicResolver;

    function setUp() public {

        QNSRegistry qnsRegistryImpl = new QNSRegistry();

        qnsRegistry = QNSRegistry(
            address(
                new ERC1967Proxy(
                    address(qnsRegistryImpl),
                    abi.encodeWithSelector(
                        QNSRegistry.initialize.selector
        ))));

        UqRegistrar baseRegistrarImpl = new UqRegistrar();

        baseRegistrar = UqRegistrar(
            address(
                new ERC1967Proxy(
                    address(baseRegistrarImpl),
                    abi.encodeWithSelector(
                        UqRegistrar.initialize.selector,
                        qnsRegistry,
                        getNodeId("uq.")
        ))));

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
        ))));

        registryProxy = IProxyInteraction(address(qnsRegistry));
        registrarProxy = IProxyInteraction(address(baseRegistrar));
        resolverProxy = IProxyInteraction(address(publicResolver));

    }

    function testQNS () public { }

    function testProxyCorrectSetup () public {

        assertEq(registryProxy.getInitializedVersion(), 1, "registry incorrect version");
        assertEq(resolverProxy.getInitializedVersion(), 1, "resolver incorrect version");
        assertEq(registrarProxy.getInitializedVersion(), 1, "registrar incorrect version");

    }

    function testProxyCannotReinitialize() external {

        vm.expectRevert("Initializable: contract is already initialized");
        qnsRegistry.initialize();
        vm.expectRevert("Initializable: contract is already initialized");
        baseRegistrar.initialize(qnsRegistry, getNodeId("uq."));
        vm.expectRevert("Initializable: contract is already initialized");
        publicResolver.initialize(qnsRegistry, address(baseRegistrar), address(0));

    }

    function testProxyUpgrade() external {

        UpgradeTester testerImpl = new UpgradeTester();

        qnsRegistry.upgradeTo(address(testerImpl));
        baseRegistrar.upgradeTo(address(testerImpl));
        publicResolver.upgradeTo(address(testerImpl));

        assertTrue(UpgradeTester(address(registryProxy)).upgraded(), "registry not upgraded");
        assertTrue(UpgradeTester(address(registrarProxy)).upgraded(), "registrar not upgraded");
        assertTrue(UpgradeTester(address(resolverProxy)).upgraded(), "resolver not upgraded");

    }

}
