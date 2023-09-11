// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";

import "../interfaces/IQNS.sol";
import "../lib/BytesUtils.sol";

contract QNSRegistry is IQNS {

    using BytesUtils for bytes;

    struct Record {
        address owner;
        address resolver;
        uint32  fuses;
        uint64  ttl;
    }

    // token id to Record which contains owner
    mapping (uint => Record) records;

    // TODO: ERC721 compliance
    mapping(address => mapping(address => bool)) operators; 

    constructor() { records[0].owner = msg.sender; }

    function setRecord(
        bytes calldata fqdn,
        address owner,
        address resolver,
        uint64  ttl
    ) public {

        (bytes32 labelhash, uint256 offset) = fqdn.readLabel(0);
        bytes32 parentNode = fqdn.namehash(offset);
        uint node = uint(_makeNode(parentNode, labelhash));

        Record storage r = records[node];

        require(r.owner == msg.sender || operators[r.owner][msg.sender]);

        if (owner != address(0)) 
            emit Transfer(node, r.owner = owner);

        if (resolver != address(0)) 
            emit NewResolver(node, r.resolver = resolver);

    }

    function setSubnodeRecord (
        bytes calldata fqdn,
        address owner,
        address resolver,
        uint64  ttl
    ) public {

        (bytes32 labelhash, uint256 offset) = fqdn.readLabel(0);
        bytes32 parentNode = fqdn.namehash(offset);
        uint node = uint(_makeNode(parentNode, labelhash));

        address parentOwner = records[uint(parentNode)].owner;

        // TODO: use fuses to know if node can be operated on by parent owner
        require(parentOwner == msg.sender || operators[parentOwner][msg.sender]);

        Record storage r = records[uint(node)];

        if (r.owner == address(0) && r.resolver == address(0) && r.fuses == 0 && r.ttl == 0)
            emit NameRegistered(node, fqdn, owner);

        if (owner != address(0))
            emit Transfer(node, r.owner = owner);

        if (resolver != address(0))
            emit NewResolver(node, r.resolver = resolver);

    }

    function setApprovalForAll(address operator, bool approved) public {

        operators[msg.sender][operator] = approved;

    }

    function isApprovedForAll(
        address owner, 
        address operator
    ) public view returns (
        bool approved
    ) {

        approved = operators[msg.sender][operator];

    }

    function _makeNode(
        bytes32 node,
        bytes32 labelhash
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(node, labelhash));
    }

    function owner(uint256 node) external view returns (address owner) {

        owner = records[node].owner;

    }

    // TODO: May keep or delete these
    function setTTL(uint256 node, uint64 ttl) public {}
    function ttl(uint256 node) public view returns (uint64 ttl) {}
    function recordExists(uint256 node) external view returns (bool exists) {}
    function resolver(uint256 node) external view returns (address resolver) {}
    function setResolver(uint256 node, address resolver) external {}
    function setOwner(uint256 node, address owner) external {}

}
