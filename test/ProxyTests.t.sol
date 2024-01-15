// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// import { KNSRegistry } from "../src/KNSRegistry.sol";
// import { IKNS } from "../src/interfaces/IKNS.sol";
// import { UqNFT } from "../src/UqNFT.sol";
// import { IKNSNFT } from "../src/interfaces/IKNSNFT.sol";
// import { IProxyInteraction } from "../src/test/IProxyInteraction.sol";
// import { KNSRegistry2 } from "../src/test/KNSRegistry2.sol";
// import { TestUtils } from "./Utils.sol";

// import { console } from "forge-std/Console.sol";

// contract ProxyTests is TestUtils {

//     // contracts
//     IProxyInteraction public knsRegistryProxy;
//     IProxyInteraction public uqNftProxy;
//     KNSRegistry       public knsRegistry;
//     UqNFT             public uqNft;

//     // addresses
//     address public deployer = address(2);
//     address public alice = address(3);

//     // constants
//     bytes32 constant _PUBKEY = bytes32(0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F);

//     // events
//     event Upgraded(address indexed implementation);

//     function setUp() public {
//         vm.prank(deployer);
//         KNSRegistry knsRegistryImpl = new KNSRegistry();

//         vm.prank(deployer);
//         knsRegistry = KNSRegistry(
//             address(
//                 new ERC1967Proxy(
//                     address(knsRegistryImpl),
//                     abi.encodeWithSelector(
//                         KNSRegistry.initialize.selector
//                     )
//                 )
//             )
//         );

//         assertEq(knsRegistry.owner(), address(deployer));

//         vm.prank(deployer);
//         UqNFT uqNftImpl = new UqNFT();

//         vm.prank(deployer);
//         uqNft = UqNFT(
//             address(
//                 new ERC1967Proxy(
//                     address(uqNftImpl),
//                     abi.encodeWithSelector(
//                         UqNFT.initialize.selector,
//                         knsRegistry
//                     )
//                 )
//             )
//         );

//         vm.prank(deployer);
//         knsRegistry.registerSubdomainContract(
//             getDNSWire("os"),
//             IKNSNFT(uqNft)
//         );

//         knsRegistryProxy = IProxyInteraction(address(knsRegistryProxy));
//         uqNftProxy = IProxyInteraction(address(uqNftProxy));
//     }

//     function testProxyCorrectSetup () public {
//         assertEq(knsRegistry.getInitializedVersion(), 1);
//         assertEq(uqNft.getInitializedVersion(), 1);
//     }

//     function testProxyCannotReinitialize() external {
//         vm.expectRevert("Initializable: contract is already initialized");
//         knsRegistry.initialize();
//         vm.expectRevert("Initializable: contract is already initialized");
//         uqNft.initialize(knsRegistry);
//     }

//     function testUpgradeKNSRegistry() external {
//         vm.prank(alice);
//         uqNft.register(getDNSWire("alices-node.os"), alice, new bytes[](0));

//         vm.prank(alice);
//         knsRegistry.setWsRecord(
//             getNodeId("alices-node.os"),
//             _PUBKEY,
//             1,
//             1,
//             new bytes32[](0)
//         );

//         // assert exists in old state
//         IKNS.WsRecord memory wsRecord = knsRegistry.ws(getNodeId("alices-node.os"));
//         assertEq(wsRecord.publicKey, _PUBKEY);
//         assertEq(wsRecord.ip, 1);
//         assertEq(wsRecord.port, 1);
//         assertEq(wsRecord.routers.length, 0);

//         // upgrade contract
//         KNSRegistry2 knsRegistry2 = new KNSRegistry2();
//         vm.prank(deployer);
//         vm.expectEmit(true, false, false, false);
//         emit Upgraded(address(knsRegistry2));
//         knsRegistry.upgradeTo(address(knsRegistry2));

//         // assert old state still exists
//         IKNS.WsRecord memory newWsRecord = knsRegistry.ws(getNodeId("alices-node.os"));
//         assertEq(newWsRecord.publicKey, _PUBKEY);
//         assertEq(newWsRecord.ip, 1);
//         assertEq(newWsRecord.port, 1);
//         assertEq(newWsRecord.routers.length, 0);

//         // assert new state can be set
//         KNSRegistry2(address(knsRegistry)).setNewRecord(getNodeId("alices-node.os"));
//         assertEq(KNSRegistry2(address(knsRegistry)).new_records(getNodeId("alices-node.os")), true);
//     }
// }
