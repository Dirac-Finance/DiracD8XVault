// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import "forge-std/Script.sol";
import "../src/DiracPerpetualVault.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {DiracPerpetualVault} from "../src/DiracPerpetualVault.sol";
import {DiracPerpetualVaultUpgrade} from "../src/DiracPerpetualVaultUpgrade.sol";
import "../src/interface/IAccountInfo.sol";
import  "forge-std/console.sol";
import {DiracPerpetualD8XVault2} from "../src/DiracPerpetualD8XVault2.sol";
import {DiracD8XLongGoldVault} from "../src/DiracD8XLongGoldVault.sol";
contract DeployDiracD8XLongGoldVault is Script{
    IERC20 internal honey = IERC20(0xFCBD14DC51f0A4d49d5E53C2E0950e0bC26d0Dce); // HONEY
    address internal kodiakSwapRouter=0xEd158C4b336A6FCb5B193A5570e3a571f6cbe690; // Kodiak V3 SwapRouter
    address internal perpetualVault=0xb6329c7168b255Eca8e5c627b0CCe7A5289C8b7F;
    uint24  internal perpetualIdBTC = 100003; // BTC perpetual ID
    uint24  internal perpetualIdGold = 100013; // Gold perpetual ID

    function run() external {

        // deployment

        //deploy();
        //address  vault =0xC144F12f4D65f66710498dC4c5764bEc1F63Bd4A;
        address  vault = 0xe996c9c6d80c1D50E0A2B0F30F8CFD2551Bd0508;
        //startTradeCycle(vault, 84000);
        //approveCompositeToken(vault, 17 ether, perpetualIdBTC, address(honey));
        //approveCompositeToken(vault, 0 ether, perpetualIdGold, address(honey));
        //postOrder(vault,  0x40000000, 100,   81196468436795840,  true );

        //postOrder(vault,  0x40000000, 100,    2628594066894127,  true );

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

        address[] memory whitelist = new address[](1);
        whitelist[0] = 0x97dCbD0112D01bE3dd83333F5412Eb668753fe3c;
        //whitelist[1] = 0xdef43CF2Dd024abc5447C1Dcdc2fE3FE58547b84;

        whitelistUsers(vault, whitelist, true);

        //whitelistUsers(vault, whitelist, true);
        // 4 Start trade cycle finish
        //startTradeCycle(vault, 84000); // 84000 seconds = 1 day
        // 1. Initialization of the vault finish
        //initialisation(vault);
        // 3. make deposit finish

       //deposit(vault, 1 ether, address(0x621CBbe73636D0BEa60ceBF74B332c7b7eD0A059)); // 10 HONEY//// 6 open orders

        // 7. get account informations

        // 8. Close trade


        //updateMaxDeposit(vault);
        //addOperator(vault, 0x0A5980A4923388b9Bd4108b27e5bD65998deb6C7);
        //transferOwnership(vault, 0x0A5980A4923388b9Bd4108b27e5bD65998deb6C7);
        //requestToEndTradeCycle(vault);
        //endTradeCycle(vault);

    }

    function setUp() external {
        // Set up any necessary state or configurations before running the script
    }
    function deploy() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address proxy = Upgrades.deployTransparentProxy(
            "DiracD8XLongGoldVault.sol",
            msg.sender,
            abi.encodeCall(
                DiracPerpetualD8XVault2.initialize,
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
        DiracPerpetualD8XVault2 instance = DiracPerpetualD8XVault2(
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
            "DiracD8XLongGoldVault.sol",
            ""
        );
        vm.stopBroadcast();
    }
    function transferOwnership(address vault, address newOwner) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DiracD8XLongGoldVault instance = DiracD8XLongGoldVault(
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

        DiracD8XLongGoldVault instance = DiracD8XLongGoldVault(
            payable(vault)
        );
        instance.initializeCycle();
        vm.stopBroadcast();
    }
    function addOperator(address vault, address newOperator) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DiracD8XLongGoldVault instance = DiracD8XLongGoldVault(
            payable(vault)
        );
        instance.grantRole(keccak256("OPERATOR_ROLE"), newOperator);
        vm.stopBroadcast();
    }

    function removeOperator(address vault, address operator) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DiracD8XLongGoldVault instance = DiracD8XLongGoldVault(
            payable(vault)
        );
        instance.revokeRole(keccak256("OPERATOR_ROLE"), operator);

        vm.stopBroadcast();
    }

    function updateMaxUserDeposit(address vault, uint256 newAmount) public {
        uint256 operatorPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(operatorPrivateKey);

        DiracD8XLongGoldVault instance = DiracD8XLongGoldVault(
            payable(vault)
        );
        instance.updateMaxUserDeposit(newAmount);

        vm.stopBroadcast();
    }

    function startTradeCycle(address vault, uint256 duration) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DiracD8XLongGoldVault instance = DiracD8XLongGoldVault(
            payable(vault)
        );
        instance.startTradeCycle(duration);
        vm.stopBroadcast();
    }

    function requestToEndTradeCycle(address vault) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        DiracD8XLongGoldVault instance = DiracD8XLongGoldVault(
            payable(vault)
        );
        instance.requestToEndTradeCycle();
        vm.stopBroadcast();
    }

    function endTradeCycle(address vault) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DiracD8XLongGoldVault instance = DiracD8XLongGoldVault(
            payable(vault)
        );
        instance.endTradeCycle();

        vm.stopBroadcast();
    }

    function deposit(address vault, uint256 amount, address user) public {
        uint256 userPrivateKey = vm.envUint("USER_PRIVATE_KEY");

        vm.startBroadcast(userPrivateKey);

        TransferHelper.safeApprove(address(honey), vault, amount);

        DiracD8XLongGoldVault instance = DiracD8XLongGoldVault(vault);
        instance.deposit(amount,user);
        vm.stopBroadcast();
    }

    function updateMaxDeposit(address vault) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        DiracD8XLongGoldVault instance = DiracD8XLongGoldVault(
            payable(vault)
        );
        instance.updateMaxUserDeposit(50 ether);
        vm.stopBroadcast();
    }

    function withdraw(address vault, uint256 amount) public {
        uint256 userPrivateKey = vm.envUint("USER_PRIVATE_KEY");
        address user = vm.addr(userPrivateKey);
        vm.startBroadcast(userPrivateKey);

        DiracD8XLongGoldVault instance = DiracD8XLongGoldVault(
            payable(vault)
        );
        instance.withdraw(amount, user, user);
        vm.stopBroadcast();
    }

    function postOrder(address vault,  uint32 _flags, uint16 _leverageTDR, int128 _fTradeAmountABDK, bool _isLong) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        DiracD8XLongGoldVault instance = DiracD8XLongGoldVault(
            payable(vault)
        );
        instance.postOrder(_flags, _leverageTDR, _fTradeAmountABDK, _isLong);
        vm.stopBroadcast();
    }

    function addPerpetual(address vault, bool isBTC) public{
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        DiracD8XLongGoldVault instance = DiracD8XLongGoldVault(
            payable(vault)
        );
        instance.addPerpetual(isBTC);
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
        DiracD8XLongGoldVault instance = DiracD8XLongGoldVault(
             payable(vault)
         );
         instance.approveCompositeToken(_amount, _iPerpetualId, _spendToken);
         vm.stopBroadcast();
     }




    function whitelistUsers(
        address vault,
        address[] memory users,
        bool status
    ) public {
        uint256 operatorPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(operatorPrivateKey);

        DiracD8XLongGoldVault instance = DiracD8XLongGoldVault(
            payable(vault)
        );
        instance.whitelistUsers(users, status);

        vm.stopBroadcast();
    }


    function allowance(address vault, uint24 perpetual) public {
        uint256 operatorPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(operatorPrivateKey);

        DiracD8XLongGoldVault instance = DiracD8XLongGoldVault(
            payable(vault)
        );
        address compositToken = instance.mgnTknAddrOfPool(perpetual);
        console.logAddress(compositToken);
        console.log("Allowance", honey.allowance(vault, compositToken));
        vm.stopBroadcast();
    }
}
