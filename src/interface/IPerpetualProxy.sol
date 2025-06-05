// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./IAccountInfo.sol";
import "./LiquidityPoolData.sol";

interface IPerpetualProxy {
    function getAMMPerpLogic() external view returns (address);

    function getShareTokenFactory() external view returns (address);

    function getOracleFactory() external view returns (address);

    function getTreasuryAddress() external view returns (address);

    function getOrderBookFactoryAddress() external view returns (address);

    function getOrderBookAddress(uint24 _perpetualId) external view returns (address);
    function getLiquidityPool(
        uint8 _poolId
    ) external view returns (ILiquidityPoolData.LiquidityPoolData memory);

    function getMarginAccount(
        uint24 _perpetualId,
        address _traderAddress
    ) external view returns (IAccountInfo.MarginAccount memory);

    function executeCancelOrder(uint24 _perpetualId, bytes32 _digest) external;

    function isOrderExecuted(bytes32 digest) external view returns (bool);

    function isOrderCanceled(bytes32 digest) external view returns (bool);
}
