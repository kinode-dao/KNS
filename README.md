# QNS
Last updated Sept 21 2023

## QNS Overview
QNS is a system similar to ENS but designed specifically to coordinate network information to Uqbar Nodes so that they may interact with eachother. Below follows the architecture of the smart contracts and the rationales for these decisions.

### QNSRegistryResolver

This contract is the central point of recordholding for all nodes in the network. It contains a minimal mapping of a node to its records which are constrained to contain a public networking key, and in addition, either an array of other nodes for routing, or a set of direct IP and port information for the base networking protocols standardized in Uqbar Nodes. As of the time of first release, that includes port information for TCP and UDP, at the lower level, and WebSockets and WebTransport at the higher level.

The QNSRegistryResolver will be a single contract for the entire network of Uqbar Nodes. This provides simple indexing for any node on the network resulting in clear communication of the correct networking information for any given node. 

The QNSRegistryResolver is constructed to give control of any given TLD to a dedicated address, most likely a smart contract address. These addresses then may write any records they wish into the registry provided it is for the TLD they have been granted. This allows for various entities to participate in the network regardless of where their community derives from. They do not need to under an Uqbar affiliated name.

Important concepts.

* DNS Wire Format for passing in nodes to register. 
Passing in all names in DNS Wire Format is necessary to support a system where a TLD has the ability to create any node underneath it's TLD, regardless of how deep a subnode it might be without that subnode's parents already being registered. This is a requirement for such a system as there must be a way to assure the name being registered does indeed fall under the TLD of the registrar responsible for registering it. It is not allowed to register a name under a TLD that is not controlled by the registrar. 

* Fully Qualified Domain Name (FQDN)
An FQDN is the whole name for a domain name, all the way up to the top level domain at the end. For instance, the name a.b under the top level domain "example" has a fully qualified domain name of "a.b.example".

* Namehash
Namehashes are a way of deriving a hash for a given domain name given any depth of subdomains within it. In this algorithm, a domain name is split into labels. These are then hashed. The namehash is created by taking a label's hash and creating a new hash utilizing this same new hash derived from its series of parent labels. In other words, its parent's namehash. The namehash of the highest level domain name is a 32 byte array of zeros.

Interaction with TLDRegistrar.

`registerTLD(bytes fully_qualified_domain_name, address registar)`

registerTLD is called when granting a new contract to mint nodes in the registry in the future. The fully qualified domain name is passed in using DNS Wire Format. This means that for 


`registerNode(bytes fully_qualified_domain_name)`

Registering a node performs no check with the TLDRegistrar beyond asserting the fact that the sender of the message is the TLDRegistrar for that particular TLD. Though it is meaningless to do so, this may be called many times as the only thing this sets is writing the TLDRegistrar's address in as the tld of the node, and writes the protocols to the zeroth value, which are a bitmap that only serve as an efficient indicator of which protocols the node supports.

```
setKey(bytes32 _node, bytes32 _key)
setRouting(bytes32 _node, bytes32[] _nodes)
setIp(bytes32 _node, uint128 _ipAddress)
setWs(bytes32 _node, uint16 _port)
setWt(bytes32 _node, uint16 _port)
setTcp(bytes32 _node, uint16 _port)
setUdp(bytes32 _node, uint16 _port)
```

All of the above functions for setting a node's records make an authorization call to the respective TLDRegistar of a node such that the TLD can decide according to its own opinions whether a node is authorized to set a record or not. It only requires the a node's bytes32 namehash as an argument because the node must be registered before a record is set, and when a node is registered, its TLD is set. So, a TLDRegistrar must be able to reason about whether or not a user is authorized to make a change to a record using only the node's namehash.

### TLDRegistrar

The TLDRegistrar contract is a base contract with internal methods providing the functionality of interacting with the QNSRegistryResolver. Any contract inheriting this builds its own logic atop that dictates the particular management of the TLD it is concerned with. This contract optimizes for gas while conforming to an ERC721 standard for tokenization. In addition to the 160 bits of an node owners address, it stores 96 bits that may be utilized in any way by the inheriting contract. Prior art utilizes this storage to build domain name expiries and permission schemes for governing various types of authorization over a node's attributes, for instance if it has relinquished control of its subdomains.

### DotUqRegistar

The DotUqRegistar implements the TLDRegistar base class to create a contract that will manage .UQ names. It utilizes the attributes of a node to store whether or not the owner of a node has relinquished permissions of control over the various subdomains it may have. It does not enforce any expiry dates, and it does enforce a requirement that the names it registers be 9 characers or longer. 


### DotEthRegistar

The DotEthRegistrar is the exitpoint of a cross chain contract setup that is meant to allow .ETH domains from the ENS domains smart contract on Ethereum Mainnet to claim and manage their .ETH domain within the QNSRegistryResolver. It accepts a message transported over [LayerZero](https://github.com/LayerZero-Labs/LayerZero). The message attests that an address has been authenticated as either an owner or an operator for a particular node and caches this user so that they may operate on the .ETH name within the QNSRegistryResolver. The message may also set records simulatenously, for convenience. The various attributes set in the ENS NameWrapper are also ported over so definition is not lost when interacting with ENS.

### DotEthAuthenticator

The DotEthAuthenticator is responsible for sending the messages described above. It assures the sender is allowed to operate on behalf of a .ETH name and sends along the appropriate metadata to the DotEthRegistrar allowing the sender to operate on their .ETH name in the QNSRegistryResolver.
