// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * Decode the data returned by a low-level call
 */
library RevertDecoder {
    function decode(
        bytes memory data
    ) internal pure returns (bytes memory errMsg) {
        if (bytes4(data) == 0x4e487b71) {
            // Panic(uint256)
            return decodePanic(data);
        } else if (bytes4(data) == 0x08c379a0 && data.length > 0) {
            // Error(string)
            return decodeReason(data);
        } else {
            return "";
        }
    }

    /**
     * @dev Decode the error message of a failed low-level call
     * If an error message is defined in the require(), revert() defined in the function
     * from which the call was made, return that message
     */
    function decodeReason(
        bytes memory data
    ) internal pure returns (bytes memory errReason) {
        assembly {
            /**
             *  First 4 bytes is selector (Errror(string))
             *  slice selector for return return error message
             *  https://docs.soliditylang.org/en/v0.8.13/abi-spec.html#errors
             */
            errReason := add(data, 0x04)
        }
        errReason = abi.encodePacked(" [", abi.decode(errReason, (bytes)), "]");
    }

    /**
     * @dev Decode the panic and return error message
     * If reverted due to panic, decode the panic code and return a predefined error message
     */
    function decodePanic(
        bytes memory data
    ) internal pure returns (bytes memory errCode) {
        uint code;
        assembly {
            /**
             *  0x4(selector), 0x20(message = bytes32(0))
             *  last 1 bytes is panic code
             *  https://docs.soliditylang.org/en/v0.8.19/control-structures.html
             */
            code := mload(add(data, 0x24))
        }
        errCode = abi.encodePacked(" [", getPanicMsg(code), "]");
    }

    function getPanicMsg(
        uint panicCode
    ) internal pure returns (bytes memory panicMsg) {
        if (panicCode == 0x00) {
            return "generic compiler inserted panics";
        } else if (panicCode == 0x01) {
            return "running assert function";
        } else if (panicCode == 0x11) {
            return "underflow or overflow";
        } else if (panicCode == 0x12) {
            return "divide or modulo by zero";
        } else if (panicCode == 0x21) {
            return
                "convert a value that is too big or negative into an enum type";
        } else if (panicCode == 0x22) {
            return "access a storage byte array that is incorrectly encoded";
        } else if (panicCode == 0x31) {
            return "call pop function on an empty array";
        } else if (panicCode == 0x32) {
            return "array index out of bound";
        } else if (panicCode == 0x41) {
            return
                "allocate too much memory or create an array that is too large";
        } else if (panicCode == 0x51) {
            return "call a zero-initialized variable of internal function type";
        } else {
            return "panic by undefined reason";
        }
    }
}
