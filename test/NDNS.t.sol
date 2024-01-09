// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// import { TestUtils } from "./Utils.sol";

// import { INDNS } from "../src/interfaces/INDNS.sol";
// import { INDNSNFT } from "../src/interfaces/INDNSNFT.sol";
// import { NDNSRegistry } from "../src/NDNSRegistry.sol";
// import { UqNFT } from "../src/UqNFT.sol";
// import "forge-std/console.sol";

// contract NDNSTest is TestUtils {
//     // events
//     event NewSubdomainContract(uint256 indexed node, bytes name, address nft);
//     event NodeRegistered(uint256 indexed node, bytes name);
//     event ProtocolsCleared(uint256 indexed node);
//     event WsChanged(
//         uint256 indexed node,
//         uint32 indexed protocols,
//         bytes32 publicKey,
//         uint32 ip,
//         uint16 port,
//         bytes32[] routers
//     );

//     // addresses
//     address public deployer = address(2);
//     address public alice = address(3);
//     address public bob = address(4);
//     address public charlie = address(5);

//     // contracts
//     NDNSRegistry public ndnsRegistry;
//     UqNFT public uqNft;
//     UqNFT public uqNft2;

//     // constants
//     bytes32 constant _PUBKEY = bytes32(0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F);

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

//         assertEq(uqNft.owner(), address(deployer));
//         assertEq(address(uqNft.ndns()), address(ndnsRegistry));
//         assertEq(uqNft.name(), "Uqbar Name Service");
//         assertEq(uqNft.symbol(), "UNDNS");

//         vm.prank(deployer);
//         vm.expectEmit(true, false, false, true);
//         emit NewSubdomainContract(getNodeId("nec"), getDNSWire("nec"), address(uqNft));
//         ndnsRegistry.registerSubdomainContract(
//             getDNSWire("nec"),
//             INDNSNFT(uqNft)
//         );

//         assertEq(uqNft.baseNode(), getNodeId("nec"));

//         (address actualNft, uint96 actualProtocols) = ndnsRegistry.records(getNodeId("uq."));

//         assertEq(actualNft, address(uqNft));
//         assertEq(actualProtocols, 0);

//         // used for registration tests
//         vm.prank(deployer);
//         UqNFT uqNft2Impl = new UqNFT();

//         vm.prank(deployer);
//         uqNft2 = UqNFT(
//             address(
//                 new ERC1967Proxy(
//                     address(uqNft2Impl),
//                     abi.encodeWithSelector(
//                         UqNFT.initialize.selector,
//                         ndnsRegistry
//                     )
//                 )
//             )
//         );
//     }

//     function test_registerSubdomainContractFailsWhenNotOwner() public {
//         vm.prank(alice);
//         vm.expectRevert("NDNSRegistry: only parent domain owner can register subdomain contract");
//         ndnsRegistry.registerSubdomainContract(
//             getDNSWire("alices-tld"),
//             INDNSNFT(uqNft2)
//         );
//     }

//     function test_registerSubdomainContract() public {
//         vm.prank(deployer);
//         vm.expectEmit(true, false, false, true);
//         emit NewSubdomainContract(getNodeId("new-tld"), getDNSWire("new-tld"), address(uqNft2));
//         ndnsRegistry.registerSubdomainContract(
//             getDNSWire("new-tld"),
//             uqNft2
//         );

//         (address actualNft, uint96 actualProtocols) = ndnsRegistry.records(getNodeId("new-tld"));
//         assertEq(actualNft, address(uqNft2));
//         assertEq(actualProtocols, 0);
//     }

//     function test_registerNodeFailsWhenIsNotParent() public {
//         vm.prank(alice);
//         vm.expectRevert("NDNSRegistry: only NFT contract can register node for a subdomain");
//         ndnsRegistry.registerNode(getDNSWire("test.nec"));
//     }
    
//     function test_registerNode() public {
//         vm.prank(alice);
//         vm.expectEmit(true, false, false, true);
//         emit NodeRegistered(getNodeId("alices-node.nec"), getDNSWire("alices-node.nec"));
//         uqNft.register(getDNSWire("alices-node.nec"), alice, new bytes[](0));
        
//         (address actualNft, uint96 actualProtocols) = ndnsRegistry.records(getNodeId("alices-node.nec"));
//         assertEq(actualNft, address(uqNft));
//         assertEq(actualProtocols, 0);
//     }

