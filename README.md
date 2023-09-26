# QNS
Last updated Sept 21 2023

## QNS Overview
QNS is a fork of ENS which lets you map human readable names to different kinds of information called "records". Currently we have only one record type: `WsRecord`, which is used for setting Uqbar-related networking information: networking keys, ip & port (if direct), and routers (if indirect). QNS also follows the UUPS upgradable pattern, which means we can add more record types in the future. For example, if we decided to add a way to network using TCP instead of WS, we could add a new record type. More interestingly, we could add a way to set a `.uq` name to point to a protocol spec, and that QNS id will be managed by a DAO. We could also add a record type that would point to an NFT representing, for example, your profile picture - and this gives all other nodes on the network an easy way to fetch your PFP for all applications. Some of the examples here we will likely implement in the near future.

## Architecture
QNS follows ENS' architecture with a few modifications to make it more efficient and eliminate cruft. For one, ENS' base layer only uses bytes32 to identify nodes, and then mints an ERC721/1155 token at higher levels. We use a node's uint value as the NFT id so it is usable throughout all layers. Also unlike ENS, no ownership logic is handled at the base layer, all of it is handled by the `UqNFT` system. These can be any normal ERC721 token, though they must implement a few extra functions described in `IQNSNFT.sol` 

### QNSRegistry
This contract is responsible for storing all information related to uqbar protocols. Again, no ownership logic lives here. For on-chain information associated with a name, we just have Websockets for Uqbar networking. In the future we can add up to 31 more record types which can represent networking information or just general record information.

### UqNFT
A normal NFT that governs ownership of all subdomains of a particular node. This is our implementation for handling all `.uq` names, but this contract can be used for other TLDs (like if we wanted to deploy a `.test` domain) and other subdomains like `alice.uq`, if desired. However, you can also use any ERC721 compliant token provided that it:
- implements `baseNode()` which sets the domain it governs, in this case `.uq` though this contract can also be used to handle subdomains such as `example.uq`
- implements `setBaseNode(uint256)` which is called by the `QNSRegistry` to set the base node it can govern
- the nft-ids must be the namehash of the domain that the id represents

# Deployment Notes
## Scripts
Before running scripts, build dnswire with
```
cd dnswire
cargo build
```
Then you can run scripts, for example
```
ganache-cli --server.ws --wallet.mnemonic "test test test test test test test test test test test test"

forge script script/QNS.s.sol --rpc-url http://127.0.0.1:8545 --ffi --broadcast -vvvv
```

## Verification With Forge
Obvious reminder to swap out the contract addresses and constructor arguments. Compiler version and optimizations may also change
```
forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 200 \
    --watch \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --compiler-version v0.8.21+commit.d9974bed \
    0x2AFC8D61c2Dc9a3B40D85F5207f40de81d4A86e7 \
    src/QNSRegistry.sol:QNSRegistry

forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 200 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address,bytes)" 0x2AFC8D61c2Dc9a3B40D85F5207f40de81d4A86e7 0x8129fc1c) \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --compiler-version v0.8.21+commit.d9974bed \
    0x9e5ed0e7873E0d7f10eEb6dE72E87fE087A12776 \
    lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy

forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 200 \
    --watch \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --compiler-version v0.8.21+commit.d9974bed \
    0xAf763608ad4E3ffEbbE5B5B0DCDe140d282C4457 \
    src/UqNFT.sol:UqNFT

forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 200 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address,bytes)" 0xAf763608ad4E3ffEbbE5B5B0DCDe140d282C4457 0xc4d66de80000000000000000000000009e5ed0e7873e0d7f10eeb6de72e87fe087a12776) \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --compiler-version v0.8.21+commit.d9974bed \
    0xA855B1F82127158bE35dF4a7867D9a3d7fc5166c \
    lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy
```
