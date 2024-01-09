// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// import { NDNSRegistry } from "../src/NDNSRegistry.sol";
// import { INDNS } from "../src/interfaces/INDNS.sol";
// import { UqNFT } from "../src/UqNFT.sol";
// import { INDNSNFT } from "../src/interfaces/INDNSNFT.sol";
// import { IProxyInteraction } from "../src/test/IProxyInteraction.sol";
// import { NDNSRegistry2 } from "../src/test/NDNSRegistry2.sol";
// import { TestUtils } from "./Utils.sol";

// import { console } from "forge-std/Console.sol";

// contract ProxyTests is TestUtils {

//     // contracts
//     IProxyInteraction public ndnsRegistryProxy;
//     IProxyInteraction public uqNftProxy;
//     NDNSRegistry       public ndnsRegistry;
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
//         NDNSRegistry ndnsRegistryImpl = new NDNSRegistry();
        
//         vm.prank(deployer);
//         ndnsRegistry = NDNSRegistry(
//             address(
//                 new ERC1967Proxy(
//                     address(ndnsRegistryImpl),
//                     abi.encodeWithSelector(
//                         NDNSRegistry.initialize.selector
//                     )
//                 )
//             )
//         );

//         assertEq(ndnsRegistry.owner(), address(deployer));

//         vm.prank(deployer);
//         UqNFT uqNftImpl = new UqNFT();

//         vm.prank(deployer);
//         uqNft = UqNFT(
//             address(
//                 new ERC1967Proxy(
//                     address(uqNftImpl),
//                     abi.encodeWithSelector(
//                         UqNFT.initialize.selector,
//                         ndnsRegistry
//                     )
//                 )
//             )
//         );

//         vm.prank(deployer);
//         ndnsRegistry.registerSubdomainContract(
//             getDNSWire("nec"),
//             INDNSNFT(uqNft)
//         );

//         ndnsRegistryProxy = IProxyInteraction(address(ndnsRegistryProxy));
//         uqNftProxy = IProxyInteraction(address(uqNftProxy));
//     }

//     function testProxyCorrectSetup () public {
//         assertEq(ndnsRegistry.getInitializedVersion(), 1);
//         assertEq(uqNft.getInitializedVersion(), 1);
//     }

//     function testProxyCannotReinitialize() external {
//         vm.expectRevert("Initializable: contract is already initialized");
//         ndnsRegistry.initialize();
//         vm.expectRevert("Initializable: contract is already initialized");
//         uqNft.initialize(ndnsRegistry);
//     }

//     function testUpgradeNDNSRegistry() external {
//         vm.prank(alice);
//         uqNft.register(getDNSWire("alices-node.nec"), alice, new bytes[](0));
        
//         vm.prank(alice);
//         ndnsRegistry.setWsRecord(
//             getNodeId("alices-node.nec"),
//             _PUBKEY,
//             1,
//             1,
//             new bytes32[](0)
//         );

//         // assert exists in old state
//         INDNS.WsRecord memory wsRecord = ndnsRegistry.ws(getNodeId("alices-node.nec"));
//         assertEq(wsRecord.publicKey, _PUBKEY);
//         assertEq(wsRecord.ip, 1);
//         assertEq(wsRecord.port, 1);
//         assertEq(wsRecord.routers.length, 0);

//         // upgrade contract
//         NDNSRegistry2 ndnsRegistry2 = new NDNSRegistry2();
//         vm.prank(deployer);
//         vm.expectEmit(true, false, false, false);
//         emit Upgraded(address(ndnsRegistry2));
//         ndnsRegistry.upgradeTo(address(ndnsRegistry2));

//         // assert old state still exists
//         INDNS.WsRecord memory newWsRecord = ndnsRegistry.ws(getNodeId("alices-node.nec"));
//         assertEq(newWsRecord.publicKey, _PUBKEY);
//         assertEq(newWsRecord.ip, 1);
//         assertEq(newWsRecord.port, 1);
//         assertEq(newWsRecord.routers.length, 0);

//         // assert new state can be set
//         NDNSRegistry2(address(ndnsRegistry)).setNewRecord(getNodeId("alices-node.nec"));
//         assertEq(NDNSRegistry2(address(ndnsRegistry)).new_records(getNodeId("alices-node.nec")), true);
//     }
// }
