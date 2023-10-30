// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../openzeppelin-contracts/utils/Counters.sol";

/**
 * This smart contract code is Copyright 2020 WEMADETREE Ltd. For more information see https://wemixnetwork.com/
 *
 */

// UserNonce is used to prevent attempt same signature on contracts that require a user's signature.

contract UserNonce {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) userNonce;

    function getNonce(address _user) public view returns (uint256) {
        return userNonce[_user].current();
    }

    function checkUserNonce(address _user, uint256 _nonce) internal {
        require(_user != address(0), "UserNonce:address is the zero");
        require(
            _nonce == userNonce[_user].current(),
            "UserNonce:mismatch nonce"
        );
        userNonce[_user].increment();
    }
}
