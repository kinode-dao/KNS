// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IWsResolver.sol";
import "../ResolverBase.sol";

error MustChooseStaticOrRouted();

abstract contract WsResolver is IWsResolver, ResolverBase {
    mapping(uint256 => WsRecord) ws_records;

    function combineIpAndPort(uint32 ip, uint16 port) public pure returns (uint48) {
        return uint48((uint48(ip) << 16) | port);
    }

    /**
     * Sets the Ws information associated with the QNS node.
     * @param node The node to update.
     * @param _publicKey The networking key of the QNS node
     * @param _ip The IP address of the QNS node (0 if indirect node)
     * @param _port The port of the QNS node (0 if indirect node)
     * @param _routers The allowed routers of the QNS node (empty if direct node)
     */
    function setWs(
        uint256 node,
        bytes32 _publicKey,
        uint32 _ip,
        uint16 _port,
        bytes32[] calldata _routers
    ) external virtual authorised(node) {

        if ((_ip != 0 || _port != 0) && _routers.length != 0) {
            revert MustChooseStaticOrRouted();
        }
        if (_ip == 0 && _port == 0 && _routers.length == 0) {
            revert MustChooseStaticOrRouted();
        }

        uint48 _ipAndPort = combineIpAndPort(_ip, _port);

        ws_records[node] = WsRecord(
            _publicKey,
            _ipAndPort,
            _routers
        );
        emit WsChanged(node, _publicKey, _ipAndPort, _routers);
    }

    /**
     * Returns the Ws routing information associated with the QNS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @return record The record information from the resolver
     */
    function ws(
        uint256 node
    ) external view virtual override returns (WsRecord memory) {
        return ws_records[node];
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual override returns (bool) {
        return
            interfaceID == type(IWsResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}