//     function test_setWsRecordFailsWhenNotOwnerOrNft() public {
//         vm.prank(alice);
//         uqNft.register(getDNSWire("alices-node.nec"), alice, new bytes[](0));
//         console.logBytes(getDNSWire("alices-node.nec"));

//         vm.prank(bob);
//         vm.expectRevert("NDNSRegistry: only NFT contract or NFT owner can set ws records for a subdomain");
//         ndnsRegistry.setWsRecord(
//             getNodeId("alices-node.nec"),
//             bytes32(0),
//             9004,
//             9005,
//             new bytes32[](0)
//         );
//     }

//     function test_setWsRecordFailsWhenNotMinted() public {
//         vm.prank(address(uqNft));
//         vm.expectRevert();
//         ndnsRegistry.setWsRecord(
//             getNodeId("alices-node.nec"),
//             _PUBKEY,
//             9004,
//             9005,
//             new bytes32[](0)
//         );
//     }

//     function test_setWsRecordFailsWhenNotStaticOrRouted() public {
//         vm.prank(alice);
//         uqNft.register(getDNSWire("alices-node.nec"), alice, new bytes[](0));
        
//         vm.prank(alice);
//         vm.expectRevert("NDNSRegistry: must specify either static ip/port or routers");
//         ndnsRegistry.setWsRecord(
//             getNodeId("alices-node.nec"),
//             _PUBKEY,
//             0,
//             0,
//             new bytes32[](0)
//         );
//     }

//     function test_setWsRecordFailsWhenPubKeyIsZero() public {
//         vm.prank(alice);
//         uqNft.register(getDNSWire("alices-node.nec"), alice, new bytes[](0));

//         vm.prank(alice);
//         vm.expectRevert("NDNSRegistry: public key cannot be 0");
//         ndnsRegistry.setWsRecord(
//             getNodeId("alices-node.nec"),
//             bytes32(0),
//             5,
//             6,
//             new bytes32[](0)
//         );
//     }

//     function test_setWsRecordFailsWhenRouterDoesNotSupportWebSockets() public {
//         vm.prank(deployer);
//         uqNft.register(getDNSWire("uqbar-router-1.nec"), deployer, new bytes[](0));
        
//         vm.prank(alice);
//         uqNft.register(getDNSWire("alices-node.nec"), alice, new bytes[](0));
        
//         bytes32[] memory routers = new bytes32[](1);
//         routers[0] = bytes32(getNodeId("uqbar-router-1.nec"));
        
//         vm.prank(alice);
//         vm.expectRevert("NDNSRegistry: router does not support websockets");
//         ndnsRegistry.setWsRecord(
//             getNodeId("alices-node.nec"),
//             _PUBKEY,
//             0,
//             0,
//             routers
//         );
//     }

//     function test_setWsRecordFailsWhenRouterHasNoIpAndPort() public {
//         vm.prank(deployer);
//         uqNft.register(getDNSWire("uqbar-router-1.nec"), deployer, new bytes[](0));
//         vm.prank(deployer);
//         ndnsRegistry.setWsRecord(
//             getNodeId("uqbar-router-1.nec"),
//             _PUBKEY,
//             1,
//             1,
//             new bytes32[](0)
//         );

//         bytes32[] memory router2Routers = new bytes32[](1);
//         router2Routers[0] = bytes32(getNodeId("uqbar-router-1.nec"));

//         vm.prank(deployer);
//         uqNft.register(getDNSWire("uqbar-router-2.nec"), deployer, new bytes[](0));
//         vm.prank(deployer);
//         ndnsRegistry.setWsRecord(
//             getNodeId("uqbar-router-2.nec"),
//             _PUBKEY,
//             0,
//             0,
//             router2Routers
//         );

//         vm.prank(alice);
//         uqNft.register(getDNSWire("alices-node.nec"), alice, new bytes[](0));
        
//         bytes32[] memory aliceRouters = new bytes32[](1);
//         aliceRouters[0] = bytes32(getNodeId("uqbar-router-2.nec"));
        
//         vm.prank(alice);
//         vm.expectRevert("NDNSRegistry: router does not support websockets");
//         ndnsRegistry.setWsRecord(
//             getNodeId("alices-node.nec"),
//             _PUBKEY,
//             0,
//             0,
//             aliceRouters
//         );
//     }

//     function test_setWsRecordDirect() public {
//         vm.prank(alice);
//         uqNft.register(getDNSWire("alices-node.nec"), alice, new bytes[](0));

