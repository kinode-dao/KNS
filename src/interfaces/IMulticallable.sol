// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMulticallable {

    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory results);

    function multicallWithNodeCheck(
        bytes32 node,
        bytes[] calldata data
    ) external returns (bytes[] memory results); 

}