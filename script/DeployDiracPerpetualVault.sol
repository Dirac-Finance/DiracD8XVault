// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import "forge-std/Script.sol";
import "../src/DiracPerpetualVault.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {DiracPerpetualVault} from "../src/DiracPerpetualVault.sol";
import {DiracPerpetualVaultUpgrade} from "../src/DiracPerpetualVaultUpgrade.sol";
import "../src/interface/IAccountInfo.sol";
import  "forge-std/console.sol";
import {DiracPerpetualD8XVault} from "../src/DiracPerpetualD8XVault.sol";
contract DeployDiracPerpetualVault is Script{
    IERC20 internal honey = IERC20(0xFCBD14DC51f0A4d49d5E53C2E0950e0bC26d0Dce); // HONEY
    address internal kodiakSwapRouter=0xEd158C4b336A6FCb5B193A5570e3a571f6cbe690; // Kodiak V3 SwapRouter
    address internal perpetualVault=0xb6329c7168b255Eca8e5c627b0CCe7A5289C8b7F;
    uint24  internal perpetualIdBTC = 100003; // BTC perpetual ID
    uint24  internal perpetualIdGold = 100013; // Gold perpetual ID

function run() external {

        // deployment
        // address  vault =0x42c79B19d9266c80e970383Bac68aa0a5E351C3E; old contract
        address  vault = 0xD47B1374E35Ddf8EaAe06bbe8EdC25B178Febe9b;
        //deploy();
        //startTradeCycle(vault, 84000);
        //approveCompositeToken(vault, 10 ether, perpetualIdBTC, address(honey));
        //approveCompositeToken(vault, 5 ether, perpetualIdGold, address(honey));
        //postOrder(vault,  0x40000000, 100,   1730808206853421, true);
        //approveAmountForPerpetualMgnTkn(vault,1 ether, true);
        //upgrade(vault);
        //addPerpetual(vault, true);
        //addPerpetual(vault, false);
        //getMarginAccount(vault, true);
        //updateVariables( vault, IERC20(honey), kodiakSwapRouter, perpetualVault, perpetualIdBTC, perpetualIdGold, 50 ether);
        //requestToEndTradeCycle(vault);
        //endTradeCycle(vault);

        //// Process

        // 2. Whitelist address finish

        //address[] memory whitelist = new address[](1);
        //whitelist[0] = 0xC9104F69637C03D2646bF8225fcBb796C148D543;
        //whitelistUsers(vault, whitelist, true);
        // 5 Allowance finish
        //approveCompositeToken(vault, 15 ether, perpetualIdBTC, address(honey)); // 10 HONEY
        //approveCompositeToken(vault, 15 ether, perpetualIdGold, address(honey)); // 5 HONEY
        // 4 Start trade cycle finish
        //startTradeCycle(vault, 84000); // 84000 seconds = 1 day
        // 1. Initialization of the vault finish
         // initialisation(vault);
        // 3. make deposit finish

        //deposit(vault, 15 ether, address(0xC9104F69637C03D2646bF8225fcBb796C148D543)); // 10 HONEY
        // 6 open orders

        // 7. get account informations

        // 8. Close trade


        //updateMaxDeposit(vault);
        //addOperator(vault, 0x0A5980A4923388b9Bd4108b27e5bD65998deb6C7);
        //transferOwnership(vault, 0x0A5980A4923388b9Bd4108b27e5bD65998deb6C7);
    }

    function setUp() external {
        // Set up any necessary state or configurations before running the script
    }
    function deploy() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address proxy = Upgrades.deployTransparentProxy(
            "DiracPerpetualVaultUpgrade.sol",
            msg.sender,
            abi.encodeCall(
                DiracPerpetualVaultUpgrade.initialize,
                (
                    honey,
                    kodiakSwapRouter,
                    perpetualVault,
                    perpetualIdBTC,
                    perpetualIdGold,
                    50 ether
                )
            )
        );

        console.log("Proxy: ");
        console.logAddress(proxy);

        address implementationAddress = Upgrades.getImplementationAddress(
            proxy
        );
        address adminAddress = Upgrades.getAdminAddress(proxy);

        console.log("Implementation: ");
        console.logAddress(implementationAddress);

        console.log("Proxy Admin: ");
        console.logAddress(adminAddress);

        require(adminAddress != address(0), "Invalid admin address");

        vm.stopBroadcast();
    }
    function updateVariables(

        address vault,
        IERC20 _honey,
        address _kodiakSwapRouter,
        address _perpetualVault,
        uint24 _perpetualIdBTC,
        uint24 _perpetualIdGold,
        uint256 _maxUserDeposit
    ) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        DiracPerpetualVaultUpgrade instance = DiracPerpetualVaultUpgrade(
            payable(vault)
        );
        instance.updateVariables(
            _honey,
            _kodiakSwapRouter,
            _perpetualVault,
            _perpetualIdBTC,
            _perpetualIdGold,
            _maxUserDeposit
        );
        vm.stopBroadcast();
    }

    function upgrade(address proxyAddress) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        /*bytes memory data = abi.encodeCall(
        DiracPerpetualD8XVault.reinitializerV2,
            (
                honey,
                kodiakSwapRouter,
                perpetualVault,
                perpetualIdBTC,
                perpetualIdGold,
                50 ether
            )
        );
        */

        Upgrades.upgradeProxy(
            proxyAddress,
            "DiracPerpetualD8XVault.sol",
            ""
        );
        vm.stopBroadcast();
    }
    function transferOwnership(address vault, address newOwner) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DiracPerpetualVault instance = DiracPerpetualVault(
            payable(vault)
        );
        instance.grantRole(0x00, newOwner);
        instance.grantRole(keccak256("OPERATOR_ROLE"), newOwner);
        //instance.renounceRole(0x00, msg.sender);

        vm.stopBroadcast();
    }

    function initialisation(address vault) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DiracPerpetualD8XVault instance = DiracPerpetualD8XVault(
            payable(vault)
        );
        instance.initializeCycle();
        vm.stopBroadcast();
    }
    function addOperator(address vault, address newOperator) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DiracPerpetualD8XVault instance = DiracPerpetualD8XVault(
            payable(vault)
        );
        instance.grantRole(keccak256("OPERATOR_ROLE"), newOperator);
        vm.stopBroadcast();
    }

    function removeOperator(address vault, address operator) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DiracPerpetualVault instance = DiracPerpetualVault(
            payable(vault)
        );
        instance.revokeRole(keccak256("OPERATOR_ROLE"), operator);

        vm.stopBroadcast();
    }

    function updateMaxUserDeposit(address vault, uint256 newAmount) public {
        uint256 operatorPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(operatorPrivateKey);

        DiracPerpetualVault instance = DiracPerpetualVault(
            payable(vault)
        );
        instance.updateMaxUserDeposit(newAmount);

        vm.stopBroadcast();
    }

    function startTradeCycle(address vault, uint256 duration) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DiracPerpetualVaultUpgrade instance = DiracPerpetualVaultUpgrade(
            payable(vault)
        );
        instance.startTradeCycle(duration);
        vm.stopBroadcast();
    }

    function requestToEndTradeCycle(address vault) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        DiracPerpetualVault instance = DiracPerpetualVault(
            payable(vault)
        );
        instance.requestToEndTradeCycle();
        vm.stopBroadcast();
    }

    function endTradeCycle(address vault) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DiracPerpetualVault instance = DiracPerpetualVault(
            payable(vault)
        );
        instance.endTradeCycle();

        vm.stopBroadcast();
    }

    function deposit(address vault, uint256 amount, address user) public {
        uint256 userPrivateKey = vm.envUint("USER_PRIVATE_KEY");
        if (user == address(0)) {
            user = vm.addr(userPrivateKey);
        }
        vm.startBroadcast(userPrivateKey);

        TransferHelper.safeApprove(address(honey), vault, amount);

        DiracPerpetualD8XVault instance = DiracPerpetualD8XVault(vault);
        instance.deposit(amount,user);
        vm.stopBroadcast();
    }

    function updateMaxDeposit(address vault) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        DiracPerpetualD8XVault instance = DiracPerpetualD8XVault(
            payable(vault)
        );
        instance.updateMaxUserDeposit(50 ether);
        vm.stopBroadcast();
    }

    function withdraw(address vault, uint256 amount) public {
        uint256 userPrivateKey = vm.envUint("USER_PRIVATE_KEY");
        address user = vm.addr(userPrivateKey);
        vm.startBroadcast(userPrivateKey);

        DiracPerpetualVault instance = DiracPerpetualVault(
            payable(vault)
        );
        instance.withdraw(amount, user, user);
        vm.stopBroadcast();
    }

    function postOrder(address vault,  uint32 _flags, uint16 _leverageTDR, int128 _fTradeAmountABDK, bool _isLong) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        DiracPerpetualVaultUpgrade instance = DiracPerpetualVaultUpgrade(
            payable(vault)
        );
        instance.postOrder(_flags,_leverageTDR  ,_fTradeAmountABDK,_isLong);
        vm.stopBroadcast();
    }

    function addPerpetual(address vault, bool isBTC) public{
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        DiracPerpetualVaultUpgrade instance = DiracPerpetualVaultUpgrade(
            payable(vault)
        );
        instance.addPerpetual(isBTC);
        vm.stopBroadcast();
    }

    function approveAmountForPerpetualMgnTkn(address vault, uint256 _amount, bool isBTC) public{
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        DiracPerpetualVaultUpgrade instance = DiracPerpetualVaultUpgrade(
            payable(vault)
        );
        instance.approveAmountForPerpetualMgnTkn(_amount, isBTC);
        vm.stopBroadcast();
    }

    function getMarginAccount(address vault, bool isBTC) public{
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        DiracPerpetualVaultUpgrade instance = DiracPerpetualVaultUpgrade(
            payable(vault)
        );
        IAccountInfo.D18MarginAccount memory account = instance.getMarginAccount(isBTC);
        console.log("lockedInValueQCD18: %s", account.lockedInValueQCD18);
        console.log("cashCCD18:         %s", account.cashCCD18);
        console.log("positionSizeBCD18: %s", account.positionSizeBCD18);
        vm.stopBroadcast();
    }

    function approveCompositeToken(
        address vault,
        uint256 _amount,
        uint24 _iPerpetualId,
        address _spendToken
    ) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        DiracPerpetualD8XVault instance = DiracPerpetualD8XVault(
            payable(vault)
        );
        instance.approveCompositeToken(_amount, _iPerpetualId, _spendToken);
        vm.stopBroadcast();
    }

    function transferMarginCollateralTo(address vault, bool isBTC) public{
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        DiracPerpetualVaultUpgrade instance = DiracPerpetualVaultUpgrade(
            payable(vault)
        );
        instance.transferMarginCollateralTo(isBTC);
        vm.stopBroadcast();
    }

    function transferTokensTo(address vault, bool isBTC) public{
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        DiracPerpetualVaultUpgrade instance = DiracPerpetualVaultUpgrade(
            payable(vault)
        );
        instance.transferMarginCollateralTo(isBTC);
        vm.stopBroadcast();
    }

    function whitelistUsers(
        address vault,
        address[] memory users,
        bool status
    ) public {
        uint256 operatorPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(operatorPrivateKey);

        DiracPerpetualD8XVault instance = DiracPerpetualD8XVault(
            payable(vault)
        );
        instance.whitelistUsers(users, status);

        vm.stopBroadcast();
    }
}
