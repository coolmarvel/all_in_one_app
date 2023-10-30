// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
/**
 * This smart contract code is Copyright 2022 WEMADE Ltd. For more information see https://wemixnetwork.com/
 */
import "../openzeppelin-contracts/token/ERC20/IERC20.sol";

library RecipientLibV4 {
    struct Recipient {
        address recipientRoleV4;
    }

    function _init(Recipient storage r, address recipientRoleV4) internal {
        r.recipientRoleV4 = recipientRoleV4;
    }

    function _addIncome(
        Recipient storage r,
        bytes32 service,
        address token,
        bytes32 column,
        uint amount
    ) internal {
        require(
            r.recipientRoleV4 != address(0),
            "RecipientLib: recipientRoleV4 address is not set"
        );
        if (
            IERC20(token).allowance(address(this), r.recipientRoleV4) < amount
        ) {
            require(
                IERC20(token).approve(r.recipientRoleV4, type(uint).max),
                "RecipientLib: approve error"
            );
        }
        require(
            IRecipientRoleV4(r.recipientRoleV4).addIncome(
                service,
                token,
                column,
                amount
            ),
            "RecipientLib: addIncome error"
        );
    }

    function _addMintIncome(
        Recipient storage r,
        address token,
        uint amount
    ) internal {
        require(
            r.recipientRoleV4 != address(0),
            "RecipientLib: recipientRoleV4 address is not set"
        );
        if (
            IERC20(token).allowance(address(this), r.recipientRoleV4) < amount
        ) {
            require(
                IERC20(token).approve(r.recipientRoleV4, type(uint).max),
                "RecipientLib: approve error"
            );
        }
        require(
            IRecipientRoleV4(r.recipientRoleV4).addMintIncome(token, amount),
            "RecipientLib: addMintIncome error"
        );
    }
}

interface IRecipientRoleV4 {
    event IncomeAddedV4(
        bytes32 indexed service,
        bytes32 indexed wallet,
        address token,
        bytes32 indexed column,
        uint amount
    );
    event MintIncomeAdded(address indexed token, uint amount);
    event AllIncomeAdded(
        bytes32 indexed service,
        address indexed token,
        bytes32 indexed column,
        uint toOwner,
        uint toService
    );
    event RecipientChanged(bytes32 indexed name, address indexed account);
    event OptiongChanged(bytes32 indexed name, uint percent);

    function addIncome(
        bytes32 service,
        address token,
        bytes32 column,
        uint amount
    ) external returns (bool);

    function addMintIncome(address token, uint amount) external returns (bool);

    function getWallet(
        bytes32 service,
        uint index
    ) external view returns (bytes32 name, address account, uint fee);

    function isRecipient(address account) external view returns (bool);

    function isWalletAdded(bytes32 service) external view returns (bool);
}
