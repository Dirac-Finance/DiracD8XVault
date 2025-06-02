// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

library LOperation {

    int256 private constant DECIMALS = 10 ** 18;
    int128 private constant ONE_64x64 = 2 ** 64;
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    int128 private constant TEN_64x64 = 0xa0000000000000000;
    event CallbackReceived(bytes32 orderDigest, bool isExecuted);

    /**
     * Convert signed decimal-18 number to ABDK-128x128 format
     * @param x number decimal-18
     * @return ABDK-128x128 number
     */
    function _fromDec18(int256 x) internal pure returns (int128) {
        int256 result = (x * ONE_64x64) / DECIMALS;
        require(x >= MIN_64x64 && x <= MAX_64x64, "result out of range");
        return int128(result);
    }

    /**
     * Convert ABDK-128x128 format to signed decimal-18 number
     * @param x number in ABDK-128x128 format
     * @return decimal 18 (signed)
     */
    function toDec18(int128 x) internal pure returns (int256) {
        return (int256(x) * DECIMALS) / ONE_64x64;
    }

    /**
     * Convert signed 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function _fromInt(int256 x) internal pure returns (int128) {
        require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF, "ABDK.fromInt");
        return int128(x << 64);
    }

    /**
     * Callback function that will be called once the order is executed or cancelled
     * @param orderDigest unique identifier for the order
     * @param isExecuted true if order was succesfully executed
     */
    function d8xExecutionCallback(bytes32 orderDigest, bool isExecuted) external {
        // msg.sender is the order-book contract, so we can upgrade the corresponding
        // margin account
        emit CallbackReceived(orderDigest, isExecuted);
    }
}
