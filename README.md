# QNS
Last updated Sept 17 2023

## QNS Overview
QNS is a fork of ENS. Currently we have only one record type: `WsRecord`, which is used for setting networking keys, ip & port (if direct), and routers (if indirect). QNS also follows the UUPS upgradable pattern, which means we can add more record types in the future. For example, if we decided to add a way to network using TCP instead of WS, we could add a new record type. More interestingly, we could add a way to set a `.uq` name to point to a protocol spec, and that QNS id will be managed by a DAO. We could also add a record type that would point to an NFT representing, for example, your profile picture - and this gives all other nodes on the network an easy way to fetch your PFP for all applications. Some of the examples here we will likely implement in the near future.

## Architecture
QNS follows ENS' architecture with a few modifications to make it more efficient and eliminate cruft. For one, ENS' base layer only uses bytes32 to identify nodes, and then mints an ERC721/1155 token at higher levels. We use a node's uint value as the NFT id so it is usable throughout all layers. TODO more documentation here. Where are NFTs minted in ENS vs how are they minted here?

### QNSRegistry
This contract is responsible for storing all information related to uqbar protocols. Right now, we just have Websockets. We can support up to 31 more record types which can represent networking information or just general record information.

### UqNFT
A normal NFT that governs ownership of all subdomains of something, in this case, `.uq`. It is a normal ERC721 contract except it must handle all minting logic by calling `setProtocols` in the `QNSRegistry`, and the nft-ids must be the namehash of the name the ID represents. Since this will be permissioned, this is not a big deal and we will be able to audit and make sure each TLD NFT contract is implemented correctly.

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
    --chain-id 420 \
    --num-of-optimizations 200 \
    --watch \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --compiler-version v0.8.21+commit.d9974bed \
    0x368D79c95888bf09199451d397561f2575FBcBe5 \
    src/QNSRegistry.sol:QNSRegistry

forge verify-contract \
    --chain-id 420 \
    --num-of-optimizations 200 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address,bytes)" 0x368D79c95888bf09199451d397561f2575FBcBe5 0x8129fc1c) \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --compiler-version v0.8.21+commit.d9974bed \
    0xBb6C999650d4832be7F72A5D35E02E0214BEBbB0 \
    lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy

forge verify-contract \
    --chain-id 420 \
    --num-of-optimizations 200 \
    --watch \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --compiler-version v0.8.21+commit.d9974bed \
    0xD21c24f919f079361224D0f4E67B95F65fC65495 \
    src/UqNFT.sol:UqNFT

forge verify-contract \
    --chain-id 420 \
    --num-of-optimizations 200 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address,bytes)" 0xD21c24f919f079361224D0f4E67B95F65fC65495 0xcd6dc687000000000000000000000000bb6c999650d4832be7f72a5d35e02e0214bebbb0000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000040275710000000000000000000000000000000000000000000000000000000000) \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --compiler-version v0.8.21+commit.d9974bed \
    0xCA2745A297427d2829EA7bd693F3D9d03Eb788f6 \
    lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy
```
