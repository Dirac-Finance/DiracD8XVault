// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IAccountInfo {
    /**
 * @notice  Data structure to store user margin information.
     */
    struct MarginAccount {
        int128 fLockedInValueQC; // unrealized value locked-in when trade occurs
        int128 fCashCC; // cash in collateral currency (base, quote, or quanto)
        int128 fPositionBC; // position in base currency (e.g., 1 BTC for BTCUSD)
        int128 fUnitAccumulatedFundingStart; // accumulated funding rate
    }

    /**
 * @notice  Data structure to return simplified and relevant margin information.
 */
    struct D18MarginAccount {
        int256 lockedInValueQCD18; // unrealized value locked-in when trade occurs: notional amount * price in decimal 18 format
        int256 cashCCD18; // cash in collateral currency (base, quote, or quanto) in decimal 18 format
        int256 positionSizeBCD18; // position in base currency (e.g., 1 BTC for BTCUSD) in decimal 18 format
    }
}
