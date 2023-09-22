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
    event ProtocolsChanged(uint256 indexed node, bytes name, uint32 protocols);
    event WsChanged(
        uint256 indexed node,
        bytes32 publicKey,
        uint48 ipAndPort,
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

    //
    // subdomain tests
    //

    function test_cannotRegister3LTLDFromUqNftUsingRegister() public {
        vm.prank(alice);
        uqNft.register(getDNSWire("uq.uq"), alice);
        
        vm.prank(alice);
        vm.expectRevert("UqNFT: only subdomains of baseNode can be registered");
        uqNft.register(getDNSWire("sub.uq.uq"), alice);
    }

    function test_cannotRegister3LTLDDirectToRegistry() public {
        vm.prank(alice);
        uqNft.register(getDNSWire("alice.uq"), alice);
        
        vm.prank(alice);
        vm.expectRevert("QNSRegistry: only parent domain owner can register subdomain contract");
        qnsRegistry.registerSubdomainContract(getDNSWire("alice.uq"), IQNSNFT(uqNft2));
    }

    function test_allowSubdomainsFailsWhenNot2LTLD() public {
        vm.prank(alice);
        uqNft.register(getDNSWire("alice.uq"), alice);

        vm.prank(alice);
        vm.expectRevert("UqNFT: only subdomains of baseNode can be registered");
        uqNft.allowSubdomains(getDNSWire("sub.alice.uq"), IQNSNFT(uqNft));
    }

    function test_allowSubdomainsFailsWhenNotOwner() public {
        vm.prank(alice);
        uqNft.register(getDNSWire("alice.uq"), alice);

        vm.prank(bob);
        vm.expectRevert("UqNFT: only owner of node can allow subdomains");
        uqNft.allowSubdomains(getDNSWire("alice.uq"), IQNSNFT(uqNft));
    }

    function test_allowSubdomains() public {
        // register alice.uq
        vm.prank(alice);
        uqNft.register(getDNSWire("alice.uq"), alice);

        // allow subdomains on alice.uq
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit NewSubdomainContract(getNodeId("alice.uq"), getDNSWire("alice.uq"), address(uqNft2));
        uqNft.allowSubdomains(getDNSWire("alice.uq"), IQNSNFT(uqNft2));

        // check all on-chain data about alice.uq is updated
        (address actualNft, uint96 actualProtocols) = qnsRegistry.records(getNodeId("alice.uq"));
        assertEq(actualNft, address(uqNft2));
        assertEq(actualProtocols, 0);
        assertEq(uqNft2.baseNode(), getNodeId("alice.uq"));

        // try to register subdomain on alice.uq
        vm.prank(alice);
        uqNft2.register(getDNSWire("sub.alice.uq"), alice);

        (address actualSubNft, uint96 actualSubProtocols) = qnsRegistry.records(getNodeId("alice.uq"));
        assertEq(actualSubNft, address(uqNft2));
        assertEq(actualSubProtocols, 0);
    }
}