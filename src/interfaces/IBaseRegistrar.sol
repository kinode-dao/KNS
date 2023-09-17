pragma solidity >=0.8.4;

interface IBaseRegistrar {
    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);

    function commitments(bytes32) external view returns (uint);
    function minCommitmentAge() external view returns (uint);
    function maxCommitmentAge() external view returns (uint);
    function controllers(address) external view returns (bool);
    function baseNode() external view returns (uint);

    function addController(address controller) external;
    function removeController(address controller) external;

    function setMaxCommitmentAge(uint duration) external;
    function setMinCommitmentAge(uint duration) external;

    function setResolver(address resolver) external;

    function available(uint256 id) external view returns (bool);

    function makeCommitment(
        bytes memory name,
        address owner,
        bytes32 secret,
        address resolver,
        bytes[] calldata resolverData,
        bool reverseRegistrar,
        uint16 ownerControlledFuses
    ) external view returns (
        bytes32 commitment
    );

    function commit(bytes32 commitment) external;

    function register(
        bytes memory name,
        address owner,
        bytes32 secret,
        address resolver,
        bytes[] calldata resolverData,
        bool reverseRegistrar,
        uint16 ownerControlledFuses
    ) external payable;

}
