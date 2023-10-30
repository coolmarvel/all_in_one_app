// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../../../openzeppelin-contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./IERC721UniqueMetadata.sol";

/**
 * @title ERC721UniqueMetadata
 * @author Wemade Pte, Ltd
 * @dev ERC721UniqueMetadata contract to be deployed in wemix.
 *
 * ERC721UniqueMetadata prevents duplication of token uri.
 */
abstract contract ERC721UniqueMetadata is
    ERC721URIStorage,
    IERC721UniqueMetadata
{
    mapping(bytes32 => bool) private _isUsedTokenURI;

    /**@dev External function to verify already used tokenURI
     * @param tokenURI token uri
     * @return is used or not
     */
    function isUsedTokenURI(
        string calldata tokenURI
    ) external view override returns (bool) {
        return _isUsedTokenURI[keccak256(abi.encodePacked(tokenURI))];
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory tokenURI
    ) internal virtual override {
        super._setTokenURI(tokenId, tokenURI);
        bytes32 _tokenURI = keccak256(abi.encodePacked(tokenURI));
        require(
            !_isUsedTokenURI[_tokenURI],
            "ERC721UniqueMetadata: URI is not unique"
        );
        _isUsedTokenURI[_tokenURI] = true;
    }
}
