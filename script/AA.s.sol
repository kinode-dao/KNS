// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import {Script, console} from "forge-std/Script.sol";

// // import { UserOperation, UserOperationLib } from "aa/interfaces/UserOperation.sol";
// // import { DepositPaymaster } from "aa/samples/DepositPaymaster.sol";
// // import { VerifyingPaymaster } from "aa/samples/VerifyingPaymaster.sol";
// // import { BaseAccount } from "aa/core/BaseAccount.sol";
// // import { SimpleAccount } from "aa/samples/SimpleAccount.sol";
// // import { SimpleAccountFactory } from "aa/samples/SimpleAccountFactory.sol";
// // import { IEntryPoint } from "aa/interfaces/IEntrypoint.sol";

// import { UserOperation, UserOperationLib } from "account-abstraction/interfaces/UserOperation.sol";
// import { DepositPaymaster } from "account-abstraction/samples/DepositPaymaster.sol";
// import { VerifyingPaymaster } from "account-abstraction/samples/VerifyingPaymaster.sol";
// import { BaseAccount } from "account-abstraction/core/BaseAccount.sol";
// import { SimpleAccount } from "account-abstraction/samples/SimpleAccount.sol";
// import { SimpleAccountFactory } from "account-abstraction/samples/SimpleAccountFactory.sol";
// import { IEntryPoint } from "account-abstraction/interfaces/IEntrypoint.sol";

// contract AAScript is Script {

//     function setUp() public {}

//     function run() public {

//         vm.startBroadcast();

//         IEntryPoint entrypoint = IEntryPoint(vm.envAddress("AA_ENTRYPOINT"));

//         SimpleAccountFactory simpleAccountFactory = new SimpleAccountFactory(entrypoint);

//         // entrypoint.depositTo{value: 100 wei}(msg.sender);

//         // DepositPaymaster depositPaymasterr = new DepositPaymaster(entrypoint);

//         vm.stopBroadcast();

//     }
// }