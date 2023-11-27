pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITLDRegistrar is IERC721 {

    event Webmaster(address indexed owner, address indexed webmaster, bool approved);

    // read base node id
    function TLD_HASH () external view returns (bytes32);

    function TLD_DNS_WIRE () external view returns (bytes memory);

    function auth (bytes32 node, address sender) 
        external view returns (bool authorized); 

    // function register (bytes calldata name, address user, bytes[] calldata data) 
    //     external payable returns (uint node);

    function setWebmaster (address webmaster, bool approved) 
        external;

    function isWebmaster (address webmaster, uint node) 
        external view returns (bool);

    function isWebmaster (address owner, address webmaster) 
        external view returns (bool);

}
