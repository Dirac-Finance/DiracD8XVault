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




