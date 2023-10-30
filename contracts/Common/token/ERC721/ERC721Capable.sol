// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../../../openzeppelin-contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./IERC721Capable.sol";

/**
 * @title ERC721Capable
 * @author Wemade Pte, Ltd
 * @dev ERC721Capable contract to be deployed in wemix.
 *
 * Limit the total amount and the number of tokens that the user can own.
 */
abstract contract ERC721Capable is IERC721Capable, ERC721Enumerable {
    uint256 private _totalSupplyCap;
    uint256 private _balanceCap;

    /**@dev Public function to check which address is not retricted about balance cap */
    function isExcludedCapAccount(
        address account
    ) public view virtual returns (bool);

    /**@dev Public function to check total supply cap
     * @return _totalSupplyCap
     */
    function totalSupplyCap() public view override returns (uint256) {
        return _totalSupplyCap;
    }

    /**@dev Public function to check user balance cap
     * @return _balanceCap
     */
    function balanceCap() public view override returns (uint256) {
        return _balanceCap;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        super.transferFrom(from, to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (from == address(0)) {
            // Check totalSupply when minting.
            require(
                _totalSupplyCap == 0 || totalSupply() < _totalSupplyCap,
                "ERC721BalanceCapable: exceeds total supply cap"
            );
        }
        if (to != address(0) && !isExcludedCapAccount(to)) {
            require(
                _balanceCap == 0 || balanceOf(to) < _balanceCap,
                "ERC721BalanceCapable: exceeds balance cap"
            );
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _initERC721Capable(
        uint256 supply,
        uint256 balance
    ) internal virtual {
        _balanceCap = balance;
        _totalSupplyCap = supply;
    }
}
