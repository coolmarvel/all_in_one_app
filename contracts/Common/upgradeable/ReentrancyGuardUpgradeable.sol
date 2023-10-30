// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

abstract contract ReentrancyGuardUpgradeable {
    uint256 private _NOT_ENTERED;
    uint256 private _ENTERED;

    uint256 private _status;

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _initReentrancyGuard() internal {
        _NOT_ENTERED = 1;
        _ENTERED = 2;

        _status = _NOT_ENTERED;
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
