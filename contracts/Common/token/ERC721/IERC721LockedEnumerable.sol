// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Lockable.sol";

interface IERC721LockedEnumerable is IERC721Lockable {
    /** @dev External function that returns a list of tokens in a transferable state.
     * @param owner address owning the tokens
     * @return uint256[] List of token IDs that can not be transfered from the requested address
     */
    function lockedTokensOfOwner(
        address owner
    ) external view returns (uint256[] memory);
}
