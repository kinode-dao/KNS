// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { TestUtils } from "./Utils.sol";

import { IQNS } from "../src/interfaces/IQNS.sol";
import { IQNSNFT } from "../src/interfaces/IQNSNFT.sol";
import { QNSRegistry } from "../src/QNSRegistry.sol";
import { UqNFT } from "../src/UqNFT.sol";
import "forge-std/console.sol";

contract QNSTest is TestUtils {
    // events
    event NewSubdomainContract(uint256 indexed node, bytes name, address nft);
    event NodeRegistered(uint256 indexed node, bytes name);
    event WsChanged(
        uint256 indexed node,
        uint32 indexed protocols,
        bytes32 publicKey,
        uint32 ip,
        uint16 port,
        bytes32[] routers
    );

    // addresses
    address public deployer = address(2);
    address public alice = address(3);
    address public bob = address(4);
    address public charlie = address(5);

    // contracts
    QNSRegistry public qnsRegistry;
    UqNFT public uqNft;
    UqNFT public uqNft2;

    // constants
    bytes32 constant _PUBKEY = bytes32(0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F);

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

        assertEq(uqNft.owner(), address(deployer));
        assertEq(address(uqNft.qns()), address(qnsRegistry));
        assertEq(uqNft.name(), "Uqbar Name Service");
        assertEq(uqNft.symbol(), "UQNS");

        vm.prank(deployer);
        vm.expectEmit(true, false, false, true);
        emit NewSubdomainContract(getNodeId("uq"), getDNSWire("uq"), address(uqNft));
        qnsRegistry.registerSubdomainContract(
            getDNSWire("uq"),
            IQNSNFT(uqNft)
        );

        assertEq(uqNft.baseNode(), getNodeId("uq"));

        (address actualNft, uint96 actualProtocols) = qnsRegistry.records(getNodeId("uq."));

        assertEq(actualNft, address(uqNft));
        assertEq(actualProtocols, 0);

        // used for registration tests
        vm.prank(deployer);
        UqNFT uqNft2Impl = new UqNFT();

        vm.prank(deployer);
        uqNft2 = UqNFT(
            address(
                new ERC1967Proxy(
                    address(uqNft2Impl),
                    abi.encodeWithSelector(
                        UqNFT.initialize.selector,
                        qnsRegistry
                    )
                )
            )
        );
    }

    function test_registerSubdomainContractFailsWhenNotOwner() public {
        vm.prank(alice);
        vm.expectRevert("QNSRegistry: only parent domain owner can register subdomain contract");
        qnsRegistry.registerSubdomainContract(
            getDNSWire("alices-tld"),
            IQNSNFT(uqNft2)
        );
    }

    function test_registerSubdomainContract() public {
        vm.prank(deployer);
        vm.expectEmit(true, false, false, true);
        emit NewSubdomainContract(getNodeId("new-tld"), getDNSWire("new-tld"), address(uqNft2));
        qnsRegistry.registerSubdomainContract(
            getDNSWire("new-tld"),
            uqNft2
        );

        (address actualNft, uint96 actualProtocols) = qnsRegistry.records(getNodeId("new-tld"));
        assertEq(actualNft, address(uqNft2));
        assertEq(actualProtocols, 0);
    }

    function test_registerNodeFailsWhenIsNotParent() public {
        vm.prank(alice);
        vm.expectRevert("QNSRegistry: only NFT contract can register node for a subdomain");
        qnsRegistry.registerNode(getDNSWire("test.uq"));
    }
    
    function test_registerNode() public {
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit NodeRegistered(getNodeId("alice.uq"), getDNSWire("alice.uq"));
        uqNft.register(getDNSWire("alice.uq"), alice);
        
        (address actualNft, uint96 actualProtocols) = qnsRegistry.records(getNodeId("alice.uq"));
        assertEq(actualNft, address(uqNft));
        assertEq(actualProtocols, 0);
    }

    function test_setWsRecordFailsWhenNotOwnerOrNft() public {
        vm.prank(alice);
        uqNft.register(getDNSWire("alice.uq"), alice);
        console.logBytes(getDNSWire("alice.uq"));

        vm.prank(bob);
        vm.expectRevert("QNSRegistry: only NFT contract or NFT owner can set ws records for a subdomain");
        qnsRegistry.setWsRecord(
            getNodeId("alice.uq"),
            bytes32(0),
            9004,
            9005,
            new bytes32[](0)
        );
    }

    function test_setWsRecordFailsWhenNotMinted() public {
        vm.prank(address(uqNft));
        vm.expectRevert();
        qnsRegistry.setWsRecord(
            getNodeId("alice.uq"),
            _PUBKEY,
            9004,
            9005,
            new bytes32[](0)
        );
    }

    function test_setWsRecordFailsWhenNotStaticOrRouted() public {
        vm.prank(alice);
        uqNft.register(getDNSWire("alice.uq"), alice);
        
        vm.prank(alice);
        vm.expectRevert("QNSRegistry: must specify either static ip/port or routers");
        qnsRegistry.setWsRecord(
            getNodeId("alice.uq"),
            _PUBKEY,
            0,
            0,
            new bytes32[](0)
        );
    }

    function test_setWsRecordFailsWhenPubKeyIsZero() public {
        vm.prank(alice);
        uqNft.register(getDNSWire("alice.uq"), alice);

        vm.prank(alice);
        vm.expectRevert("QNSRegistry: public key cannot be 0");
        qnsRegistry.setWsRecord(
            getNodeId("alice.uq"),
            bytes32(0),
            5,
            6,
            new bytes32[](0)
        );
    }

    function test_setWsRecordFailsWhenRouterDoesNotSupportWebSockets() public {
        vm.prank(deployer);
        uqNft.register(getDNSWire("uqbar-router-1.uq"), deployer);
        
        vm.prank(alice);
        uqNft.register(getDNSWire("alice.uq"), alice);
        
        bytes32[] memory routers = new bytes32[](1);
        routers[0] = bytes32(getNodeId("uqbar-router-1.uq"));
        
        vm.prank(alice);
        vm.expectRevert("QNSRegistry: router does not support websockets");
        qnsRegistry.setWsRecord(
            getNodeId("alice.uq"),
            _PUBKEY,
            0,
            0,
            routers
        );
    }

    function test_setWsRecordFailsWhenRouterHasNoIpAndPort() public {
        vm.prank(deployer);
        uqNft.register(getDNSWire("uqbar-router-1.uq"), deployer);
        vm.prank(deployer);
        qnsRegistry.setWsRecord(
            getNodeId("uqbar-router-1.uq"),
            _PUBKEY,
            1,
            1,
            new bytes32[](0)
        );

        bytes32[] memory router2Routers = new bytes32[](1);
        router2Routers[0] = bytes32(getNodeId("uqbar-router-1.uq"));

        vm.prank(deployer);
        uqNft.register(getDNSWire("uqbar-router-2.uq"), deployer);
        vm.prank(deployer);
        qnsRegistry.setWsRecord(
            getNodeId("uqbar-router-2.uq"),
            _PUBKEY,
            0,
            0,
            router2Routers
        );

        vm.prank(alice);
        uqNft.register(getDNSWire("alice.uq"), alice);
        
        bytes32[] memory aliceRouters = new bytes32[](1);
        aliceRouters[0] = bytes32(getNodeId("uqbar-router-2.uq"));
        
        vm.prank(alice);
        vm.expectRevert("QNSRegistry: router does not support websockets");
        qnsRegistry.setWsRecord(
            getNodeId("alice.uq"),
            _PUBKEY,
            0,
            0,
            aliceRouters
        );
    }

    function test_setWsRecordDirect() public {
        vm.prank(alice);
        uqNft.register(getDNSWire("alice.uq"), alice);

        vm.prank(alice);
        // TODO why are these broken
        // vm.expectEmit(true, true, false, true);
        // emit WsChanged(getNodeId("alice.uq"), 1, _PUBKEY, 65537, new bytes32[](0));
        qnsRegistry.setWsRecord(
            getNodeId("alice.uq"),
            _PUBKEY,
            1,
            1,
            new bytes32[](0)
        );

        IQNS.WsRecord memory wsRecord = qnsRegistry.ws(getNodeId("alice.uq"));
        assertEq(wsRecord.publicKey, _PUBKEY);
        assertEq(wsRecord.ip, 1);
        assertEq(wsRecord.port, 1);
        assertEq(wsRecord.routers.length, 0);
    }

    function test_setWsRecordIndirect() public {
        // set up router
        vm.prank(deployer);
        uqNft.register(getDNSWire("uqbar-router-1.uq"), deployer);
        vm.prank(deployer);
        qnsRegistry.setWsRecord(
            getNodeId("uqbar-router-1.uq"),
            _PUBKEY,
            9001,
            9002,
            new bytes32[](0)
        );

        vm.prank(alice);
        uqNft.register(getDNSWire("alice.uq"), alice);
        
        bytes32[] memory routers = new bytes32[](1);
        routers[0] = bytes32(getNodeId("uqbar-router-1.uq"));

        vm.prank(alice);
        // TODO why are these broken
        // vm.expectEmit(true, true, false, true);
        // emit WsChanged(getNodeId("alice.uq"), 1, _PUBKEY, 0, routers);
        qnsRegistry.setWsRecord(
            getNodeId("alice.uq"),
            _PUBKEY,
            0,
            0,
            routers
        );

        IQNS.WsRecord memory wsRecord = qnsRegistry.ws(getNodeId("alice.uq"));
        assertEq(wsRecord.publicKey, _PUBKEY);
        assertEq(wsRecord.ip, 0);
        assertEq(wsRecord.port, 0);
        assertEq(wsRecord.routers.length, 1);
    }

    function test_transferFromAndClearProtocols() public {
        vm.prank(alice);
        uqNft.register(getDNSWire("alice.uq"), alice);
        
        vm.prank(alice);
        qnsRegistry.setWsRecord(
            getNodeId("alice.uq"),
            _PUBKEY,
            9001,
            9002,
            new bytes32[](0)
        );

        vm.prank(alice);
        uqNft.transferFromAndClearProtocols(alice, bob, getNodeId("alice.uq"));

        vm.expectRevert("QNSRegistry: node does not support websockets");
        qnsRegistry.ws(getNodeId("alice.uq"));
    }
}
