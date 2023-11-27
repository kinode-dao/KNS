# QNS
Last updated Sept 21 2023

## QNS Overview
QNS is a system similar to ENS but designed specifically to coordinate network information to Uqbar Nodes so that they may interact with eachother. Below follows the architecture of the smart contracts and the rationales for these decisions.

### QNSRegistryResolver

This contract is the central point of recordholding for all nodes in the network. It contains a minimal mapping of a node to its records which are constrained to contain a public networking key, and in addition, either an array of other nodes for routing, or a set of direct IP and port information for the base networking protocols standardized in Uqbar Nodes. As of the time of first release, that includes port information for TCP and UDP, at the lower level, and WebSockets and WebTransport at the higher level.

The QNSRegistryResolver will be a single contract for the entire network of Uqbar Nodes. This provides simple indexing for any node on the network resulting in clear communication of the correct networking information for any given node. 

The QNSRegistryResolver is constructed to give control of any given TLD to a dedicated address, most likely a smart contract address. These addresses then may write any records they wish into the registry provided it is for the TLD they have been granted. This allows for various entities to participate in the network regardless of where their community derives from. They do not need to under an Uqbar affiliated name.

### TLDRegistrar

The TLDRegistrar contract is a base contract with internal methods providing the functionality of interacting with the QNSRegistryResolver. Any contract inheriting this builds its own logic atop that dictates the particular management of the TLD it is concerned with. This contract optimizes for gas while conforming to an ERC721 standard for tokenization. In addition to the 160 bits of an node owners address, it stores 96 bits that may be utilized in any way by the inheriting contract. Prior art utilizes this storage to build domain name expiries and permission schemes for governing various types of authorization over a node's attributes, for instance if it has relinquished control of its subdomains.
