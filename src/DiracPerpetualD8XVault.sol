// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./interface/CompositeToken.sol";
import "./interface/IAccountInfo.sol";
import "./interface/LiquidityPoolData.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {ERC4626Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {IClientOrder} from "./interface/IClientOrder.sol";
import {ILimitOrderBook} from "./interface/ILimitOrderBook.sol";
import {IPerpetualProxy} from "./interface/IPerpetualProxy.sol";
import {ISwapRouter} from "v3-periphery/interfaces/ISwapRouter.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {Ownable2StepUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import {TransferHelper} from "v3-periphery/libraries/TransferHelper.sol";
import  "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import  {TransferHelper} from "v3-periphery/libraries/TransferHelper.sol";
import "./library/LOperation.sol";
/**
 * @dev Custom errors.
 */
    error InsufficientFunds();
    error OperationFailed();
    error TradeNotMatured();
    error UserExceedMaxDepositAmount();
    error UserNotWhitelisted();
    error ZeroAddress();
    error ZeroAmount();
    error PerpetualOrderSubmitFailed(string reason);

/// @custom:oz-upgrades-from DiracPerpetualVaultUpgrade
contract DiracPerpetualD8XVault is Initializable, ERC4626Upgradeable, AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {

    // The trade cycle status
    enum TradeCycleStatus {
        INIT,
        OPEN,
        PENDING,
        CLOSED
    }

    // Data structures
    struct PositionData {
        int128 amount;
        uint128 entryPrice;
        uint256 executedAt;
        uint256 postedAt;
        uint32 _flags;
        uint16 _leverageTDR;
        int256 _fTradeAmountABDK;
    }


    struct TradeCycle {
        TradeCycleStatus status;
        uint256 startedAt;
        uint256 endedAt;
        uint256 honeyDeposit; // The amount of honey deposited at the start of the trade cycle
        PositionData[] Positions;
    }

    // events that occurred
    event TradeCycleCreated(uint256 indexed cycleId, TradeCycleStatus status, uint256 startTime, uint256 endTime
    );
    event TradeCycleStarted(uint256 indexed tradeCycleId, uint256 honeyDeposit, uint256 startedAt, uint256 expiresAt);
    event TradeCyclePendingEnd(uint256 indexed tradeCycleId);
    event TradeCycleEnded(uint256 indexed tradeCycleId, uint256 endedAt);
    event PostedOrder( uint24 indexed perpetualId, int128 amount, uint32 flags, uint16 leverageTDR, int128 fLimitPrice);
    event PerpetualAdded(uint24 perpetualId, address lobAddr, address mgnTknAddrOfPool);
    event MarginTokenSent(uint24 perpetualId, address to, uint256 amountDecN);

    mapping(address => bool) public whitelisted;
    uint256 public maxUserDeposit;
    mapping(address => uint256) public userDeposits;
    uint256 public totalUsers;
    mapping(uint256 => TradeCycle) public tradeCycles;
    uint256 public currentTradeCycleId;

    // Assets to use in the vault
    IERC20 private honey;

    // Perpetuals are identified by a unique id, which is a uint24
    mapping(uint24 => address) public orderBookAddresses;
    // each perpetual is in a pool. Perpetuals in a pool share the margin token
    mapping(uint24 => address) public mgnTknAddrOfPool;

    // D8X addresses for smart contract interaction
    address private perpetualProxy;

    // perpetual id
    uint24 private   perpetualIdBTC;
    uint24 private   perpetualIdGold;

    // Kodiak swap router address (in case we need to accept other currencies as deposits to be swapped to HONEY and sent to D8X/MadHoney). In case we need to swap token
    address private  kodiakSwapRouter;
    // operator role for operations like deposits, withdrawals, and trades
    bytes32 private constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    // This role has the full control over the contract

    modifier onlyTradeCycle(TradeCycleStatus status) {
        if (tradeCycles[currentTradeCycleId].status != status) {
            revert OperationFailed();
        }
        _;
    }

    modifier whenTradeClosed() {
        TradeCycle memory tradeCycle = tradeCycles[currentTradeCycleId];
        if (
            tradeCycle.status != TradeCycleStatus.INIT &&
            tradeCycle.status != TradeCycleStatus.CLOSED
        ) {
            revert OperationFailed();
        }

        _;
    }

    /**
    * @notice Restricts function execution to addresses that have been whitelisted.
     */
    modifier onlyWhitelisted() {
        if (!whitelisted[msg.sender]) {
            revert UserNotWhitelisted();
        }

        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }


    /**
    * @notice Pauses all contract operations.
     * @dev Callable only by the admin.
     */
    function emergencyPause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses contract operations.
     * @dev Callable only by the admin.
     */
    function emergencyUnpause() external onlyRole(DEFAULT_ADMIN_ROLE){
        _unpause();
    }

    function startTradeCycle(
        uint256 _duration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) whenTradeClosed whenNotPaused {
        currentTradeCycleId = currentTradeCycleId + 1;
        TradeCycle storage tradeCycle = tradeCycles[currentTradeCycleId];
        tradeCycle.honeyDeposit = honey.balanceOf(address(this));
        tradeCycle.status = TradeCycleStatus.OPEN;
        tradeCycle.startedAt = uint40(block.timestamp);
        tradeCycle.endedAt = uint40(block.timestamp + _duration);

        emit TradeCycleStarted(
            currentTradeCycleId,
            tradeCycle.honeyDeposit,
            tradeCycle.startedAt,
            tradeCycle.endedAt
        );
    }


    function updateMaxUserDeposit(
        uint256 _newMaxUserDeposit
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxUserDeposit = _newMaxUserDeposit;
    }

    function updateTradeCycleDuration(
        uint40 _newTradeCycleEndDate
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        TradeCycle storage tradeCycle = tradeCycles[currentTradeCycleId];
        if (uint40(block.timestamp) > _newTradeCycleEndDate) {
            revert();
        }

        tradeCycle.endedAt = _newTradeCycleEndDate;
    }
    /**
     * @notice Updates the whitelist status of multiple users.
     * @dev Skips the zero address. Callable only by an operator.
     * @param _users An array of addresses to update.
     * @param _status The new whitelist status.
     */
    function whitelistUsers(
        address[] calldata _users,
        bool _status
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 count = _users.length;
        for (uint256 i; i < count; ++i) {
            if (_users[i] != address(0)) {
                whitelisted[_users[i]] = _status;
            }
        }
    }

    function initialize(
        IERC20 _honey,
        address _kodiakSwapRouter,
        address _perpetualProxy,
        uint24 _perpetualIdBTC,
        uint24 _perpetualIdGold,
        uint256 _maxUserDeposit
    ) external initializer {
        __ERC20_init("Dirac D8X Perpetual Vaults", "DDPV");
        __ERC4626_init(_honey);
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);

        if (address(_honey) == address(0) ||  _perpetualProxy == address(0) ||  _kodiakSwapRouter == address(0)) {
            revert ZeroAddress();
        }
        honey = _honey;
        perpetualProxy = _perpetualProxy;
        maxUserDeposit = _maxUserDeposit;
        kodiakSwapRouter = _kodiakSwapRouter;
        perpetualIdBTC = _perpetualIdBTC;
        perpetualIdGold = _perpetualIdGold;
    }

    // In development this function is use to update some variables. In production it should be deleted
    function updateVariables(
        IERC20 _honey,
        address _kodiakSwapRouter,
        address _perpetualProxy,
        uint24 _perpetualIdBTC,
        uint24 _perpetualIdGold,
        uint256 _maxUserDeposit
    ) external {
        if (address(_honey) == address(0) ||  _perpetualProxy == address(0) ||  _kodiakSwapRouter == address(0)) {
            revert ZeroAddress();
        }
        honey = _honey;
        perpetualProxy = _perpetualProxy;
        maxUserDeposit = _maxUserDeposit;
        kodiakSwapRouter = _kodiakSwapRouter;
        perpetualIdBTC = _perpetualIdBTC;
        perpetualIdGold = _perpetualIdGold;

    }

    /**
    * @notice Deposits assets and mints corresponding shares.
     * @dev Only allowed when the trade cycle status is INIT and the caller is whitelisted.
     * @param _assets The amount of assets to deposit.
     * @param _receiver The address receiving the minted shares.
     * @return shares The number of shares minted.
     */
    function deposit(
        uint256 _assets,
        address _receiver
    )
    public
    override
    whenTradeClosed
    onlyWhitelisted
    whenNotPaused
    returns (uint256 shares)
    {
        if (_assets == 0) {
            revert ZeroAmount();
        }
        if (_receiver == address(0)) {
            revert ZeroAddress();
        }
        uint256 currentAssets = convertToAssets(balanceOf(_receiver));
        if (currentAssets + _assets > maxUserDeposit) {
            revert UserExceedMaxDepositAmount();
        }
        if (userDeposits[msg.sender] == 0 && _assets > 0) {
            totalUsers++;
        }
        userDeposits[msg.sender] += _assets;
        shares = super.deposit(_assets, _receiver);
    }

    /**
     * @notice Mints shares corresponding to the specified amount of assets.
     * @dev Only allowed when the trade cycle status is INIT and the caller is whitelisted.
     * @param _shares The number of shares to mint.
     * @param _receiver The address receiving the minted shares.
     * @return assets The amount of assets corresponding to the minted shares.
     */
    function mint(
        uint256 _shares,
        address _receiver
    )
    public
    override
    whenTradeClosed
    onlyWhitelisted
    whenNotPaused
    returns (uint256 assets)
    {
        assets = convertToAssets(_shares);
        if (assets == 0) {
            revert ZeroAmount();
        }
        uint256 currentAssets = convertToAssets(balanceOf(_receiver));
        if (currentAssets + assets > maxUserDeposit) {
            revert UserExceedMaxDepositAmount();
        }
        if (userDeposits[msg.sender] == 0 && assets > 0) {
            totalUsers++;
        }
        userDeposits[msg.sender] += assets;
        assets = super.mint(_shares, _receiver);
    }

    /**
     * @notice Withdraws assets by burning shares.
     * @dev Only allowed when the trade cycle status is INIT and the caller is whitelisted.
     * @param _assets The amount of assets to withdraw.
     * @param _receiver The address receiving the withdrawn assets.
     * @param _owner The owner of the shares being burned.
     * @return shares The number of shares burned.
     */
    function withdraw(
        uint256 _assets,
        address _receiver,
        address _owner
    )
    public
    override
    whenTradeClosed
    onlyWhitelisted
    whenNotPaused
    returns (uint256 shares)
    {
        if (_assets == 0) {
            revert ZeroAmount();
        }

        if (userDeposits[msg.sender] > _assets) {
            userDeposits[msg.sender] -= _assets;
        } else {
            delete userDeposits[msg.sender];
            if(totalUsers > 0) {
                totalUsers--;
            }
        }
        shares = super.withdraw(_assets, _receiver, _owner);
    }

    /**
     * @notice Redeems shares for assets.
     * @dev Only allowed when the trade cycle status is INIT and the caller is whitelisted.
     * @param _shares The number of shares to redeem.
     * @param _receiver The address receiving the redeemed assets.
     * @param _owner The owner of the shares being redeemed.
     * @return assets The amount of assets received.
     */

    function redeem(
        uint256 _shares,
        address _receiver,
        address _owner
    )
    public
    override
    whenTradeClosed
    onlyWhitelisted
    whenNotPaused
    nonReentrant
    returns (uint256 assets)
    {
        assets = super.redeem(_shares, _receiver, _owner);

        if (assets == 0) {
            revert ZeroAmount();
        }

        if (userDeposits[msg.sender] > assets) {
            userDeposits[msg.sender] -= assets;
        } else {
            delete userDeposits[msg.sender];
            if (totalUsers > 0) {
                totalUsers--;
            }
        }
    }

    /**
     * @notice Requests to end the current trade cycle.
     * @dev Only callable by the admin when the trade cycle status is OPEN and the contract is not paused.
     */
    function requestToEndTradeCycle() external  onlyRole(DEFAULT_ADMIN_ROLE) onlyTradeCycle(TradeCycleStatus.OPEN) whenNotPaused{
        TradeCycle storage tradeCycle = tradeCycles[currentTradeCycleId];
        tradeCycle.status = TradeCycleStatus.PENDING;

        emit TradeCyclePendingEnd(currentTradeCycleId);
    }

    /**
     * @notice Ends the current trade cycle.
     * @dev Only callable by the admin when the trade cycle status is PENDING and the contract is not paused.
     */

    function endTradeCycle() external onlyRole(DEFAULT_ADMIN_ROLE) onlyTradeCycle(TradeCycleStatus.PENDING) whenNotPaused {
        TradeCycle storage tradeCycle = tradeCycles[currentTradeCycleId];
        tradeCycle.status = TradeCycleStatus.CLOSED;
        tradeCycle.endedAt = uint40(block.timestamp);
        emit TradeCycleEnded(currentTradeCycleId, tradeCycle.endedAt);
    }

    /**
     * @notice Returns the total value locked (TVL) in the vault.
     * @return The total value locked in the vault.
     */
    function getTVL() external view returns (uint256) {
        return convertToAssets(totalSupply());
    }

    /**
     * @notice Adds a specific D8X perpetual Id in order to use it.
     * @dev Only callable by an operator.
     * @param isBTC Whether the perpetual is for BTC or Gold.
     */
    function addPerpetual(bool isBTC) external onlyRole(OPERATOR_ROLE) {
        // set order book address
        address lobAddr;
        uint24 _iPerpetualId;
        if(isBTC){
            _iPerpetualId = perpetualIdBTC;
            lobAddr = IPerpetualProxy(perpetualProxy).getOrderBookAddress(
                perpetualIdBTC
            );
        }else{
            _iPerpetualId=perpetualIdGold;
            lobAddr = IPerpetualProxy(perpetualProxy).getOrderBookAddress(
                perpetualIdGold
            );
        }
        orderBookAddresses[_iPerpetualId] = lobAddr;
        // register margin token
        uint8 poolId = uint8(_iPerpetualId / 100_000);
        if (mgnTknAddrOfPool[poolId] == address(0)) {
            // set margin token address for pool
            ILiquidityPoolData.LiquidityPoolData memory lp = IPerpetualProxy(
                perpetualProxy
            ).getLiquidityPool(poolId);
            mgnTknAddrOfPool[poolId] = lp.marginTokenAddress;
        }
        emit PerpetualAdded(_iPerpetualId, lobAddr, mgnTknAddrOfPool[poolId]);
    }

    /**
     * @notice Approves the margin token for a specific perpetual.
     * @dev Only callable by an operator.
     * @param _amount The amount to approve.
     * @param isBTC Whether the perpetual is for BTC or Gold.
     */
    function approveAmountForPerpetualMgnTkn(uint256 _amount, bool isBTC) external onlyRole(OPERATOR_ROLE){
        uint24 _iPerpetualId;
        if(isBTC){
            _iPerpetualId = perpetualIdBTC;
        }else{
            _iPerpetualId = perpetualIdGold;
        }
        uint8 poolId = uint8(_iPerpetualId / 100_000);
        address mgnTkn = mgnTknAddrOfPool[poolId];
        require(mgnTkn != address(0), "set ob addrs");
        IERC20(mgnTkn).approve(perpetualProxy, _amount);
    }

    /**
     * Approve a registered token to be used in a composite token pool.
     * @param _amount spend amount
     * @param _iPerpetualId perpetual Id
     * @param _spendToken Token to spend
     */
    function approveCompositeToken(
        uint256 _amount,
        uint24 _iPerpetualId,
        address _spendToken
    ) external onlyRole(OPERATOR_ROLE) {
        uint8 poolId = uint8(_iPerpetualId / 100_000);
        address compositeToken = mgnTknAddrOfPool[poolId];
        require(compositeToken != address(0), "no composite");
        require(_spendToken != address(0), "no token");
        address registeredToken = CompositeToken(compositeToken).registeredToken(address(this));
        if (registeredToken == address(0)) {
            // not yet registered
            CompositeToken(compositeToken).registerAccount(_spendToken);
        } else {
            require(registeredToken == _spendToken, "wrong token");
        }
        IERC20(_spendToken).approve(compositeToken, _amount);
    }

    /**
     * @notice Posts an order for a specific perpetual.
     * @dev Only callable by an operator when the trade cycle status is OPEN.
     * @param _flags Flags for the order.
     * @param _leverageTDR Leverage TDR for the order.
     * @param _fTradeAmountABDK The trade amount in ABDK format.
     * @param _isLong Whether the order is long or short.
     */
    function postOrder(
        uint32 _flags,
        uint16 _leverageTDR,
        int128 _fTradeAmountABDK,
        bool _isLong
    ) external onlyRole(OPERATOR_ROLE) whenNotPaused nonReentrant onlyTradeCycle(TradeCycleStatus.OPEN) {
        // This is for bit coin order
        uint24 _iPerpetualId;
        IClientOrder.ClientOrder[] memory order = new IClientOrder.ClientOrder[](1);
        if(_isLong){
            _iPerpetualId = perpetualIdBTC;
        } else {
            _iPerpetualId = perpetualIdGold;
        }
        address orderBookAddr = orderBookAddresses[_iPerpetualId];
        require(orderBookAddr != address(0), "order book unknown");
        order[0].iPerpetualId = _iPerpetualId;
        order[0].flags=_flags;
        order[0].traderAddr= address(this);
        order[0].fAmount=_fTradeAmountABDK;
        order[0].fLimitPrice=_fTradeAmountABDK > 0 ? LOperation.MAX_64x64 : int128(0);
        order[0].leverageTDR=_leverageTDR; // 0 if deposit and trade separate
        order[0].iDeadline  =  uint32(block.timestamp + 86400 * 3);
        order[0].executionTimestamp  =  uint32(block.timestamp);
        // specify callback target
        // order[0].callbackTarget = address(this);
        bytes[] memory sig = new bytes[](1);
        try ILimitOrderBook(orderBookAddr).postOrders(order , sig){

            tradeCycles[currentTradeCycleId].Positions.push(
                PositionData({
                    amount: _fTradeAmountABDK,
                    entryPrice: uint128(order[0].fLimitPrice),
                    executedAt: 0,
                    postedAt: block.timestamp,
                    _flags : _flags,
                    _leverageTDR : _leverageTDR,
                    _fTradeAmountABDK : _fTradeAmountABDK
                })
            );
            emit PostedOrder(_iPerpetualId, _fTradeAmountABDK, _flags, _leverageTDR, order[0].fLimitPrice);
        } catch Error(string memory reason) {
            revert PerpetualOrderSubmitFailed(reason);
        }
    }

    /**
     * @notice Swaps tokens using the Kodiak swap router.
     * @dev Only callable by an operator.
     * @param _tokenIn The address of the token to swap from.
     * @param _tokenOut The address of the token to swap to.
     * @param _amountIn The amount of the input token to swap.
     * @param _amountOutMin The minimum amount of the output token to receive.
     */
    function swapToken(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin
    ) external onlyRole(OPERATOR_ROLE) whenNotPaused {
        if (IERC20(_tokenIn).balanceOf(address (this)) < _amountIn) {
            revert InsufficientFunds();
        }
        if (_tokenIn == address(0) || _tokenOut == address(0)) {
            revert ZeroAddress();
        }
        if (_amountIn == 0 || _amountOutMin == 0) {
            revert ZeroAmount();
        }
        TransferHelper.safeApprove(
            _tokenIn,
            kodiakSwapRouter,
            _amountIn
        );
        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter
            .ExactInputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            fee: 3000,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: _amountOutMin,
            sqrtPriceLimitX96: 0
        });
        ISwapRouter(kodiakSwapRouter).exactInputSingle(swapParams);
    }

    /**
    * Return margin account information in decimal 18 format
    * @param isBTC whether the perpetual is BTC or Gold
     */
    function getMarginAccount(
        bool isBTC
    ) external view onlyRole(DEFAULT_ADMIN_ROLE) returns  (IAccountInfo.D18MarginAccount memory) {
        uint24 _iPerpetualId;
        if(isBTC){
            _iPerpetualId = perpetualIdBTC;
        }else{
            _iPerpetualId = perpetualIdGold;
        }
        IAccountInfo.MarginAccount memory acc = IPerpetualProxy(perpetualProxy).getMarginAccount(
            _iPerpetualId,
            address(this)
        );
        IAccountInfo.D18MarginAccount memory accD18;
        accD18.lockedInValueQCD18 = LOperation.toDec18(acc.fLockedInValueQC); // unrealized value locked-in when trade occmurs: price * position size
        accD18.cashCCD18 = LOperation.toDec18(acc.fCashCC); // cash in collateral currency (base, quote, or quanto)
        accD18.positionSizeBCD18 = LOperation.toDec18(acc.fPositionBC); // position in base currency (e.g., 1 BTC for BTCUSD)
        return accD18;
    }


    /**
   * Withdraw margin token balance linked to a given perpetual Id
   * @param isBTC whether the perpetual is BTC or Gold
     */
    function transferMarginCollateralTo(bool isBTC) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint24 _iPerpetualId;
        if(isBTC){
            _iPerpetualId = perpetualIdBTC;
        }else{
            _iPerpetualId = perpetualIdGold;
        }
        uint8 poolId = uint8(_iPerpetualId / 100_000);
        address mgnTknAddr = mgnTknAddrOfPool[poolId];
        IERC20 marginToken = IERC20(mgnTknAddr);
        uint256 balance = marginToken.balanceOf(address(this));
        // transfer the margin token to the user
        TransferHelper.safeTransfer(
            mgnTknAddr,
            address(this),
            balance
        );
        //marginToken.safeTransfer(msg.sender, balance);
        emit MarginTokenSent(_iPerpetualId, msg.sender, balance);
    }

    /**
     * Withdraw ERC20 tokens stored in this contract
     * Required with trading in a pool with a composite token
     * @param _tokenAddr Token address
     */
    function transferTokensTo(address _tokenAddr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20 token = IERC20(_tokenAddr);
        uint256 balance = token.balanceOf(address(this));
        // transfer the margin token to the user
        TransferHelper.safeTransfer(
            _tokenAddr,
            address(this),
            balance
        );
        //token.safeTransfer(msg.sender, balance);
        emit MarginTokenSent(0, msg.sender, balance);
    }

    /** @dev See {IERC721Receiver-onERC721Received}. */
    /*function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    */
}

