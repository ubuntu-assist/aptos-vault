# Vault Smart Contract

A secure and flexible token management system built on the Aptos blockchain that enables controlled deposits, allocations, claims, and withdrawals with robust access controls.

## Overview

The Vault smart contract provides a comprehensive system for managing token distributions on the Aptos blockchain. It utilizes resource accounts, signer capabilities, and events to create a secure environment for token management.

## Features

- **Token Deposits**: Admin-controlled deposits into the vault
- **Token Allocations**: Reserve tokens for specific addresses
- **Token Claims**: Allow users to claim their allocated tokens
- **Token Withdrawals**: Admin can withdraw unallocated tokens
- **Balance Tracking**: Monitor total and allocated token amounts
- **Event Logging**: Comprehensive event emission for off-chain monitoring

## Architecture

### Core Components

- **Vault**: Main struct containing the vault's state
- **VaultSignerCapability**: Manages signing capability for the vault's resource account
- **Event Structures**: Track deposits, withdrawals, allocations, and claims

### Functions

#### Administrative Functions

- **init_module**: Sets up the vault and resource account
- **deposit_tokens**: Add tokens to the vault (admin only)
- **allocate_tokens**: Reserve tokens for specific addresses (admin only)
- **withdraw_tokens**: Remove unallocated tokens from the vault (admin only)

#### User Functions

- **claim_tokens**: Allow users to claim their allocated tokens

#### View Functions

- **get_balance**: Check the total balance of the vault
- **get_total_allocated**: View the total amount of allocated tokens
- **get_allocation**: Check allocation for a specific address

## Key Concepts

### Resource Account

The contract uses an Aptos resource account as a "smart contract account" that can hold assets and execute transactions programmatically. The admin can sign transfers on behalf of the vault using the vault signer.

### Signer Capability

The contract implements signer capability to delegate transaction signing authority in a controlled, programmable way.

### Event System

Events are emitted for all significant actions:
- Token deposits
- Token allocations
- Token claims
- Token withdrawals

## Security Features

- **Access Control**: Function-level permissions restrict sensitive operations to admin
- **Balance Verification**: Ensures the contract never transfers more tokens than available
- **Allocation Tracking**: Careful accounting of allocated vs. unallocated tokens

## Usage Examples

### Depositing Tokens (Admin Only)

```move
public entry fun deposit_tokens(admin: &signer, amount: u64) acquires Vault, VaultSignerCapability {
    // Implementation details
}
```

### Allocating Tokens (Admin Only)

```move
public entry fun allocate_tokens(admin: &signer, recipient: address, amount: u64) acquires Vault {
    // Implementation details
}
```

### Claiming Tokens

```move
public entry fun claim_tokens(recipient: &signer) acquires Vault, VaultSignerCapability {
    // Implementation details
}
```

### Withdrawing Tokens (Admin Only)

```move
public entry fun withdraw_tokens(admin: &signer, amount: u64) acquires Vault, VaultSignerCapability {
    // Implementation details
}
```

## Development

This contract provides insight into key Aptos concepts:
- Resource accounts
- Signer capabilities
- Event emission
- Access control