pragma solidity >=0.8.4;

interface IQNS {
    // QNS node data
    struct Record {
        address owner;
        address resolver;
        address approval;
        uint32  fuses;
        uint64  ttl;
    }

    // Logged when a node is created for the first time
    event NameRegistered(uint256 indexed node, bytes name, address owner);

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(uint256 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(uint256 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(uint256 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(uint256 indexed node, uint64 ttl);

    function setRecord(
        bytes calldata node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeRecord(
        bytes calldata node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setResolver(uint256 node, address resolver) external;

    function setOwner(uint256 node, address owner) external;

    function setTTL(uint256 node, uint64 ttl) external;

    function resolver(uint256 node) external view returns (address);

    function ttl(uint256 node) external view returns (uint64);

    function recordExists(uint256 node) external view returns (bool);
}
