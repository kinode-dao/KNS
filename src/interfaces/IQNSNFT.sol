pragma solidity >=0.8.4;

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// TODO not sure we even need this contract...
// Basically we want this interface to say "hey this is an NFT and can be used for QNS"
interface IQNSNFT {
    function baseNode() external view returns (uint); // TODO what
}
