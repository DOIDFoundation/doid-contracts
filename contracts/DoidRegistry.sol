
// SPDX-License-Identifier: None
pragma solidity >=0.8.4;

import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';

import "./DoidRegistryStorage.sol";
import "./interfaces/IDoidRegistry.sol";
import "./Resolver.sol";

contract DoidRegistry is 
    ERC721Upgradeable,
    DoidRegisterStorage,
    Resolver,
    IDoidRegistry
{
    string internal _prefix;
    address internal _mintingManager;

    mapping(address => uint256) internal _reverses;

    mapping(address => bool) internal _proxyReaders;

    mapping(uint256 => bool) internal _upgradedTokens;



    modifier protectTokenOperation(uint256 tokenId) {
        //if (isTrustedForwarder(msg.sender)) {
        //    require(tokenId == _msgToken(), 'Registry: TOKEN_INVALID');
        //} else {
        //    _invalidateNonce(tokenId);
        //}
        _;
    }


    modifier onlyMintingManager() {
        require(_msgSender() == _mintingManager, 'Registry: SENDER_IS_NOT_MINTING_MANAGER');
        _;
    }

    modifier onlyOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == _msgSender(), 'Registry: SENDER_IS_NOT_OWNER');
        _;
    }

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), 'Registry: SENDER_IS_NOT_APPROVED_OR_OWNER');
        _;
    }



    function namehash(string[] calldata labels) external pure override returns (uint256) {
        return _namehash(labels);
    }

    function exists(uint256 tokenId) external view override returns (bool) {
        return _exists(tokenId);
    }

    /// Minting
    function mintTLD(uint256 tokenId, string calldata uri) external override onlyMintingManager {
        _mint(_mintingManager, tokenId);
        emit NewURI(tokenId, uri);
    }

    function mintWithPassId(
        address to,
        uint passId
    ) external override{

    }

    function mintWithPassIds(
        address to,
        uint[] calldata passIds
    ) external override {

    }

    function mintWithRecords(
        address to,
        string[] calldata labels,
        string[] calldata keys,
        string[] calldata values,
        bool withReverse
    ) external override onlyMintingManager {
        _mintWithRecords(to, labels, keys, values, withReverse);
    }

    /// Transfering

    function setOwner(address to, uint256 tokenId) external override onlyApprovedOrOwner(tokenId) protectTokenOperation(tokenId) {
        _transfer(ownerOf(tokenId), to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721Upgradeable) onlyApprovedOrOwner(tokenId) protectTokenOperation(tokenId) {
        _reset(tokenId);
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721Upgradeable) onlyApprovedOrOwner(tokenId) protectTokenOperation(tokenId) {
        _reset(tokenId);
        _safeTransfer(from, to, tokenId, data);
    }

    /// Burning

    function burn(uint256 tokenId) external override onlyApprovedOrOwner(tokenId) protectTokenOperation(tokenId) {
        _reset(tokenId);
        _burn(tokenId);
    }

    /// Resolution

    function resolverOf(uint256 tokenId) external view override returns (address) {
        return _exists(tokenId) ? address(this) : address(0x0);
    }

    function set(
        string calldata key,
        string calldata value,
        uint256 tokenId
    ) external override onlyApprovedOrOwner(tokenId) protectTokenOperation(tokenId) {
        _set(key, value, tokenId);
    }

    function setMany(
        string[] calldata keys,
        string[] calldata values,
        uint256 tokenId
    ) external override onlyApprovedOrOwner(tokenId) protectTokenOperation(tokenId) {
        _setMany(keys, values, tokenId);
    }

    function setByHash(
        uint256 keyHash,
        string calldata value,
        uint256 tokenId
    ) external override onlyApprovedOrOwner(tokenId) protectTokenOperation(tokenId) {
        _setByHash(keyHash, value, tokenId);
    }

    function setManyByHash(
        uint256[] calldata keyHashes,
        string[] calldata values,
        uint256 tokenId
    ) external override onlyApprovedOrOwner(tokenId) protectTokenOperation(tokenId) {
        _setManyByHash(keyHashes, values, tokenId);
    }

    function reconfigure(
        string[] calldata keys,
        string[] calldata values,
        uint256 tokenId
    ) external override onlyApprovedOrOwner(tokenId) protectTokenOperation(tokenId) {
        _reconfigure(keys, values, tokenId);
    }

    function reset(uint256 tokenId) external override onlyApprovedOrOwner(tokenId) protectTokenOperation(tokenId) {
        _reset(tokenId);
    }

    /**
     * @dev 
     */
    function mint(address user, uint256 tokenId) external {
        _mint(user, tokenId);
    }

    /**
     * @dev 
     */
    function mint(
        address user,
        uint256 tokenId,
        bytes calldata
    ) external {
        _mint(user, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IReverseRegistry-setReverse}.
     */
    function setReverse(uint256 tokenId) external override onlyOwner(tokenId) protectTokenOperation(tokenId) {
        _setReverse(_msgSender(), tokenId);
    }

    /**
     * @dev See {IReverseRegistry-removeReverse}.
     */
    function removeReverse() external override {
        address sender = _msgSender();
        require(_reverses[sender] != 0, 'Registry: REVERSE_RECORD_IS_EMPTY');
        _removeReverse(sender);
    }

    /**
     * @dev See {IReverseRegistry-reverseOf}.
     */
    function reverseOf(address addr) external view override returns (uint256 reverse) {
        uint256 tokenId = _reverses[addr];

        if (!_isReadRestricted(tokenId)) {
            reverse = tokenId;
        }
    }

    /**
     * @dev See {IUNSRegistry-addProxyReader(address)}.
     */
    function addProxyReader(address addr) external override onlyMintingManager {
        _proxyReaders[addr] = true;
    }

    /// Internal

    function _mintWithRecords(
        address to,
        string[] calldata labels,
        string[] calldata keys,
        string[] calldata values,
        bool withReverse
    ) internal {
        uint256 tokenId = _namehash(labels);

        _mint(to, tokenId, _uri(labels), withReverse);
        _setMany(keys, values, tokenId);
    }

    function _unlockWithRecords(
        address to,
        uint256 tokenId,
        string[] calldata keys,
        string[] calldata values,
        bool withReverse
    ) internal {
        _reset(tokenId);
        _transfer(ownerOf(tokenId), to, tokenId);
        _setMany(keys, values, tokenId);

        if (withReverse) {
            _safeSetReverse(to, tokenId);
        }
    }

    function _uri(string[] memory labels) private pure returns (string memory) {
        bytes memory uri = bytes(labels[0]);
        for (uint256 i = 1; i < labels.length; i++) {
            uri = abi.encodePacked(uri, '.', labels[i]);
        }
        return string(uri);
    }

    function _namehash(string[] memory labels) internal pure returns (uint256) {
        uint256 node = 0x0;
        for (uint256 i = labels.length; i > 0; i--) {
            node = _namehash(node, labels[i - 1]);
        }
        return node;
    }

    function _namehash(uint256 tokenId, string memory label) internal pure returns (uint256) {
        require(bytes(label).length != 0, 'Registry: LABEL_EMPTY');
        return uint256(keccak256(abi.encodePacked(tokenId, keccak256(abi.encodePacked(label)))));
    }

    function _mint(
        address to,
        uint256 tokenId,
        string memory uri,
        bool withReverse
    ) internal {
        _mint(to, tokenId);
        emit NewURI(tokenId, uri);

        if (withReverse) {
            // set reverse must be after emission of New URL event in order to keep events' order
            _safeSetReverse(to, tokenId);
        }
    }

    function _baseURI() internal view override(ERC721Upgradeable) returns (string memory) {
        return _prefix;
    }

    function _msgSender() internal view override returns (address) {
        return super._msgSender();
    }

    function _msgData() internal view override returns (bytes calldata) {
        return super._msgData();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (_reverses[from] == tokenId) {
            _removeReverse(from);
        }
    }

    function _setReverse(address addr, uint256 tokenId) internal {
        _reverses[addr] = tokenId;
        emit SetReverse(addr, tokenId);
    }

    function _safeSetReverse(address addr, uint256 tokenId) internal {
        if (address(0xdead) != addr && _reverses[addr] == 0) {
            _setReverse(addr, tokenId);
        }
    }

    function _removeReverse(address addr) internal {
        delete _reverses[addr];
        emit RemoveReverse(addr);
    }

    function _isReadRestricted(uint256 tokenId) internal view override returns (bool) {
        return _upgradedTokens[tokenId] && _proxyReaders[_msgSender()];
    }


    // Reserved storage space to allow for layout changes in the future.
    uint256[47] private __gap;

}