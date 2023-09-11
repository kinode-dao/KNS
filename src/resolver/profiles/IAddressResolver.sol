// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the new (multicoin) addr function.
 */
interface IAddressResolver {
    event AddressChanged(
        uint256 indexed node,
        uint256 coinType,
        bytes newAddress
    );

    function addr(
        uint256 node,
        uint256 coinType
    ) external view returns (bytes memory);
}
