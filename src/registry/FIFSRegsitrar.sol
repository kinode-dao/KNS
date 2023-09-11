
pragma solidity >=0.8.4;

import "../interfaces/IQNS.sol";
import "../lib/BytesUtils.sol";

/**
 * A registrar that allocates subdomains to the first person to claim them.
 */
contract FIFSRegistrar {

    using BytesUtils for bytes;

    uint256 public rootNode;
    IQNS qns;

    // modifier only_owner(string calldata label) {
    //     ( , uint offset ) = label.readLabel();
    //     uint parent = uint(label.namehash(offset));
    //     address currentOwner = qns.owner(parent);
    //     require(currentOwner == address(0x0) || currentOwner == msg.sender);
    //     _;
    // }

    /**
     * Constructor.
     * @param qnsAddr The address of the QNS registry.
     * @param node The node that this registrar administers.
     */
    constructor(IQNS qnsAddr, uint256 node) public {
        qns = qnsAddr;
        rootNode = node;
    }

    /**
     * Register a name, or change the owner of an existing registration.
     * @param fqdn The fully qualified domain name to register.
     * @param owner The address of the new owner.
     */
    function register(
        bytes calldata fqdn, 
        address owner,
        address resolver,
        uint64  ttl
    ) public {

        ( , uint offset ) = fqdn.readLabel(0);
        require(rootNode == uint(fqdn.namehash(offset)));

        qns.setSubnodeRecord(fqdn, owner, resolver, ttl);

    }
}
