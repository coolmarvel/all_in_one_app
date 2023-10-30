// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library Converter {
    /**
     * @dev Function to change bytes to bytes32
     */
    function bytesToBytes32(
        bytes memory input
    ) internal pure returns (bytes32 output) {
        uint length = input.length >= 32 ? 32 : input.length;

        for (uint i = 0; i < length; i++) {
            output |= bytes32(input[i] & 0xFF) >> (i * 8);
        }
    }

    /**
     * @dev Function to change bytes32 to string
     */
    function bytes32ToString(
        bytes32 _bytes32
    ) internal pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    /**
     * @dev Function to change string to bytes32
     * If string length is less than 32, pad for 0 (LSB)
     */
    function stringToBytes32(
        string memory source
    ) internal pure returns (bytes32 result) {
        require(bytes(source).length <= 32, "E: string too long");
        assembly {
            result := mload(add(source, 32))
        }
    }
}
