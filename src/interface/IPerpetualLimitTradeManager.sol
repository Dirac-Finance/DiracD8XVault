// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./IPerpetualOrder.sol";


interface IPerpetualLimitTradeManager is IPerpetualOrder {

    function executeCancelOrder(uint24 _perpetualId, bytes32 _digest) external;

    function isOrderExecuted(bytes32 digest) external view returns (bool);

    function isOrderCanceled(bytes32 digest) external view returns (bool);
}