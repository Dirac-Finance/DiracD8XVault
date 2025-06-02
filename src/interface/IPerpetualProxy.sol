// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

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
}
