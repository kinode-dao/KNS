// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { TestUtils } from "./Utils.sol";

import { IQNS } from "../src/interfaces/IQNS.sol";
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
                        qnsRegistry,
                        getNodeId("uq")
                    )
                )
            )
        );

        assertEq(uqNft.owner(), address(deployer));
        // assertEq(uqNft.qns(), address(qnsRegistry)); // TODO not working
        assertEq(uqNft.baseNode(), getNodeId("uq"));
        assertEq(uqNft.name(), "Uqbar Name Service");
        assertEq(uqNft.symbol(), "UQNS");

        vm.prank(deployer);
        vm.expectEmit(true, false, false, true);
        emit NewSubdomainContract(getNodeId("uq"), getDNSWire("uq"), address(uqNft));
        qnsRegistry.registerSubdomainContract(
            getDNSWire("uq"),
            address(uqNft)
        );

        (address actualNft, uint32 actualProtocols) = qnsRegistry.records(getNodeId("uq."));

        assertEq(actualNft, address(uqNft));
        assertEq(actualProtocols, 0);
    }

    function test_register () public {
    }
}
