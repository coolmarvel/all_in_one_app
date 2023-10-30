// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../../openzeppelin-contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IERC721UniqueMetadata {
    function isUsedTokenURI(
        string calldata tokenURI
    ) external view returns (bool);
}
