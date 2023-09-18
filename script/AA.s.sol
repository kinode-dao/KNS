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

        // vm.etch(
        //     vm.envAddress("AA_ENTRYPOINT"),
        //     address(new EntryPoint()).code
        // );

        vm.etch(
            0x7fc98430eAEdbb6070B35B39D798725049088348, 
            address(new SenderCreator()).code
        );

        uint privk = vm.envUint("SNAKE");
        address payable pubk  = payable(vm.rememberKey(privk));

        console.log("pubkb", pubk, pubk.balance, block.chainid);

        vm.startBroadcast(privk);

        IEntryPoint entrypoint = IEntryPoint(vm.envAddress("AA_ENTRYPOINT"));

        SimpleAccountFactory simpleAccountFactory = 
            new SimpleAccountFactory(vm.envAddress("AA_ENTRYPOINT"));

        address walletAddr = simpleAccountFactory.getAddress(pubk, 1);

        entrypoint.depositTo{value: 1 ether}(walletAddr);

        IStakeManager.DepositInfo memory depositInfo = entrypoint.getDepositInfo(pubk);

        console.log("walletAddr", walletAddr);

        // vm.deal(walletAddr, 100 ether);


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
            callGasLimit: 22017,
            verificationGasLimit: 958666,
            preVerificationGas: 115256,
            maxFeePerGas: 1000105660,
            maxPriorityFeePerGas: 1000000000,
            paymasterAndData: "",
            signature: ""
        });

        // VerifyingPaymaster verifyingPaymaster = new VerifyingPaymaster(
        //     address(entrypoint),
        //     paymasterPub
        // );

        // bytes32 digest = ECDSA.toEthSignedMessageHash(
        //     verifyingPaymaster.getHash(
        //         userOp,
        //         uint48(block.timestamp),
        //         uint48(block.timestamp + 200000)
        //     )
        // );

        // (uint8 v, bytes32 r, bytes32 s) = vm.sign(paymasterPriv, digest);

        // userOp.paymasterAndData = abi.encodePacked(
        //     paymasterPub,
        //     uint48(block.timestamp),
        //     uint48(block.timestamp + 200000),
        //     bytes.concat(r,s,bytes1(v))
        // );

        bytes32 digest = ECDSA.toEthSignedMessageHash(entrypoint.getUserOpHash(userOp));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privk, digest);
        userOp.signature = bytes.concat(r, s, bytes1(v));

        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = userOp;

        entrypoint.handleOps(ops, pubk);

        // console.log("deposit", di.deposit);
        // console.log("staked", di.staked);
        // console.log("stake", di.stake);
        // console.log("unstakeDelaySec", di.unstakeDelaySec);
        // console.log("withdrawTime", di.withdrawTime);
        // console.log("simple account factory", address(simpleAccountFactory));

        // // DepositPaymaster depositPaymasterr = new DepositPaymaster(entrypoint);

        // vm.stopBroadcast();

    }

}