//         vm.prank(alice);
//         // TODO why are these broken
//         // vm.expectEmit(true, true, false, true);
//         // emit WsChanged(getNodeId("alices-node.nec"), 1, _PUBKEY, 65537, new bytes32[](0));
//         ndnsRegistry.setWsRecord(
//             getNodeId("alices-node.nec"),
//             _PUBKEY,
//             1,
//             1,
//             new bytes32[](0)
//         );

//         INDNS.WsRecord memory wsRecord = ndnsRegistry.ws(getNodeId("alices-node.nec"));
//         assertEq(wsRecord.publicKey, _PUBKEY);
//         assertEq(wsRecord.ip, 1);
//         assertEq(wsRecord.port, 1);
//         assertEq(wsRecord.routers.length, 0);
//     }

//     function test_setWsRecordIndirect() public {
//         // set up router
//         vm.prank(deployer);
//         uqNft.register(getDNSWire("uqbar-router-1.nec"), deployer, new bytes[](0));
//         vm.prank(deployer);
//         ndnsRegistry.setWsRecord(
//             getNodeId("uqbar-router-1.nec"),
//             _PUBKEY,
//             9001,
//             9002,
//             new bytes32[](0)
//         );

//         vm.prank(alice);
//         uqNft.register(getDNSWire("alices-node.nec"), alice, new bytes[](0));
        
//         bytes32[] memory routers = new bytes32[](1);
//         routers[0] = bytes32(getNodeId("uqbar-router-1.nec"));

//         vm.prank(alice);
//         // TODO why are these broken
//         // vm.expectEmit(true, true, false, true);
//         // emit WsChanged(getNodeId("alices-node.nec"), 1, _PUBKEY, 0, routers);
//         ndnsRegistry.setWsRecord(
//             getNodeId("alices-node.nec"),
//             _PUBKEY,
//             0,
//             0,
//             routers
//         );

//         INDNS.WsRecord memory wsRecord = ndnsRegistry.ws(getNodeId("alices-node.nec"));
//         assertEq(wsRecord.publicKey, _PUBKEY);
//         assertEq(wsRecord.ip, 0);
//         assertEq(wsRecord.port, 0);
//         assertEq(wsRecord.routers.length, 1);
//     }

//     function test_transferFromAndClearProtocols() public {
//         vm.prank(alice);
//         uqNft.register(getDNSWire("alices-node.nec"), alice, new bytes[](0));
        
//         vm.prank(alice);
//         ndnsRegistry.setWsRecord(
//             getNodeId("alices-node.nec"),
//             _PUBKEY,
//             9001,
//             9002,
//             new bytes32[](0)
//         );

//         vm.prank(alice);
//         vm.expectEmit(true, false, false, false);
//         emit ProtocolsCleared(getNodeId("alices-node.nec"));
//         uqNft.transferFromAndClearProtocols(alice, bob, getNodeId("alices-node.nec"));

//         vm.expectRevert("NDNSRegistry: node does not support websockets");
//         ndnsRegistry.ws(getNodeId("alices-node.nec"));
//     }

//     function test_resolveFailsWhenNodeNotRegistered() public {
//         vm.expectRevert("ERC721: invalid token ID");
//         ndnsRegistry.resolve(getDNSWire("alices-node.nec"));
//     }

//     function test_resolveFailsWhenNodeNotRegistered3LD() public {
//         vm.prank(alice);
//         uqNft.register(getDNSWire("alices-node.nec"), alice, new bytes[](0));

//         vm.expectRevert("ERC721: invalid token ID");
//         ndnsRegistry.resolve(getDNSWire("sub.alices-node.nec"));
//     }

//     function test_resolveTLDFailsAlways() public {
//         vm.expectRevert();
//         ndnsRegistry.resolve(getDNSWire("nec"));
//     }

//     function test_resolve() public {
//         vm.prank(alice);
//         uqNft.register(getDNSWire("alices-node.nec"), alice, new bytes[](0));

//         assertEq(ndnsRegistry.resolve(getDNSWire("alices-node.nec")), alice);
//     }

//     function test_resolve3LD() public {
//         vm.prank(alice);
//         uqNft.register(getDNSWire("alices-node.nec"), alice, new bytes[](0));

//         vm.prank(alice);
//         uqNft.allowSubdomains(getDNSWire("alices-node.nec"), uqNft2);

//         vm.prank(bob);
//         uqNft2.register(getDNSWire("bob.alices-node.nec"), bob, new bytes[](0));

//         assertEq(ndnsRegistry.resolve(getDNSWire("bob.alices-node.nec")), bob);
//     }
// }
