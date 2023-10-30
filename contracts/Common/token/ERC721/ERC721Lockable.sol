// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../../openzeppelin-contracts/token/ERC721/ERC721.sol";
import "./IERC721Lockable.sol";

/**
 * @title ERC721Lockable
 * @author Wemade Pte, Ltd
 * @dev ERC721Lockable contract to be deployed in wemix.
 * ERC721 modified with transfer lock for a token.
 */
abstract contract ERC721Lockable is IERC721Lockable, ERC721 {
    mapping(uint256 => bool) private _locked;

    /** @dev Lock the tokenId so that it cannot be transferred.
     *  @param tokenId to lock
     */
    function _lock(uint256 tokenId) internal virtual {
        require(_exists(tokenId), "ERC721Lockable: nonexistent token");
        require(!_locked[tokenId], "ERC721Lockable: invalid state");
        _locked[tokenId] = true;
        emit Locked(tokenId);
    }

    /** @dev Unlock the locked tokenId.
     *  @param tokenId to unlock
     */
    function _unlock(uint256 tokenId) internal virtual {
        require(_exists(tokenId), "ERC721Lockable: nonexistent token");
        require(_locked[tokenId], "ERC721Lockable: invalid state");
        delete (_locked[tokenId]);
        emit Unlocked(tokenId);
    }

    function isLocked(uint256 tokenId) public view override returns (bool) {
        return _locked[tokenId];
    }

    /** @dev Reverts If the tokenId is locked
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(!_locked[tokenId], "ERC721Lockable: transfer state error");
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
