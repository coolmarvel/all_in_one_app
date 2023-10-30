// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
/**
 * This smart contract code is Copyright 2020 WEMADETREE Ltd. For more information see https://wemixnetwork.com/
 */
import "../../contracts/openzeppelin-contracts/token/ERC20/IERC20.sol";

library RecipientLib {
    struct Recipient {
        bytes32 service;
        address recipientRoleV2;
    }

    function _init(
        Recipient storage r,
        bytes32 service,
        address recipientRoleV2
    ) internal {
        r.service = service;
        r.recipientRoleV2 = recipientRoleV2;
    }

    function _addIncome(
        Recipient storage r,
        address token,
        bytes32 column,
        uint256 amount,
        uint256 percentToOwner
    ) internal {
        require(
            r.recipientRoleV2 != address(0),
            "RecipientLib: RecipientRoleV2 address is not set"
        );
        if (
            IERC20(token).allowance(address(this), r.recipientRoleV2) < amount
        ) {
            require(
                IERC20(token).approve(r.recipientRoleV2, type(uint256).max),
                "RecipientLib: approve error"
            );
        }
        require(
            IRecipientRoleV2(r.recipientRoleV2).addIncome(
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

interface IRecipientRoleV2 {
    event IncomeAddedV2(
        bytes32 indexed service,
        address indexed token,
        bytes32 indexed column,
        uint256 toOwner,
        uint256 toService
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
        uint256 percentToOwner
    ) external returns (bool);
}
