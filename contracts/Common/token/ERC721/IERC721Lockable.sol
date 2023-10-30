// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Lockable {
    event Locked(uint256 indexed tokenId);
    event Unlocked(uint256 indexed tokenId);

    /** @dev External function that checks the lock status of the token.
     *  @param tokenId to check
     *  @return is locked (true : locked, false : unlocked)
     */
    function isLocked(uint256 tokenId) external view returns (bool);
}
