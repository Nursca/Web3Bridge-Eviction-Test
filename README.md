# EvictionVault

## Overview

A refactored EvictionVault smart contract from a vulnerable architecture into a secured architeture.

### Core Structure

The refactored contract is organized into the following components:

```
src/
├── Interfaces/
│   ├── IVault.sol           # Vault deposit/withdrawal interface
│   ├── IMultisig.sol        # Multisig transaction interface
│   └── IAirdrop.sol         # Merkle airdrop interface
├── modules/
│   ├── MultisigCore.sol     # Multi-signature wallet implementation
│   ├── PauseModule.sol      # Access-controlled pause functionality
│   ├── MerkleAirdrop.sol    # Merkle tree-based airdrop logic
│   ├── TimelockExecutor.sol # Generic timelock functionality
│   └── SignatureUtils.sol   # Signature verification utilities
└── EvictionVault.sol        # Main contract composing all modules
```

## Contract Vulnerabilities

### 1. **setMerkleRoot Callable by Anyone**
**Vulnerability**: The original function had no access control, allowing anyone to change the merkle root.

- Now requires approval from all owners (via multisig threshold)
- Enforced with 1-hour timelock before execution

### 2. **emergencyWithdrawAll Public Drain**
**Vulnerability**: The function was public with no access control, allowing anyone to drain the vault.

- Restricted to multisig-approved transactions
- Requires multisig threshold (2 of 3 owners)
- Protected by 1-hour timelock execution delay

### 3. **pause/unpause Single Owner Control**
**Vulnerability**: Only a single owner could pause/unpause, creating a centralization risk.

- Both pause and unpause now require multisig approval

### 4. **receive() Uses tx.origin**
**Vulnerability**: Using `tx.origin` instead of `msg.sender`.

- Now uses `msg.sender` instead of `tx.origin`

### 5. **withdraw & claim Uses .transfer**
**Vulnerability**: Using `.transfer()` causing failures with smart contract recipients.
 
- Uses low-level `.call{}` for safe transfers

### 6. **Timelock Execution Proper Implementation**
**Status**: The original implementation was correct but improved with modular design.

## Testing

### Test Suite

All critical vulnerabilities have been tested with 8 comprehensive tests.

### Running Tests

```bash
forge test
```

### Building Contracts

```bash
forge build
```

## Foundry Documentation

For more information, visit: https://book.getfoundry.sh/

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
