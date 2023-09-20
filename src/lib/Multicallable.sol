
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IMulticallable.sol";

abstract contract Multicallable is IMulticallable {
    function multicall(
        bytes[] calldata data
    ) public override returns (
        bytes[] memory results
    ) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall( data[i]);
            require(success);
            results[i] = result;
        }
        return results;
    }
}
