# DiracD8XVault: D8X perpetual pair-trade vaults

> **Historical archive.** Experimental strategy vault from Dirac Finance's 2025 perp-vault period, kept public to document the evolution of our framework. It is **not maintained and not audited**: do not deploy it or deposit into it. Current work: [Dirac Finance on GitHub](https://github.com/Dirac-Finance).

## What it is
Two upgradeable ERC-4626 vaults that run a pair trade on [D8X](https://d8x.exchange) perpetuals:

| Contract | Position |
|---|---|
| `DiracD8XLongGoldVault` | Long Gold / short BTC |
| `DiracD8XLongBTCVault` | Long BTC / short Gold |

- **Trading cycles:** an operator opens trading cycles one at a time (`INIT → STARTED → PENDING_END → ENDED`), and each cycle's trade data is recorded on-chain.
- **Security model:** OpenZeppelin upgradeable proxy, `AccessControl` (admin + operator roles), `Pausable` emergency stop, `ReentrancyGuard`.
- **Earlier iterations:** `DiracPerpetualVault*` and `DiracPerpetualD8XVault*`.

Design notes (French and English) are in [`vault.md`](vault.md).

## Layout
- `src/`: vault contracts, D8X interfaces (`src/interface`), order helpers (`src/library`)
- `script/`: Foundry deployment scripts for both vaults

## Build
```
forge build
```

*Developed May–July 2025.*
