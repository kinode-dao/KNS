pragma solidity ^0.8.13;

import "../registry/QNSRegistry.sol";
import "../lib/BytesUtils.sol";
import "../interfaces/IBAseRegistrar.sol";

error CommitmentTooOld(bytes32 commitment);
error CommitmentTooNew(bytes32 commitment);
error CommitmentUnexpired(bytes32 commitment);
error DomainNotAvailable(uint256 domainId);
error DomainTooShort();
error DomainParentInvalid(bytes name);
error ResolverDataInvalid();

contract BaseRegistrar is IBaseRegistrar {

    using BytesUtils for bytes;

    QNSRegistry public immutable qns;
    uint        public immutable baseNode;

    uint public maxCommitmentAge; 
    uint public minCommitmentAge;

    mapping(address => bool) public controllers;
    mapping(bytes32 => uint) public commitments;

    modifier live() 
        { require(qns.owner(baseNode) == address(this)); _; }

    modifier onlyController() 
        { require(controllers[msg.sender]); _; }


    constructor (QNSRegistry _qns, uint256 _baseNode) {
        qns = _qns;
        baseNode = _baseNode;
    }

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

    function available (uint256 id) public view returns (bool) {
        // TODO: dependent on future support for expiry
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

    function commit (bytes32 commitment) public {

        if (commitments[commitment] + maxCommitmentAge >= block.timestamp)
            revert CommitmentUnexpired(commitment);
        else 
            commitments[commitment] = block.timestamp;

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

        if (resolverData.length > 0) 
            _setRecords(resolver, id, resolverData);

        if (reverseRecord)
            _setReverseRecord(resolver, id, name);

    }

    function _consumeCommitment(
        uint256 domainId,
        bytes32 commitment
    ) internal {

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

    function _setRecords(address resolver, uint256 id, bytes[] calldata data) internal {

    }

    function _setReverseRecord(address resolver, uint256 id, bytes calldata name) internal {

    }

}