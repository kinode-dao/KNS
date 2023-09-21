pragma solidity >=0.8.4;

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// TODO also need to specify that this is an NFT without causing inheritance issues
// This interface is required by all NFTs that are used as subdomain contracts
interface IQNSNFT {
    // read base node id
    function baseNode() external view returns (uint); // TODO what
    
    // should only be callable by QNSRegistry
    function setBaseNode(uint256 baseNode) external;
}
