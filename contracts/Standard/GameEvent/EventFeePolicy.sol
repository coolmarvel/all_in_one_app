//  SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract EventFeePolicy {
    struct Policy {
        bool isRatio; // true = percent, false = cost
        uint fee; // fee
    }

    mapping(uint => mapping(uint => Policy)) internal _feePolicies; // event id => (action type => policy)

    // flags
    // 0 = enter, 1 = additional pay, 2 = reward, 3 = drop
    uint8 internal constant ENTER = 0;
    uint8 internal constant ADD = 1;
    uint8 internal constant REWARD = 2;
    uint8 internal constant CANCEL = 3;

    function _changeFeePolicy(
        uint eventId,
        uint8 actionType,
        bool isRatio,
        uint fee
    ) internal {
        Policy storage _policy = _feePolicies[eventId][actionType];

        _policy.isRatio = isRatio;
        _policy.fee = fee;
    }

    /**
     *   @return rewardAmout    user reward amount
     *   @return incomeAmount    add income amount
     */
    function _distributeToken(
        uint8 actionType,
        uint eventId,
        uint amount
    ) internal view returns (uint rewardAmout, uint incomeAmount) {
        Policy memory _policy = _feePolicies[eventId][actionType];

        // calulate amount of tokens distributed according to the distribution policy
        bool isRatio = _policy.isRatio;
        uint fee = _policy.fee;

        unchecked {
            incomeAmount = isRatio ? incomeAmount = (amount * fee) / 100 : fee;

            require(
                amount >= incomeAmount,
                "EventFeePolicy: income amount exceeds amount"
            );
            rewardAmout = amount - incomeAmount;
        }

        // incomeAmount = isRatio ? incomeAmount = amount.mul(fee).div(100) : fee;
        // rewardAmout = amount.sub(incomeAmount, "EventFeePolicy: invalid fee");
    }

    function _deleteFeePolicy(uint eventId) internal returns (bool) {
        delete _feePolicies[eventId][ENTER];
        delete _feePolicies[eventId][ADD];
        delete _feePolicies[eventId][REWARD];
        delete _feePolicies[eventId][CANCEL];

        return true;
    }
}
