// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import "./lib/BytesUtils.sol";
import "./TLDRegistrar.sol";

contract DotUqRegistrar is TLDRegistrar, Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using BytesUtils for bytes;

    function initialize (
        address _qns
    ) public initializer {

        __TLDRegistrar_init(_qns, "Uqbar Name Service", "UQNS");
        __UUPSUpgradeable_init();
        __Ownable_init();

    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getInitializedVersion() public view returns (uint8) {
        return  _getInitializedVersion();
    }

    //
    // internals
    //

}