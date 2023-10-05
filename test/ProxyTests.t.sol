// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { QNSRegistry } from "../src/QNSRegistry.sol";
import { IQNS } from "../src/interfaces/IQNS.sol";
import { UqNFT } from "../src/UqNFT.sol";
import { IQNSNFT } from "../src/interfaces/IQNSNFT.sol";
import { IProxyInteraction } from "../src/test/IProxyInteraction.sol";
import { QNSRegistry2 } from "../src/test/QNSRegistry2.sol";
import { TestUtils } from "./Utils.sol";

import { console } from "forge-std/Console.sol";

contract ProxyTests is TestUtils {

    // contracts
    IProxyInteraction public qnsRegistryProxy;
    IProxyInteraction public uqNftProxy;
    QNSRegistry       public qnsRegistry;
    UqNFT             public uqNft;

    // addresses
    address public deployer = address(2);
    address public alice = address(3);

    // constants
    bytes32 constant _PUBKEY = bytes32(0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F);

    // events
    event Upgraded(address indexed implementation);

    function setUp() public {
        vm.prank(deployer);
        QNSRegistry qnsRegistryImpl = new QNSRegistry();
        
        vm.prank(deployer);
        qnsRegistry = QNSRegistry(
            address(
                new ERC1967Proxy(
                    address(qnsRegistryImpl),
                    abi.encodeWithSelector(
                        QNSRegistry.initialize.selector
                    )
                )
            )
        );

        assertEq(qnsRegistry.owner(), address(deployer));

        vm.prank(deployer);
        UqNFT uqNftImpl = new UqNFT();

        vm.prank(deployer);
        uqNft = UqNFT(
            address(
                new ERC1967Proxy(
                    address(uqNftImpl),
                    abi.encodeWithSelector(
                        UqNFT.initialize.selector,
                        qnsRegistry
                    )
                )
            )
        );

        vm.prank(deployer);
        qnsRegistry.registerSubdomainContract(
            getDNSWire("uq"),
            IQNSNFT(uqNft)
        );

        qnsRegistryProxy = IProxyInteraction(address(qnsRegistryProxy));
        uqNftProxy = IProxyInteraction(address(uqNftProxy));
    }

    function testProxyCorrectSetup () public {
        assertEq(qnsRegistry.getInitializedVersion(), 1);
        assertEq(uqNft.getInitializedVersion(), 1);
    }

    function testProxyCannotReinitialize() external {
        vm.expectRevert("Initializable: contract is already initialized");
        qnsRegistry.initialize();
        vm.expectRevert("Initializable: contract is already initialized");
        uqNft.initialize(qnsRegistry);
    }

    function testUpgradeQNSRegistry() external {
        vm.prank(alice);
        uqNft.register(getDNSWire("alices-node.uq"), alice);
        
        vm.prank(alice);
        qnsRegistry.setWsRecord(
            getNodeId("alices-node.uq"),
            _PUBKEY,
            1,
            1,
            new bytes32[](0)
        );

        // assert exists in old state
        IQNS.WsRecord memory wsRecord = qnsRegistry.ws(getNodeId("alices-node.uq"));
        assertEq(wsRecord.publicKey, _PUBKEY);
        assertEq(wsRecord.ip, 1);
        assertEq(wsRecord.port, 1);
        assertEq(wsRecord.routers.length, 0);

        // upgrade contract
        QNSRegistry2 qnsRegistry2 = new QNSRegistry2();
        vm.prank(deployer);
        vm.expectEmit(true, false, false, false);
        emit Upgraded(address(qnsRegistry2));
        qnsRegistry.upgradeTo(address(qnsRegistry2));

        // assert old state still exists
        IQNS.WsRecord memory newWsRecord = qnsRegistry.ws(getNodeId("alices-node.uq"));
        assertEq(newWsRecord.publicKey, _PUBKEY);
        assertEq(newWsRecord.ip, 1);
        assertEq(newWsRecord.port, 1);
        assertEq(newWsRecord.routers.length, 0);

        // assert new state can be set
        QNSRegistry2(address(qnsRegistry)).setNewRecord(getNodeId("alices-node.uq"));
        assertEq(QNSRegistry2(address(qnsRegistry)).new_records(getNodeId("alices-node.uq")), true);
    }
}
