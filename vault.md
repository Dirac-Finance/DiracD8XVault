# Fonctionnement du Vault

Notre contrat implémente plusieurs fonctionnalités essentielles, notamment :

- Le contrôle d'accès 
- La gestion des pauses d'urgence 
- La protection contre les attaques par réentrance

Il hérite des contrats suivants :

- Initializable 
- ERC4626Upgradeable — le standard pour les vaults compatibles ERC4626 
- AccessControlUpgradeable — pour la gestion des rôles et du contrôle d'accès
- PausableUpgradeable — pour permettre des pauses en cas d'urgence 
- ReentrancyGuardUpgradeable` — pour se protéger contre les attaques de type réentrance



# Mise en ligne

Nous utilisons un contrat proxy upgradable. Toutes les interactions s’effectuent via le proxy, ce qui nous permet de mettre à jour l’implémentation du contrat principal sans changer l’adresse d’interaction.
Cela est particulièrement utile lorsque nous changeons de stratégie : nous déployons alors une nouvelle implémentation tout en conservant les données du proxy.



# Outils

Nous utilisons uniquement Foundry et Solidity pour développer et tester le contrat.



# Description des contrats

Le projet contient :

* Un contrat principal (le vault)
* Un script de déploiement utilisant `forge script`



# Logique de fonctionnement

Nous pouvons ouvrir plusieurs cycles de trading, mais un seul cycle peut être actif à la fois.
Chaque cycle suit les statuts suivants :

- INIT : pour l’initialisation du cycle
- STARTED : pour indiquer le démarrage des opérations de trading
- PENDING_END : pour marquer la phase où la fin du cycle est en attente 
- ENDED : pour signifier la fin effective du cycle

À chaque cycle, les informations de trading sont enregistrées dans une structure de données, ce qui nous permet de suivre l’historique et l’évolution des cycles.

# Informations supplémentaires

Si vous avez besoin d'autres détails ou souhaitez des explications sur une partie spécifique du contrat, n’hésitez pas à me le faire savoir.




# Technical Overview of the Vault Contract
This project implements an upgradeable ERC-4626-compliant vault with strict security and modularity considerations, 
leveraging industry-standard OpenZeppelin upgradeable patterns.

# Security Features
The vault contract integrates:
- Role-based access control (AccessControlUpgradeable) : There is two roles default admin role and operator role
- Emergency circuit breaker (PausableUpgradeable)
- Reentrancy protection (ReentrancyGuardUpgradeable)
- Upgradeable proxy pattern (Initializable via OpenZeppelin Upgrades)

These components ensure secure operation in production and flexible administrative control.

# ERC-4626 Compliance
The core contract inherits from ERC4626Upgradeable, making it fully compatible with the ERC-4626 Tokenized Vault 
Standard for seamless DeFi composability (e.g., aggregators, vault routers).

# Development Stack
Language: Solidity
Framework: Foundry — for testing, scripting, and deployments
Upgradeability: Transparent proxy via OpenZeppelin Upgrades

# Upgrade Pattern
The system is deployed using a proxy-based architecture (ERC1967/Transparent Proxy).
The logic contract can be upgraded without changing the proxy address, enabling iterative improvements and strategy
shifts while maintaining compatibility with integrators.


The meeting schedule is about to end.
Action Items for this meeting:
- Present the first version of the code to the team for review and feedback. @Omar Roustoumi
- Whitelist addresses for the initial investment period. @Caspar Sauter
- Define the funding period for the product launch and liquidity lock. @Omar Roustoumi
- Confirm the number of decimals used for the amount in the contract. @Dibea Koffi BADJO
- Calculate the amount of base currency (Bitcoin or Gold) for the order size
  based on user deposits. @Caspar Sauter
- Confirm the type of order (market or limit) for the deployment made yesterday and ensure it works as intended. @Omar Roustoumi
- Provide a script that has an input for the amount of honey in the world and creates a post order algorithm. @Basile Maire
- Provide access to the contract for review. @Basile Maire
- Add the necessary text to the GitHub repository. @Omar Roustoumi
- Discuss and decide on the duration of the epoch for closing positions
  to optimize yield. @Omar Roustoumi
- Choose the leverage parameters for the integration strategy. @Basile Maire
- Deploy a simple strategy for the integration that can be gradually improved over time. @Omar Roustoumi
- Send GitHub handles to the team. @Caspar Sauter


I submitted the limit order and the PerpetualLimitOrderCreated was emitted.

I checked the Limit order contract for the btc/usd perpetual(which has as address 0x901cA2D9a243aeeDB0e91495AfE27f97864F81F7)
,but in the transactions I do not see my transaction.

I have a few questions regarding the order execution:

Why I'm not seeing the order I post in the limit order contract transaction?
How does the order execution work? Is it automatic or do we need to write a function to execute it manually?

