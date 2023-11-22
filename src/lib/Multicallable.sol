
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IMulticallable.sol";

abstract contract Multicallable is IMulticallable {
    function _multicall(
        bytes32 node,
        bytes[] calldata data
    ) internal returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            if (node != 0) {
                bytes32 txNode = bytes32(data[i][4:36]);
                require(
                    txNode == node,
                    "multicall: All records must have a matching namehash"
                );
            }
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );
            require(success);
            results[i] = result;
        }
        return results;
    }

    // This function provides an extra security check when called
    // from priviledged contracts (such as EthRegistrarController)
    // that can set records on behalf of the node owners
    function multicallWithNodeCheck(
        bytes32 node,
        bytes[] calldata data
    ) external returns (bytes[] memory results) {
        return _multicall(node, data);
    }

    function multicall(
        bytes[] calldata data
    ) external override returns (bytes[] memory results) {
        return _multicall(0, data);
    }

}
