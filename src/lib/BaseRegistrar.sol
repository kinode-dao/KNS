// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../registry/QNSRegistry.sol";
import "../lib/BytesUtils.sol";
import "../interfaces/IBaseRegistrar.sol";
import "../interfaces/IResolver.sol";

error CommitmentTooOld(bytes32 commitment);
error CommitmentTooNew(bytes32 commitment);
error CommitmentUnexpired(bytes32 commitment);
error CommitmentDoesNotExist(bytes32 commitment);
error DomainNotAvailable(uint256 domainId);
error DomainTooShort();
error DomainParentInvalid(bytes name);
error ResolverDataInvalid();

contract BaseRegistrar is IBaseRegistrar, Initializable, OwnableUpgradeable, UUPSUpgradeable {

    using BytesUtils for bytes;

    QNSRegistry public qns;
    uint        public baseNode;

    uint public maxCommitmentAge; 
    uint public minCommitmentAge;

    mapping(address => bool) public controllers;
    mapping(bytes32 => uint) public commitments;

    modifier live() 
        { require(qns.owner(baseNode) == address(this)); _; }

    modifier onlyController() 
        { require(controllers[msg.sender]); _; }


    function initialize (
        QNSRegistry _qns, 
        uint256 _baseNode
    ) public initializer {

        __UUPSUpgradeable_init();
        __Ownable_init();

        qns = _qns;
        baseNode = _baseNode;
        minCommitmentAge = 0;
        maxCommitmentAge = type(uint128).max;

    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getInitializedVersion() public view returns (uint8) 
        { return  _getInitializedVersion(); }

    function addController(address controller) external onlyController {
        controllers[controller] = true;
        emit ControllerAdded(controller);
    }

    function removeController(address controller) external onlyController {
        controllers[controller] = false;
        emit ControllerRemoved(controller);
    }

    function setMaxCommitmentAge (uint256 duration) 
        external onlyController { maxCommitmentAge = duration; }

    function setMinCommitmentAge (uint256 duration) 
        external onlyController { minCommitmentAge = duration; }

    function setResolver(address resolver) 
        external onlyController { qns.setResolver(baseNode, resolver); }

    // TODO: dependent on future support for expiry
    function available (uint256 id) public view returns (bool) {
        return true; 
    }

    function makeCommitment (
        bytes memory name,
        address owner,
        bytes32 secret,
        address resolver,
        bytes[] calldata resolverData,
        bool reverseRegistrar,
        uint16 ownerControlledFuses
    ) public view returns(bytes32) {

        (,uint offset) = name.readLabel(0);

        if (offset < 9) 
            revert DomainTooShort();

        if (uint(name.namehash(offset)) != baseNode)
            revert DomainParentInvalid(name);

        if (resolver != address(0) && resolverData.length == 0)
            revert ResolverDataInvalid();

        return keccak256(
            abi.encode(
                uint(name.namehash(0)),
                owner,
                secret,
                resolver,
                resolverData,
                reverseRegistrar,
                ownerControlledFuses
            )
        );
    }

    function commit (bytes32 commit) public {

        uint commitment = commitments[commit];

        if (commitment != 0 && commitment + maxCommitmentAge >= block.timestamp)
            revert CommitmentUnexpired(commit);
        else 
            commitments[commit] = block.timestamp;

    }

    function register (
        bytes calldata name,
        address owner,
        bytes32 secret,
        address resolver,
        bytes[]calldata resolverData,
        bool reverseRecord,
        uint16 ownerControlledFuses
    ) public payable {

        uint id = uint(name.namehash(0));

        _consumeCommitment(
            id,
            makeCommitment(
                name,
                owner,
                secret,
                resolver,
                resolverData,
                reverseRecord,
                ownerControlledFuses
            )
        );

        qns.setSubnodeRecord(
            name, 
            owner, 
            resolver, 
            type(uint64).max
        );

        if (resolverData.length > 0) 
            _setRecords(resolver, id, resolverData);

        if (reverseRecord)
            _setReverseRecord(resolver, id, name);

    }

    function _consumeCommitment(
        uint256 domainId,
        bytes32 commitment
    ) internal {

        // must exist
        if (commitments[commitment] == 0)
            revert CommitmentDoesNotExist(commitment);

        // too old or already registered
        if (commitments[commitment] + maxCommitmentAge <= block.timestamp)
            revert CommitmentTooOld(commitment);

        // old enough 
        if (commitments[commitment] + minCommitmentAge > block.timestamp)
            revert CommitmentTooNew(commitment);

        // must be available
        if (!available(domainId)) 
            revert DomainNotAvailable(domainId);

        delete (commitments[commitment]);

    }

    function _setRecords(
        address resolverAddress, 
        uint256 id, 
        bytes[] calldata data
    ) internal {

        IResolver(resolverAddress).multicallWithNodeCheck(id, data);

    }

    function _setReverseRecord(address resolver, uint256 id, bytes calldata name) internal {

    }



}