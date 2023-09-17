# QNS
Last updated Sept 17 2023

## QNS Overview
QNS is a fork of ENS. Currently we have only one record type: `WsRecord`, which is used for setting networking keys, ip & port (if direct), and routers (if indirect). QNS also follows the UUPS upgradable pattern, which means we can add more record types in the future. For example, if we decided to add a way to network using TCP instead of WS, we could add a new record type. More interestingly, we could add a way to set a `.uq` name to point to a protocol spec, and that QNS id will be managed by a DAO. We could also add a record type that would point to an NFT representing, for example, your profile picture - and this gives all other nodes on the network an easy way to fetch your PFP for all applications. Some of the examples here we will likely implement in the near future.

## Architecture
QNS follows ENS' architecture with a few modifications to make it more efficient and eliminate cruft. For one, ENS' base layer only uses bytes32 to identify nodes, and then mints an ERC721/1155 token at higher levels. We use a node's uint value as the NFT id so it is usable throughout all layers. TODO more documentation here. Where are NFTs minted in ENS vs how are they minted here?

### `QNSRegistry.sol`
The core contract for QNS. It's logic is very simpel: it maintains a map of all domains to its their resolvers. While there may be more resolvers in the future, for now there is only the PublicResolver (should rename WsResolver?), which is responsible for resolving networking information on chain.

### `PublicResolver.sol`
Responsible for storing all Web Socket routing information for Uqbar's networking.

### `UqRegistrar.sol`
Logic that dictates how a user can register, own, and renew QNS names. Currently we have a commit/reveal scheme to prevent frontrunning. TODO we will also need to build an invite code system. TODO also need to add controller logic, which should handle registrations and renewals. Maybe we even remove the controller logic!

## Testing and Scripts
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
