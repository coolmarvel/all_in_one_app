// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @title SPKCalculator
 * @author Wemade Pte, Ltd
 * @dev This contract calculates the index(K) of the staking user.
 */
abstract contract SPKCalculator {
    //===== VARIABLES =====//
    uint public k; // last saved K
    uint public lastMinedRT; // last mined RT

    mapping(address => uint) public userK; // user K

    //===== EVNETS =====//
    event KUpdated(uint indexed k);
    event UserKUpdated(address indexed user, uint indexed userK);

    //===== PUBLIC FUNCTIONS =====//
    /**
     * @dev To get current k
     * @param tm total mined RT
     * @param ts total staked ST
     * @return current k
     */
    function currentK(uint tm, uint ts) public view returns (uint) {
        uint current = k;

        if (tm > lastMinedRT) {
            uint difference = ((tm - lastMinedRT) * 1e4);
            if (difference != 0 && ts != 0) {
                current = current + ((difference * 1e18) / ts);
            }
        }

        return current;
    }

    /**
     * @dev To get reward k
     * @param tm total mined RT
     * @param ts total staked ST
     * @param user address of user
     */
    function rewardK(
        uint tm,
        uint ts,
        address user
    ) public view returns (uint) {
        return
            currentK(tm, ts) > userK[user]
                ? (currentK(tm, ts) - userK[user])
                : 0;
    }

    //===== INTERNAL FUNCTIONS =====//
    /**
     * @dev Update current k
     * @param tm total mined RT
     * @param ts total staked ST
     */
    function _updateK(uint tm, uint ts) internal {
        // assume rate = 100%
        // thisK = current mined amount - last mined amount
        // total = total supply of reward ts
        // y[1] = y[0] + (thisK[0]/total[0])
        // y[2] = y[1] + (thisK[1]/total[1]) = y[0] + (thisK[0]/total[0]) + (thisK[1]/total[1])
        // ...
        // therefore
        // y[n] = y[0] + (thisK[0]/total[0]) + (thisK[1]/total[1]) + ... + (thisK[n-1]/total[n-1])
        if (tm > lastMinedRT) {
            uint difference = (tm - lastMinedRT) * 1e4;
            lastMinedRT = tm;
            if (difference != 0 && ts != 0) {
                k = k + ((difference * 1e18) / ts);
            }
        }
        emit KUpdated(k);
    }

    /**
     * @dev Update user k changing by reward claim
     * @param tm total mined RT
     * @param ts total staked ST
     * @param user address of user
     */
    function _updateUserKWithReward(
        uint tm,
        uint ts,
        address user
    ) internal returns (uint) {
        uint current = currentK(tm, ts);
        uint reward = rewardK(tm, ts, user);
        userK[user] = current;

        emit UserKUpdated(user, userK[user]);

        return reward;
    }
}
