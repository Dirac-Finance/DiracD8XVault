// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./IClientOrder.sol";


interface ILimitOrderBook {
    function executeOrders(
        bytes32[] calldata _digests,
        address _executorAddr,
        bytes[] calldata _updateData,
        uint64[] calldata _publishTimes
    ) external payable;

    function postOrders(IClientOrder.ClientOrder[] calldata _orders, bytes[] calldata _signatures) external;
}
