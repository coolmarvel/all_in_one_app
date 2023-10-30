// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IVerifyKey.sol";
import "../openzeppelin-contracts/utils/Counters.sol";

abstract contract VerifyKey is IVerifyKey {
    using Counters for Counters.Counter;

    mapping(bytes32 => bytes4) private _functionSelectors;
    mapping(address => Counters.Counter) private _userNonce;

    function getVerifyKey(
        address user,
        bytes32 functionName
    ) external view virtual override returns (bytes32) {
        return _getVerifyKey(user, _functionSelectors[functionName]);
    }

    function _getVerifyKey(
        address user,
        bytes4 selector
    ) internal view virtual returns (bytes32) {
        address _user = user;
        // vault manager address, chainId, user address, user nonce
        return
            keccak256(
                abi.encodePacked(
                    address(this),
                    block.chainid,
                    _user,
                    selector,
                    _userNonce[_user].current()
                )
            );
    }

    function _renewSeed(address user) internal virtual {
        _userNonce[user].increment();
    }

    function _checkAlreadyRegistered(
        bytes32 functionName
    ) internal virtual returns (bool) {
        return _functionSelectors[functionName] == bytes4(0);
    }

    function _registFunctionSelector(
        bytes32 functionName,
        bytes4 selector
    ) internal virtual {
        bytes32 _functionName = functionName;
        require(
            _checkAlreadyRegistered(_functionName),
            "VerifyKey: already registered"
        );
        _functionSelectors[_functionName] = selector;
    }
}
