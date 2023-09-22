// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { TestUtils } from "./Utils.sol";

import { IQNS } from "../src/interfaces/IQNS.sol";
import { IQNSNFT } from "../src/interfaces/IQNSNFT.sol";
import { QNSRegistry } from "../src/QNSRegistry.sol";
import { UqNFT } from "../src/UqNFT.sol";
import "forge-std/console.sol";

error MustChooseStaticOrRouted();

contract QNSTest is TestUtils {
    // events
    event NewSubdomainContract(uint256 indexed node, bytes name, address nft);
    event NodeRegistered(uint256 indexed node, bytes name);
    event WsChanged(
        uint256 indexed node,
        uint32 indexed protocols,
        bytes32 publicKey,
        uint48 ipAndPort,
        bytes32[] routers // TODO maybe string?
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
        // assertEq(uqNft.qns(), address(qnsRegistry)); // TODO not working
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

        (address actualNft, uint32 actualProtocols) = qnsRegistry.records(getNodeId("uq."));

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

        (address actualNft, uint32 actualProtocols) = qnsRegistry.records(getNodeId("new-tld"));
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
        
        (address actualNft, uint32 actualProtocols) = qnsRegistry.records(getNodeId("alice.uq"));
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
        // TODO reason isn't correct for some reason? Should be:
        // "QNSRegistry: only NFT contract or NFT owner can set a records for a subdomain"
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
        vm.expectRevert(); // TODO MustChooseStaticOrRouted
        qnsRegistry.setWsRecord(
            getNodeId("alice.uq"),
            bytes32(0),
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

    function test_setWsRecordDirect() public {
        vm.prank(alice);
        uqNft.register(getDNSWire("alice.uq"), alice);

        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit WsChanged(getNodeId("alice.uq"), 1, _PUBKEY, 65537, new bytes32[](0));
        qnsRegistry.setWsRecord(
            getNodeId("alice.uq"),
            _PUBKEY,
            1,
            1,
            new bytes32[](0)
        );

        IQNS.WsRecord memory wsRecord = qnsRegistry.ws(getNodeId("alice.uq"));
        assertEq(wsRecord.publicKey, _PUBKEY);
        assertEq(wsRecord.ipAndPort, 65537);
        assertEq(wsRecord.routers.length, 0);
    }

    function test_setWsRecordIndirect() public {
        vm.prank(alice);
        uqNft.register(getDNSWire("alice.uq"), alice);
        
        bytes32[] memory routers = new bytes32[](1);
        routers[0] = bytes32(getNodeId("rolr1.uq"));

        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit WsChanged(getNodeId("alice.uq"), 1, _PUBKEY, 0, routers);
        qnsRegistry.setWsRecord(
            getNodeId("alice.uq"),
            _PUBKEY,
            0,
            0,
            routers
        );

        IQNS.WsRecord memory wsRecord = qnsRegistry.ws(getNodeId("alice.uq"));
        assertEq(wsRecord.publicKey, _PUBKEY);
        assertEq(wsRecord.ipAndPort, 0);
        assertEq(wsRecord.routers.length, 1);
    }

    function test_clearWsRecordCannotReadWs() public {
        vm.prank(alice);
        uqNft.register(getDNSWire("alice.uq"), alice);
        
        bytes32[] memory routers = new bytes32[](1);
        routers[0] = bytes32(getNodeId("rolr1.uq"));

        vm.prank(alice);
        qnsRegistry.setWsRecord(
            getNodeId("alice.uq"),
            _PUBKEY,
            0,
            0,
            routers
        );

        vm.prank(alice);
        uqNft.transferFrom(alice, bob, getNodeId("alice.uq"));

        vm.expectRevert("QNSRegistry: node does not support websockets");
        qnsRegistry.ws(getNodeId("alice.uq"));
    }
}
