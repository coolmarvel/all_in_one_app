// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../../../openzeppelin-contracts/access/Ownable.sol";
import "../../../openzeppelin-contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface IERC721Capable {
    function totalSupplyCap() external view returns (uint256);

    function balanceCap() external view returns (uint256);
}
