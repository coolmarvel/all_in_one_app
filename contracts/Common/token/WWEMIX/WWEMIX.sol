// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IWWEMIX.sol";
import "../../../openzeppelin-contracts/token/ERC20/ERC20.sol";

contract WWEMIX is IWWEMIX, ERC20 {
    constructor() ERC20("Wrapped Wemix", "WWEMIX") {}

    fallback() external payable {
        deposit();
    }

    receive() external payable {
        revert();
    }

    /* =========== FUNCTIONS ===========*/

    /**
     * @notice Exchange Wemix to WWEMIX.
     */
    function deposit() public payable {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Exchange WWEMIX to Wemix.
     */
    function withdraw(uint256 _amount) external {
        require(
            balanceOf(msg.sender) >= _amount,
            "WWEMIX: Sender balance of WWEMIX must be greater than or equal to _amount."
        );

        _burn(msg.sender, _amount);

        payable(msg.sender).transfer(_amount);

        emit Withdraw(msg.sender, _amount);
    }
}
