// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import { UserOperation, UserOperationLib } from "../src/aa/interfaces/UserOperation.sol";
import { DepositPaymaster } from "../src/aa/samples/DepositPaymaster.sol";
import { VerifyingPaymaster } from "../src/aa/samples/VerifyingPaymaster.sol";
import { BaseAccount } from "../src/aa/core/BaseAccount.sol";
import { SimpleAccount } from "../src/aa/samples/SimpleAccount.sol";
import { SimpleAccountFactory } from "../src/aa/samples/SimpleAccountFactory.sol";
import { IEntryPoint } from "../src/aa/interfaces/IEntrypoint.sol";
import { IStakeManager } from "../src/aa/interfaces/IStakeManager.sol";

import { EntryPoint } from "../src/aa/core/EntryPoint.sol";
import { SenderCreator } from "../src/aa/core/SenderCreator.sol";

contract AAScript is Script {

    function setUp() public {}

    string mnemonic = "test test test test test test test test test test test junk";
    uint paymasterPriv;
    address paymasterPub;

    function run() public {

        paymasterPriv = vm.deriveKey(mnemonic, 0);
        paymasterPub = vm.rememberKey(paymasterPriv);

        uint privk = vm.envUint("SNAKE");
        address payable pubk  = payable(vm.rememberKey(privk));

        vm.startBroadcast(privk);

        IEntryPoint entrypoint = IEntryPoint(vm.envAddress("AA_ENTRYPOINT"));

        SimpleAccountFactory simpleAccountFactory = 
            new SimpleAccountFactory(vm.envAddress("AA_ENTRYPOINT"));

        address walletAddr = simpleAccountFactory.getAddress(pubk, 1);

        if (entrypoint.balanceOf(walletAddr) == 0)
            entrypoint.depositTo{value: 1 ether}(walletAddr);

        UserOperation memory userOp = UserOperation({
            sender: walletAddr,
            nonce: 0,
            initCode: abi.encodePacked(
                address(simpleAccountFactory),
                abi.encodeWithSelector(
                    SimpleAccountFactory.createAccount.selector,
                    pubk,
                    1
                )
            ),
            callData: "",
            callGasLimit: 30000,
            verificationGasLimit: 2000000,
            preVerificationGas: 600000,
            maxFeePerGas: 1000000000,
            maxPriorityFeePerGas: 1000000000,
            paymasterAndData: "",
            signature: ""
        });

        VerifyingPaymaster verifyingPaymaster = new VerifyingPaymaster(
            address(entrypoint),
            paymasterPub
        );

        bytes32 digest = ECDSA.toEthSignedMessageHash(
            verifyingPaymaster.getHash(
                userOp,
                uint48(block.timestamp + 200000),
                uint48(block.timestamp)
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(paymasterPriv, digest);

        userOp.paymasterAndData = abi.encodePacked(
            address(verifyingPaymaster),
            abi.encode(
                uint48(block.timestamp + 200000),
                uint48(block.timestamp)
            ),
            bytes.concat(r,s,bytes1(v))
        );

        digest = ECDSA.toEthSignedMessageHash(entrypoint.getUserOpHash(userOp));

        (v, r, s) = vm.sign(privk, digest);
        userOp.signature = bytes.concat(r, s, bytes1(v));

        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = userOp;

        entrypoint.depositTo{value: 1 ether}(address(verifyingPaymaster));

        entrypoint.handleOps(ops, pubk);

    }

}

contract DepositToPaymaster is Script {

    function run () public {

        IEntryPoint entrypoint = IEntryPoint(vm.envAddress("AA_ENTRYPOINT"));

        address paymaster = vm.envAddress("AA_VERIFYING_PAYMASTER");

        vm.startBroadcast();

        entrypoint.depositTo{value: .1 ether}(paymaster);

        vm.stopBroadcast();

    }

}

contract DeployVerifyingPaymaster is Script {

    function run () public {

        uint256 paymasterPriv = vm.envUint("PRIV_PAYMASTER");
        address paymasterPub = vm.envAddress("PUB_PAYMASTER");

        IEntryPoint entrypoint = IEntryPoint(vm.envAddress("AA_ENTRYPOINT"));

        vm.startBroadcast();

        VerifyingPaymaster verifyingPaymaster = new VerifyingPaymaster(
            address(entrypoint),
            paymasterPub
        );

        vm.stopBroadcast();

    }
}