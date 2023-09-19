pragma solidity >=0.8.4;

interface IQNS {
    // QNS node data
    struct Record {
        address owner;
        address resolver;
        address approval; // TODO delete this
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
        address resolver
    ) external;
}
