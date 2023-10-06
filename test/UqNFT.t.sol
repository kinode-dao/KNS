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
    event WsChanged(
        uint256 indexed node,
        uint96 indexed protocols,
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

    //
    // setBaseNode tests
    //

    function test_setBaseNodeFailsIfNotQNS() public {
        vm.prank(alice);
        vm.expectRevert("UqNFT: only QNS can set baseNode");
        uqNft2.setBaseNode(getNodeId("uq"));
    }

    function test_setBaseNodeFailsIfAlreadySet() public {
        vm.prank(address(qnsRegistry));
        vm.expectRevert("UqNFT: baseNode already set");
        uqNft.setBaseNode(getNodeId("uq"));
    }

    // register tests
    function test_registerFailsIfNameTooShort() public {
        vm.prank(alice);
        vm.expectRevert("UqNFT: name must be at least 9 characters long");
        uqNft.register(getDNSWire("test.uq"), alice, new bytes[](0));
    }

    //
    // subdomain tests
    //

    function test_cannotRegister3LTLDFromUqNftUsingRegister() public {
        vm.prank(alice);
        uqNft.register(getDNSWire("testinguq.uq"), alice, new bytes[](0));
        
        vm.prank(alice);
        vm.expectRevert("UqNFT: only subdomains of baseNode can be registered");
        uqNft.register(getDNSWire("testingsub.testinguq.uq"), alice, new bytes[](0));
    }

    function test_cannotRegister3LTLDDirectToRegistry() public {
        vm.prank(alice);
        uqNft.register(getDNSWire("alices-node.uq"), alice, new bytes[](0));
        
        vm.prank(alice);
        vm.expectRevert("QNSRegistry: only parent domain owner can register subdomain contract");
        qnsRegistry.registerSubdomainContract(getDNSWire("alices-node.uq"), IQNSNFT(uqNft2));
    }

    function test_allowSubdomainsFailsWhenNot2LTLD() public {
        vm.prank(alice);
        uqNft.register(getDNSWire("alices-node.uq"), alice, new bytes[](0));

        vm.prank(alice);
        vm.expectRevert("UqNFT: only subdomains of baseNode can be registered");
        uqNft.allowSubdomains(getDNSWire("sub.alices-node.uq"), IQNSNFT(uqNft));
    }

    function test_allowSubdomainsFailsWhenNotOwner() public {
        vm.prank(alice);
        uqNft.register(getDNSWire("alices-node.uq"), alice, new bytes[](0));

        vm.prank(bob);
        vm.expectRevert("UqNFT: only owner of node can allow subdomains");
        uqNft.allowSubdomains(getDNSWire("alices-node.uq"), IQNSNFT(uqNft));
    }

    function test_allowSubdomains() public {
        // register alices-node.uq
        vm.prank(alice);
        uqNft.register(getDNSWire("alices-node.uq"), alice, new bytes[](0));

        // allow subdomains on alices-node.uq
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit NewSubdomainContract(getNodeId("alices-node.uq"), getDNSWire("alices-node.uq"), address(uqNft2));
        uqNft.allowSubdomains(getDNSWire("alices-node.uq"), IQNSNFT(uqNft2));

        // check all on-chain data about alices-node.uq is updated
        (address actualNft, uint96 actualProtocols) = qnsRegistry.records(getNodeId("alices-node.uq"));
        assertEq(actualNft, address(uqNft2));
        assertEq(actualProtocols, 0);
        assertEq(uqNft2.baseNode(), getNodeId("alices-node.uq"));

        // try to register subdomain on alice.uq
        vm.prank(bob);
        uqNft2.register(getDNSWire("bob.alices-node.uq"), bob, new bytes[](0));

        (address actualSubNft, uint96 actualSubProtocols) = qnsRegistry.records(getNodeId("alices-node.uq"));
        assertEq(actualSubNft, address(uqNft2));
        assertEq(actualSubProtocols, 0);

        // assert ownership information is still correct
        assertEq(bob, qnsRegistry.resolve(getDNSWire("bob.alices-node.uq")));
        assertEq(alice, qnsRegistry.resolve(getDNSWire("alices-node.uq")));
    }

    function testRegisterWithSettingWebsockets () public {

        bytes[] memory records = new bytes[](1);
        records[0] = abi.encodeWithSelector(
            IQNS.setWsRecord.selector,
            getNodeId("alices-node.uq"),
            bytes32("0x1"),
            uint32(1),
            uint16(1),
            new bytes32[](0)
        );

        vm.prank(alice);
        vm.expectEmit(true, false, false, false);
        emit WsChanged(getNodeId("alices-node.uq"), uint96(1), bytes32("0x1"), uint32(1), uint16(1), new bytes32[](0));
        uqNft.register(getDNSWire("alices-node.uq"), alice, records);
        assertEq(alice, qnsRegistry.resolve(getDNSWire("alices-node.uq")));

    }

    function testMulticallDoesNotAllowAlterationsOfAnothersRecord () public {

        uint alicesNodeId = getNodeId("alices-node.uq");
        uint bobsNodeId = getNodeId("bobs-node.uq");

        vm.prank(alice);
        uqNft.register(getDNSWire("alices-node.uq"), alice, new bytes[](0));

        bytes[] memory records = new bytes[](2);

        records[0] = abi.encodeWithSelector(
            IQNS.setWsRecord.selector,
            bobsNodeId,
            bytes32("0x1"),
            uint32(1),
            uint16(1),
            new bytes32[](0)
        );

        records[1] = abi.encodeWithSelector(
            IQNS.setWsRecord.selector,
            alicesNodeId,
            bytes32("0x1"),
            uint32(1),
            uint16(1),
            new bytes32[](0)
        );

        vm.prank(bob);
        vm.expectRevert();
        uqNft.register(getDNSWire("bobs-node.uq"), bob, records);

        bytes[] memory recordsForSuccess = new bytes[](1);
        recordsForSuccess[0] = records[0];

        uqNft.register(getDNSWire("bobs-node.uq"), bob, recordsForSuccess);
        assertEq(bob, qnsRegistry.resolve(getDNSWire("bobs-node.uq")));

    }
}
