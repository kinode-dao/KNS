// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { TestUtils } from "./Utils.sol";

import { IQNS } from "../src/interfaces/IQNS.sol";
import { QNSRegistry } from "../src/QNSRegistry.sol";
import { UqNFT } from "../src/UqNFT.sol";
import "forge-std/console.sol";

contract QNSTest is TestUtils {
    // events
    event NewTld(uint256 indexed node, bytes name, address nft);

    // addresses
    address public deployer = address(2);
    address public alice = address(3);
    address public bob = address(4);
    address public charlie = address(5);

    // contracts
    QNSRegistry public qnsRegistry;
    UqNFT public uqNft;

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

        vm.prank(deployer);
        UqNFT uqNftImpl = new UqNFT();

        vm.prank(deployer);
        uqNft = UqNFT(
            address(
                new ERC1967Proxy(
                    address(uqNftImpl),
                    abi.encodeWithSelector(
                        UqNFT.initialize.selector,
                        qnsRegistry,
                        getNodeId("uq")
                    )
                )
            )
        );

        vm.prank(deployer);
        vm.expectEmit(true, false, false, true);
        emit NewTld(getNodeId("uq"), getDNSWire("uq"), address(uqNft));
        qnsRegistry.newTld(
            getDNSWire("uq"),
            address(uqNft)
        );

        (address actualNft, uint32 actualProtocols) = qnsRegistry.records(getNodeId("uq."));

        assertEq(actualNft, address(uqNft));
        assertEq(actualProtocols, 0);
    }

    function test_newTldFailsWhenNotOwner () public {
        vm.prank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        qnsRegistry.newTld(
            getDNSWire("alices-tld"),
            address(9001)
        );
    }

    function test_newTldFailsWhenUsingSubdomain() public {
        vm.prank(deployer);
        vm.expectRevert("QNSRegistry: cannot register subdomain using newTld");
        qnsRegistry.newTld(
            getDNSWire("a.b"),
            address(9001)
        );
    }

    function test_newTld () public {
        vm.prank(deployer);
        vm.expectEmit(true, false, false, true);
        emit NewTld(getNodeId("new-tld"), getDNSWire("new-tld"), address(9001));
        qnsRegistry.newTld(
            getDNSWire("new-tld"),
            address(9001)
        );

        (address actualNft, uint32 actualProtocols) = qnsRegistry.records(getNodeId("new-tld"));
        assertEq(actualNft, address(9001));
        assertEq(actualProtocols, 0);
    }

    function test_setProtocolsFailsWhenIsNotParent () public {
        vm.prank(alice);
        vm.expectRevert("QNSRegistry: only parent NFT contract can setRecords for a subdomain");
        qnsRegistry.setProtocols(getDNSWire("test.uq"), 0);
    }

    function test_setProtocolsFailsWhenNftNotMinted() public {
        vm.prank(address(uqNft));
        vm.expectRevert("ERC721: invalid token ID");
        qnsRegistry.setProtocols(getDNSWire("test.uq"), 0);
    }
    
    function test_setProtocols () public {
        // check records
        // check event was emitted
    }

    function test_setWsRecordFailsWhenNotAuthorized () public {
        vm.prank(charlie);
    }

    function test_setWsRecordFailsWhenNotStaticOrRouted () public {
    }

    function test_setWsRecord () public {
        // check ws_records
        // check event was emitted
    }
}
