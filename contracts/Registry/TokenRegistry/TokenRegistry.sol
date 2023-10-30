// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./ITokenRegistry.sol";
import "../../Role/INileRole.sol";
import "../../../../../contracts/openzeppelin-contracts/utils/Address.sol";

contract TokenRegistry is ITokenRegistry {
    using Address for address;

    INileRole _nileRole;

    mapping(bytes32 => address) private _ca;

    constructor(address nileRole) onlyValidAddress(nileRole) {
        _nileRole = INileRole(nileRole);
    }

    modifier onlyEditor() {
        require(
            _nileRole.isEditor(msg.sender),
            "TokenRegistry: msg sender is not editor"
        );
        _;
    }

    modifier onlyValidAddress(address _address) {
        require(_address.isContract(), "TokenRegistry: invalid address");
        _;
    }

    /**
     * @dev regist contract of token
     * @param name member name
     * @param account contract address
     */
    function regist(
        bytes32 name,
        address account
    ) external onlyEditor onlyValidAddress(account) {
        require(
            _ca[name] == address(0),
            "TokenRegistry: already registered token"
        );

        _ca[name] = account;
    }

    /**
     * @dev change contract of token
     * @param name member name
     * @param account contract address
     */
    function change(
        bytes32 name,
        address account
    ) external onlyEditor onlyValidAddress(account) {
        require(
            _ca[name] != address(0),
            "TokenRegistry: it's not registered token"
        );

        _ca[name] = account;
    }

    /**
     * @dev to get address of token
     * @param name member name
     */
    function CA(bytes32 name) external view override returns (address) {
        return _ca[name];
    }
}
