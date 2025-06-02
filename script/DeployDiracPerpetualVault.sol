// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../lib/forge-std/src/Script.sol";
import "../src/DiracPerpetualVault.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Options, Upgrades} from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

contract DeployDiracPerpetualVault is Script{
    IERC20 internal honey = IERC20(0xFCBD14DC51f0A4d49d5E53C2E0950e0bC26d0Dce); // HONEY
    address internal kodiakSwapRouter=0xEd158C4b336A6FCb5B193A5570e3a571f6cbe690; // Kodiak V3 SwapRouter
    address internal perpetualVault=0xb6329c7168b255Eca8e5c627b0CCe7A5289C8b7F;
    address internal orderBookAddressBTC=0x901cA2D9a243aeeDB0e91495AfE27f97864F81F7;
    address internal orderBookAddressGold=0x7A34951C84764D0337eA20942CFFe7692F8f6662;
    uint24  internal perpetualIdBTC = 1; // BTC perpetual ID
    uint24  internal perpetualIdGold = 2; // Gold perpetual ID
    function run() external {

    }

    function setUp() external {
        // Set up any necessary state or configurations before running the script
    }
    function deploy() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address proxy = Upgrades.deployTransparentProxy(
            "DiracPerpetualVault.sol",
            msg.sender,
            abi.encodeCall(
                DiracPerpetualVault.initialize,
                (
                    honey,
                    orderBookAddressBTC,
                    orderBookAddressGold,
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

    function whitelistUsers(
        address vault,
        address[] memory users,
        bool status
    ) public {
        uint256 operatorPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(operatorPrivateKey);

        DiracPerpetualVault instance = DiracPerpetualVault(
            payable(vault)
        );
        instance.whitelistUsers(users, status);

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

        DiracPerpetualVault instance = DiracPerpetualVault(
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

    function deposit(address vault, uint256 amount) public {
        uint256 userPrivateKey = vm.envUint("USER_PRIVATE_KEY");
        address user = vm.addr(userPrivateKey);
        vm.startBroadcast(userPrivateKey);

        TransferHelper.safeApprove(address(honey), vault, amount);

        DiracPerpetualVault instance = DiracPerpetualVault(
            payable(vault)
        );
        instance.deposit(amount, user);
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
}
