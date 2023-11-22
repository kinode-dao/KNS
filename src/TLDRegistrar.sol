// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./lib/BytesUtils.sol";
import "./interfaces/ITLDRegistrar.sol";
import "./interfaces/IQNSRegistryResolver.sol";

error TLDSet();
error NotATLD();
error NotQNS();
error InvalidTLD();
error NotAuthorized();
error MustBeTLD();
error ERC721TransferToNonReceiver();
error ERC721AlreadyMinted();
error ERC721MintToAddress0();
error ERC721TransferFromIncorrectOwner();
error ERC721TransferToAddress0();
error ERC721InvalidOwnerAddress0();
error ERC721NotOwnerOrApproved();
error ERC721ApproveToOwner();
error ERC721InvalidTokenId();
error TLDWebmasterApproveToCaller();

contract TLDRegistrar is ITLDRegistrar, Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using BytesUtils for bytes;

    IQNSRegistryResolver public qns;

    bytes32 public TLD_HASH;
    bytes   public TLD_DNS_WIRE;

    string private _name;
    string private _symbol;

    mapping (uint256 => bytes32) private _nodes;
    mapping (address => uint256) private _balances;
    mapping (uint256 => address) private _approvals;

    mapping (address => mapping(address => bool)) private _operators;
    mapping (address => mapping(address => bool)) private _webmasters;

    // 
    // uups upgradeable
    // 

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // 
    // erc 721
    //

    function balanceOf(address _owner) public view returns (uint256) { 
        if (_owner == address(0)) revert ERC721InvalidOwnerAddress0();
        return _balances[_owner];
    }

    function ownerOf(uint256 node) public view returns (address) {
        address _owner = _ownerOf(node);
        if (_owner == address(0)) revert ERC721InvalidTokenId();
        return _owner;
    }

    function name () public view returns (string memory) {
        return _name;
    }

    function symbol () public view returns (string memory) {
        return _symbol;
    }

    function approve (address to, uint256 node) public {
        address owner = ownerOf(node);

        if (to == owner) revert ERC721ApproveToOwner();
        if (_msgSender() != owner && isApprovedForAll(owner, _msgSender()))
            revert ERC721NotOwnerOrApproved();

        _approve(to, node);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _approvals[tokenId] = to;
        emit Approval(_ownerOf(tokenId), to, tokenId);
    }

    function getApproved (uint256 _node) public view returns (address) {
        if (_ownerOf(_node) == address(0)) revert ERC721InvalidTokenId();
        return _approvals[_node];
    }

    function setApprovalForAll (address _operator, bool _approved) public {
        _setApprovalForAll(_msgSender(), _operator, _approved);
    }

    function _setApprovalForAll(address _owner, address _operator, bool _approved) public {
        if (_owner == _operator) revert ERC721ApproveToOwner();
        _operators[_owner][_operator] = _approved;
        emit ApprovalForAll(_owner, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return _operators[_owner][_operator];
    }

    function setWebmaster(address _webmaster, bool _approved) public {
        _setWebmaster(_msgSender(), _webmaster, _approved);
    }

    function isWebmaster(address _owner, address _webmaster) public view returns (bool) {
        return _webmasters[_owner][_webmaster];
    }

    function isWebmaster(address _webmaster, uint256 _node) public view returns (bool) {
        return _isWebmaster(_webmaster, _node);
    }

    function _isWebmaster(address _webmaster, uint256 _node) internal view returns (bool) {
        return _webmasters[_ownerOf(_node)][_webmaster];
    }

    function _setWebmaster(address _owner, address _webmaster, bool _approved) internal {
        if (_owner == _webmaster) revert TLDWebmasterApproveToCaller();
        _webmasters[_owner][_webmaster] = _approved;
        emit Webmaster(_owner, _webmaster, _approved);
    }

    function _isApprovedOrOwner (address spender, uint node) internal view returns (bool) {
        address _owner = TLDRegistrar.ownerOf(node);
        return (spender == _owner || isApprovedForAll(_owner, spender) || getApproved(node) == spender);
    }

    function transferFrom(address from, address to, uint256 node) public {
        if (!_isApprovedOrOwner(_msgSender(), node))
            revert ERC721NotOwnerOrApproved();
        _transfer(from, to, node);
    }

    function safeTransferFrom(address from, address to, uint node) public {
        safeTransferFrom(from, to, node, "");
    }

    function safeTransferFrom(address from, address to, uint node, bytes memory data) public {
        if (!_isApprovedOrOwner(_msgSender(), node))
            revert ERC721NotOwnerOrApproved();
        _safeTransfer(from, to, node, data);
    }

    function _safeTransfer(address from, address to, uint node, bytes memory data) internal {
        _transfer(from, to, node);
        if (!_checkOnERC721Received(from, to, node, data))
            revert ERC721TransferToNonReceiver();
    }

    function _setOwner(
        address to, 
        bytes32 node
    ) internal pure returns (bytes32) {

        bytes32 addressMask = bytes32(uint(uint160(to)) << 96);
        return addressMask | node;

    }

    function _setAttributes (
        bytes32 attributes,
        bytes32 node
    ) internal pure returns (bytes32) {

        bytes32 mask = bytes32(uint256(0xffffffffffffffffffffffff)); // Mask for the rightmost 96 bits
        bytes32 attributesMasked = attributes & mask;
        bytes32 nodeMasked = node & ~mask;
        return nodeMasked | attributesMasked;

    }

    function _getAttributes (
        bytes32 node
    ) internal pure returns (bytes32) {
        return node & bytes32(uint256(0xffffffffffffffffffffffff)); // Mask for the rightmost 96 bits
    }

    function _getOwner(
        bytes32 node
    ) internal pure returns (address) {
        return address(uint160(uint256(node) >> 96));
    }

    function _ownerOf(
        uint _node
    ) internal view returns (address) { 
        return _getOwner(_nodes[_node]);
    }

    function _transfer(address _from, address _to, uint _node) internal {
        if (address(0) == _to) revert ERC721TransferToAddress0();

        if (_ownerOf(_node) != _from) revert ERC721TransferFromIncorrectOwner();

        _beforeTokenTransfer(_from, _to, _node, 1);

        if (_ownerOf(_node) != _from) revert ERC721TransferFromIncorrectOwner();

        delete _approvals[_node];

        unchecked { _balances[_from] -= 1; _balances[_to] += 1; }

        _nodes[_node] = _setOwner(_to, _nodes[_node]);

        emit Transfer(_from, _to, _node);

        _afterTokenTransfer(_from, _to, _node, 1);

    }

    function _mint(address _to, uint256 _node) internal virtual {
        if (_to == address(0)) revert ERC721MintToAddress0();

        if (_nodes[_node] != bytes32(0)) revert ERC721AlreadyMinted();

        _beforeTokenTransfer(address(0), _to, _node, 1);

        if (_nodes[_node] != bytes32(0)) revert ERC721AlreadyMinted();

        unchecked { _balances[_to] += 1; }

        _nodes[_node] = _setOwner(_to, _nodes[_node]);

        _afterTokenTransfer(address(0), _to, _node, 1);

    }

    function _safeMint(address to, uint node) internal virtual {
        _safeMint(to, node, "");
    }

    function _safeMint(address to, uint node, bytes memory data) internal virtual {
        _mint(to, node);
        if (!_checkOnERC721Received(address(0), to, node, data))
            revert ERC721TransferToNonReceiver();
    }

    function _burn(uint256 node) internal {
        address owner = _ownerOf(node);

        _beforeTokenTransfer(owner, address(0), node, 1);

        owner = _ownerOf(node);

        delete _approvals[node];
        unchecked { _balances[owner] -= 1; }

        delete _nodes[node];

        emit Transfer(owner, address(0), node);

        _afterTokenTransfer(owner, address(0), node, 1);

    }


    function _checkOnERC721Received(
        address from,
        address to,
        uint256 node,
        bytes memory data
    ) private returns (bool) {
        if (0 < to.code.length) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, node, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory r) {
                if (r.length == 0) revert ERC721TransferToNonReceiver();
                else { assembly { revert(add(32, r), mload(r)) } }
            }
        } else return true;
    }

    //
    // externals
    //
    function setTLD (bytes calldata tld) external {
        if (msg.sender != address(qns)) revert NotQNS();
        if (TLD_HASH != bytes32(0)) revert TLDSet();
        ( bytes32 label, uint offset ) = tld.readLabel();
        if (tld.length != offset) revert MustBeTLD(); 
        TLD_HASH = label;
        TLD_DNS_WIRE = tld;
    }

    function register(
        bytes calldata name,
        address owner,
        bytes[] calldata data
    ) external payable returns (
        uint256 nodeId
    ) {

        ( bytes32 _child, bytes32 _parent, bytes32 _tld) = 
            name.childParentAndTLD();

        if (!auth(_parent, _msgSender())) revert NotAuthorized();

        if (TLD_HASH != _tld) revert InvalidTLD();

        qns.registerNode(name);

        if (data.length > 0) qns.multicallWithNodeCheck(_child, data);

        _safeMint(owner, uint(_child));

    }

    function auth (
        bytes32 node,
        address sender
    ) public view virtual returns (
        bool authed
    ) {

        return 
            _isWebmaster(sender, uint(node)) ||
            _isApprovedOrOwner(sender, uint(node));

    }


    //
    // internals
    //
    function _getNodeAndParent(bytes memory fqdn) internal pure returns (bytes32 node, bytes32 parentNode) {
        (bytes32 label, uint256 offset) = fqdn.readLabel(0);
        parentNode = fqdn.namehash(offset);
        node = _makeNode(parentNode, label);
    }

    function _makeNode(
        bytes32 node,
        bytes32 labelhash
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(node, labelhash));
    }


    //
    // virtual hooks
    // 

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}


    // 
    // erc 165
    //

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {}

}