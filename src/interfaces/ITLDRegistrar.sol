pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITLDRegistrar is IERC721 {

    // read base node id
    function baseNode() external view returns (uint);

    // should only be callable by QNSRegistry
    function setBaseNode (uint256 baseNode) external;

    function isAuthorized (uint256 node, address user) 
        external returns (bool authorized);

    function isWebmaster (uint256 node, address user)
        external returns (bool authorized);

    function setWebmaster (uint256 node, address user) 
        external returns (bool authorized);

    function register (bytes[] calldata name) 
        external returns (uint node);
    
}
