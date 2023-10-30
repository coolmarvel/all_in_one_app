// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
/**
 * This smart contract code is Copyright 2020 WEMADETREE Ltd. For more information see https://wemixnetwork.com/
 */
import "../openzeppelin-contracts/token/ERC20/IERC20.sol";

library RecipientLibV3 {
    struct Recipient {
        bytes32 service;
        address recipientRoleV3;
    }

    function _init(
        Recipient storage r,
        bytes32 service,
        address recipientRoleV3
    ) internal {
        r.service = service;
        r.recipientRoleV3 = recipientRoleV3;
    }

    function _addIncomeKlay(
        Recipient storage r,
        bytes32 column,
        uint amount,
        uint percentToOwner
    ) internal {
        require(
            r.recipientRoleV3 != address(0),
            "RecipientLib: RecipientRoleV3 address is not set"
        );
        require(
            payable(address(this)).balance >= amount,
            "RecipientLib: lower than expected klay balance"
        );
        require(
            IRecipientRoleV3(r.recipientRoleV3).addIncome{value: amount}(
                r.service,
                address(0),
                column,
                amount,
                percentToOwner
            ),
            "RecipientLib: addIncome error"
        );
    }

    function _addIncome(
        Recipient storage r,
        address token,
        bytes32 column,
        uint amount,
        uint percentToOwner
    ) internal {
        require(
            r.recipientRoleV3 != address(0),
            "RecipientLib: RecipientRoleV3 address is not set"
        );
        if (
            IERC20(token).allowance(address(this), r.recipientRoleV3) < amount
        ) {
            require(
                IERC20(token).approve(r.recipientRoleV3, type(uint256).max),
                "RecipientLib: approve error"
            );
        }
        require(
            IRecipientRoleV3(r.recipientRoleV3).addIncome(
                r.service,
                token,
                column,
                amount,
                percentToOwner
            ),
            "RecipientLib: addIncome error"
        );
    }
}

interface IRecipientRoleV3 {
    event IncomeAddedV3(
        bytes32 indexed service,
        address indexed token,
        bytes32 indexed column,
        uint toOwner,
        uint toService
    );
    event RecipientChanged(bytes32 indexed service, address indexed account);

    function isRecipient(address account) external view returns (bool);

    function addService(bytes32 service, address account) external;

    function removeService(bytes32 service) external;

    function changeRecipient(address account) external;

    function changeServiceRecipient(bytes32 service, address account) external;

    function addIncome(
        bytes32 service,
        address token,
        bytes32 column,
        uint256 amount,
        uint percentToOwner
    ) external payable returns (bool);
}
