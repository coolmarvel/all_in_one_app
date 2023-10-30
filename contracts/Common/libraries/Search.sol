// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library Search {
    function binarySearch(
        uint[] memory array,
        uint value
    ) internal pure returns (int) {
        int low = 0;
        int high = int(array.length - 1);

        while (low <= high) {
            int mid = (low + high) / 2;

            if (array[uint(mid)] == value) {
                return mid;
            } else if (array[uint(mid)] < value) {
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }

        return -1; // Value not found
    }
}
