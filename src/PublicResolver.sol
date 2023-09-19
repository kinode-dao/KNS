// SPDX-Licqnse-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

// solhint-disable-next-line
import "./lib/Multicallable.sol";
import "./lib/profiles/WsResolver.sol";

import { QNSRegistry } from "./QNSRegistry.sol";

contract PublicResolver is
    Multicallable,
    WsResolver,
    UUPSUpgradeable,
    OwnableUpgradeable,
    IERC165Upgradeable {

    QNSRegistry public qns;

    address public trustedETHController;
    address public trustedReverseRegistrar;

    function initialize(
        QNSRegistry _qns,
        address _trustedETHController,
        address _trustedReverseRegistrar
    ) public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();

        qns = _qns;
        trustedETHController = _trustedETHController;
        trustedReverseRegistrar = _trustedReverseRegistrar;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getInitializedVersion() public view returns (uint8) 
        { return  _getInitializedVersion(); }

    function supportsInterface(bytes4 interfaceID) public view override (Multicallable, WsResolver, IERC165Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceID);
    }

    function isAuthorised(uint256 node) internal view override returns (bool) {
        // TODO what is this/why do we need it?
        // if (
        //     msg.sender == trustedETHController ||
        //     msg.sender == trustedReverseRegistrar
        // ) return true;

        return qns.isOwnerOrApproved(msg.sender, node);
    }
}
