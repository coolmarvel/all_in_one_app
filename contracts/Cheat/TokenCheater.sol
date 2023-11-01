// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../openzeppelin-contracts/access/Ownable.sol";
import "../openzeppelin-contracts/security/Pausable.sol";
import "../ContractRegistry.sol";
import "../Token/Base/ERC20Home.sol";
import "../Token/Base/ERC721Home.sol";

// import "../Token/Base/ERC721Home.sol";

contract TokenCheater is Ownable, Pausable, AccessContractRegistry {
  //cheat token
  function cheatToken(address _to, uint256 _value, address _tokenAddr) external {
    require(ERC20Home(_tokenAddr).mint(_to, _value), "TokenCheater: cheatToken error");
  }

  //cheat item
  function cheatItem(address _to, string calldata _itemUuid, address _tokenAddr) external {
    require(ERC721Home(_tokenAddr).mint(_to, _itemUuid) > 0, "TokenCheater: cheatToken error");
  }
}
