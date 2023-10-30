// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IPteRegistry.sol";
import "../../Role/INileRole.sol";
import "../../../../../contracts/openzeppelin-contracts/utils/Address.sol";

/**
 * @title PteRegistry
 * @author Wemade Pte, Ltd
 * @dev Register the EOA of Trust Pte and the fees to be received from Trust
 */
contract PteRegistry is IPteRegistry {
    using Address for address;

    INileRole internal _nileRole;

    mapping(bytes32 => Pte) private _ptes; // bytes32 : Pte name
    mapping(address => bool) private _isRegistered;

    event Registered(bytes32 name, address pte, uint minFeeRatio);
    event Changed(bytes32 name, address pte, uint minFeeRatio);

    constructor(address nileRole) {
        _nileRole = INileRole(nileRole);
    }

    modifier onlyEditor() {
        require(
            _nileRole.isEditor(msg.sender),
            "PteRegistry: msg sender is not editor"
        );
        _;
    }

    function regist(
        bytes32 name,
        address pte,
        uint minFeeRatio
    ) external onlyEditor {
        require(
            _ptes[name].pte == address(0),
            "PteRegistry: it's already registered Pte name"
        );
        require(
            pte != address(0) && !pte.isContract(),
            "PteRegistry: invalid address"
        );
        require(
            !_isRegistered[pte],
            "PteRegistry: it's already registered Pte address"
        );
        require(minFeeRatio > 0, "PteRegistry: invalid fee ratio");

        _ptes[name] = Pte({pte: pte, feeRatio: minFeeRatio});

        _isRegistered[pte] = true;

        emit Registered(name, pte, minFeeRatio);
    }

    function changePteInfo(
        bytes32 name,
        address pte,
        uint minFeeRatio
    ) external onlyEditor {
        require(
            _ptes[name].pte != address(0),
            "PteRegistry: it's not registered Pte name"
        );
        require(
            pte != address(0) && !pte.isContract(),
            "PteRegistry: invalid address"
        );
        require(
            _isRegistered[pte],
            "PteRegistry: it's not registered Pte address"
        );
        require(minFeeRatio > 0, "PteRegistry: invalid fee ratio");

        _ptes[name] = Pte({pte: pte, feeRatio: minFeeRatio});

        emit Changed(name, pte, minFeeRatio);
    }

    function getRegisteredPte(
        bytes32 name
    ) external view override returns (Pte memory) {
        return _ptes[name];
    }

    function isRegistered(address pte) external view override returns (bool) {
        return _isRegistered[pte];
    }
}
