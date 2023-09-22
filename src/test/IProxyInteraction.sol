// SPDX-Licqnse-Identifier: UNLICENSED
pragma solidity >=0.8.4;

interface IProxyInteraction {
    function getInitializedVersion () external view returns (uint8);
    function authorizeUpgrade(address newImplementation) external;
    function proxiableUUID () external view returns (bytes32);
    function upgradeTo(address newImplementation) external;
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
}