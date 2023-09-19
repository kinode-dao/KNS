
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../interfaces/IMulticallable.sol";

abstract contract Multicallable is IMulticallable, ERC165 {

    // NOTE: this implementation forces us to put all node ids as the 
    // first variable in every method signature...might not need this...
    function _multicall(
        uint256 nodeId,
        bytes[] calldata data
    ) internal returns (
        bytes[] memory results
    ) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            if (nodeId != 0) {
                uint txNodeId = uint(bytes32(data[i][4:36]));
                require(
                    txNodeId == nodeId,
                    "multicall: All records must have a matching namehash"
                );
            }

            (bool success, bytes memory result) = 
                address(this).delegatecall( data[i]);

            require(success);

            results[i] = result;

        }
        return results;
    }

    // This function provides an extra security check when called
    // from priviledged contracts (such as EthRegistrarController)
    // that can set records on behalf of the node owners
    function multicallWithNodeCheck(
        uint256 nodeId,
        bytes[] calldata data
    ) external returns (bytes[] memory results) {
        return _multicall(nodeId, data);
    }

    function multicall(
        bytes[] calldata data
    ) public override returns (bytes[] memory results) {
        return _multicall(0, data);
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual override returns (bool) {
        return
            interfaceID == type(IMulticallable).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}
