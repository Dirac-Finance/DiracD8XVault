// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {ERC4626Upgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {ISwapRouter} from "../lib/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {Initializable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {Ownable2StepUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import {TransferHelper} from "../lib/v3-periphery/contracts/libraries/TransferHelper.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IClientOrder} from "./interface/IClientOrder.sol";
import {ILimitOrderBook} from "./interface/ILimitOrderBook.sol";
/**
 * @dev Custom errors.
 */
    error ArrayOutOfBound();
    error InsufficientFunds();
    error LiquidityNotAvailable();
    error OperationFailed();
    error TradeNotMatured();
    error UserExceedMaxDepositAmount();
    error UserNotWhitelisted();
    error ZeroAddress();
    error ZeroAmount();

contract DiracPerpetualVault is Initializable, ERC4626Upgradeable, AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, IERC721Receiver{

    // The trade cycle status
    enum TradeCycleStatus {
        INIT,
        OPEN,
        PENDING,
        CLOSED
    }

    // Data structures
    struct goldPositionData {
        int128 amount;
        uint128 entryPrice;
        uint256 executedAt;
        uint256 postedAt;
    }

    struct btcPositionData {
        int128 amount;
        uint128 entryPrice;
        uint256 executedAt;
        uint256 postedAt;
    }

    struct TradeCycle {
        TradeCycleStatus status;
        uint256 startedAt;
        uint256 endedAt;
        uint256 honeyDeposit; // The amount of honey deposited at the start of the trade cycle
        goldPositionData[] goldPositions;
        btcPositionData[] btcPositions;
    }

    // events that occurred
    event TradeCycleCreated(uint256 indexed cycleId, TradeCycleStatus status, uint256 startTime, uint256 endTime
    );

    event TradeCycleStarted(uint256 indexed tradeCycleId, uint256 honeyDeposit, uint256 startedAt, uint256 expiresAt);
    event TradeCyclePendingEnd(uint256 indexed tradeCycleId);
    event TradeCycleEnded(uint256 indexed tradeCycleId, uint256 endedAt);
    event PostedOrder( uint24 indexed perpetualId, uint128 amount, uint32 flags, uint16 leverageTDR, int128 fLimitPrice);

    mapping(address => bool) public whitelisted;
    uint256 public maxUserDeposit;
    mapping(address => uint256) public userDeposits;
    uint256 public totalUsers;
    mapping(uint256 => TradeCycle) public tradeCycles;
    uint256 public currentTradeCycleId;

    // Assets to use in the vault

    IERC20 private honey;


    // perpetual vault address
    address private perpetualVault;
    address private orderBookAddressBTC;
    address private orderBookAddressGold;

    uint24 private  PERPETUAL_ID_BTC;
    uint24 private  PERPETUAL_ID_GOLD;

    // perpetual id
    uint24 private   perpetualIdBTC;
    uint24 private   perpetualIdGold;

    // Kodiak swap router address
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
        address _orderBookAddressBTC,
        address _orderBookAddressGold,
        address _kodiakSwapRouter,
        address _perpetualVault,
        uint24 _perpetualIdBTC,
        uint24 _perpetualIdGold,
        uint256 _maxUserDeposit
    ) external initializer {
        __ERC4626_init(_honey);
        __ERC20_init("Dirac Perpetual Vaults", "DPV");
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);

        if (address(_honey) == address(0) ||  _perpetualVault == address(0) ||  _kodiakSwapRouter == address(0) ||  _orderBookAddressGold == address(0) ||  _orderBookAddressBTC == address(0)) {
            revert ZeroAddress();
        }
        honey = _honey;
        perpetualVault = _perpetualVault;
        maxUserDeposit = _maxUserDeposit;
        orderBookAddressBTC = _orderBookAddressBTC;
        orderBookAddressGold = _orderBookAddressGold;
        kodiakSwapRouter = _kodiakSwapRouter;
        PERPETUAL_ID_BTC = _perpetualIdBTC;
        PERPETUAL_ID_GOLD = _perpetualIdGold;
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

    function requestToEndTradeCycle() external  onlyRole(DEFAULT_ADMIN_ROLE) onlyTradeCycle(TradeCycleStatus.OPEN) whenNotPaused{
        TradeCycle storage tradeCycle = tradeCycles[currentTradeCycleId];
        tradeCycle.status = TradeCycleStatus.PENDING;

        emit TradeCyclePendingEnd(currentTradeCycleId);
    }
    function endTradeCycle() external onlyRole(DEFAULT_ADMIN_ROLE) onlyTradeCycle(TradeCycleStatus.PENDING) whenNotPaused {
        TradeCycle storage tradeCycle = tradeCycles[currentTradeCycleId];
        tradeCycle.status = TradeCycleStatus.CLOSED;
        tradeCycle.endedAt = uint40(block.timestamp);
        emit TradeCycleEnded(currentTradeCycleId, tradeCycle.endedAt);
    }

    function getTVL() external view returns (uint256) {
        return convertToAssets(totalSupply());
    }

    function postOrder(
        int128 _amount,
        uint32 _flags,
        uint16 _leverageTDR,
        int128 _fLimitPrice,
        bool _isLong
    ) external onlyRole(OPERATOR_ROLE) whenNotPaused {
            // This is for bit coin order
            IClientOrder.ClientOrder[] memory order = new IClientOrder.ClientOrder[](1);
            order[0].iPerpetualId = perpetualIdBTC;
            order[0].flags=_flags;
            order[0].traderAddr= address(this);
            order[0].fAmount=_amount;
            order[0].fLimitPrice=_fLimitPrice;
            order[0].leverageTDR=_leverageTDR; // 0 if deposit and trade separate
            order[0].iDeadline  =  uint32(block.timestamp + 86400 * 3);
            order[0].executionTimestamp  =  uint32(block.timestamp);
            // specify callback target
            order[0].callbackTarget = address(this);
            bytes[] memory sig = new bytes[](1);
            try ILimitOrderBook(orderBookAddressBTC).postOrders(order , sig){
                tradeCycles[currentTradeCycleId].btcPositions.push(
                    btcPositionData({
                        amount: _amount,
                        entryPrice: uint128(_fLimitPrice),
                        executedAt: block.timestamp,
                        postedAt: block.timestamp
                    })
                );
                emit PostedOrder(perpetualIdBTC, _amount, _flags, _leverageTDR, _fLimitPrice);
            } catch {
                revert OperationFailed();
            }
    }
    function executeOrder(
        uint256 _perpetualId,
        uint256 _amount,
        bool _isLong
    ) external onlyRole(OPERATOR_ROLE) whenNotPaused {

    }


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

    /** @dev See {IERC721Receiver-onERC721Received}. */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

}
