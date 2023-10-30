// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Lockable.sol";
import "./IERC721LockedEnumerable.sol";

/**
 * @title ERC721LockedEnumerable
 * @author Wemade Pte, Ltd
 * @dev ERC721LockedEnumerable contract to be deployed in wemix.
 * Add enumeration function for locked token.
 */
abstract contract ERC721LockedEnumerable is
    ERC721Lockable,
    IERC721LockedEnumerable
{
    mapping(address => uint256[]) private _ownedTokensLocked;
    mapping(uint256 => uint256) private _ownedTokensLockedIndex;

    function _addLockedTokenToOwner(address to, uint256 tokenId) private {
        _ownedTokensLockedIndex[tokenId] = _ownedTokensLocked[to].length;
        _ownedTokensLocked[to].push(tokenId);
    }

    function _removeLockedTokenToOwner(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = _ownedTokensLocked[from].length - 1;
        uint256 tokenIndex = _ownedTokensLockedIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokensLocked[from][lastTokenIndex];

            _ownedTokensLocked[from][tokenIndex] = lastTokenId;
            _ownedTokensLockedIndex[lastTokenId] = tokenIndex;
        }

        _ownedTokensLocked[from].pop();
        delete (_ownedTokensLockedIndex[tokenId]);
    }

    function lockedTokensOfOwner(
        address owner
    ) public view override returns (uint256[] memory) {
        return _ownedTokensLocked[owner];
    }

    /** @dev add locked tokenId to _ownedTokensLocked.
     */
    function _lock(uint256 tokenId) internal virtual override {
        super._lock(tokenId);
        _addLockedTokenToOwner(ownerOf(tokenId), tokenId);
    }

    /** @dev remove the unlocked tokenId from the _ownedTokensLocked.
     */
    function _unlock(uint256 tokenId) internal virtual override {
        super._unlock(tokenId);
        _removeLockedTokenToOwner(ownerOf(tokenId), tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
