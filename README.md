# Aptos Vault Optimization Challenge

## 🚀 Smart Contract Efficiency Project

This project represents my work on optimizing the Aptos Vault smart contract by implementing a more direct and efficient parameter approach. I'm focusing on reducing computational overhead while maintaining security.

## The Challenge

### What I'm Starting With

The original contract relies on deriving vault addresses indirectly:

```move
public fun get_vault_address(admin_address: address): address acquires VaultSignerCapability {
    let vault_signer_cap = &borrow_global<VaultSignerCapability>(admin_address).cap;
    account::get_signer_capability_address(vault_signer_cap)
}

public entry fun deposit_tokens(admin: &signer, amount: u64) acquires Vault, VaultSignerCapability {
    let admin_address = signer::address_of(admin);
    let vault_address = get_vault_address(admin_address);
    // Function implementation...
}
```

### My Optimization Approach

I'm redesigning the contract to use vault addresses directly as parameters, eliminating unnecessary derivation operations:

```move
public entry fun deposit_tokens(admin: &signer, vault_address: address, amount: u64) acquires Vault {
    let vault = borrow_global_mut<Vault>(vault_address);
    assert!(vault.admin == signer::address_of(admin), E_NOT_ADMIN);

    coin::transfer<AptosCoin>(admin, vault.vault_address, amount);
    vault.total_balance = vault.total_balance + amount;
    event::emit_event(&mut vault.tokens_deposited_events, TokensDepositedEvent { amount });
}
```

## My Implementation Plan

### Phase 1: Code Refactoring

1. ✓ Remove the redundant `get_vault_address` function
2. ✓ Update all function signatures with direct `vault_address` parameters
3. ✓ Modify internal logic to work with the new parameter structure
4. ✓ Update admin verification to use the stored admin address in the Vault struct

### Phase 2: Contract Deployment

- Set up my development environment with Remix IDE
- Configure Move.toml with necessary dependencies
- Deploy using my Welldone wallet
- Record my contract's deployment address for submission

### Phase 3: Comprehensive Testing

- [ ] Deploy and initialize vault
- [ ] Test token deposits with my account
- [ ] Allocate tokens to test addresses
- [ ] Verify admin-only restrictions
- [ ] Test token claiming functionality
- [ ] Verify withdrawal security

## Personal Extension: Admin Transfer Feature

For the bonus challenge, I'm implementing a secure ownership transfer function:

```move
public entry fun transfer_vault_ownership(admin: &signer, vault_address: address, new_admin: address) acquires Vault {
    let admin_address = signer::address_of(admin);
    let vault = borrow_global_mut<Vault>(vault_address);

    assert!(vault.admin == admin_address, E_NOT_ADMIN);

    vault.admin = new_admin;

    event::emit_event(&mut vault.transfer_events, VaultTransferEvent {
        vault_address,
        from: admin_address,
        to: new_admin
    });
}
```

## Project Submission

My submission will include:

- My optimized contract implementation
- My testnet contract address: 0x...
- My testing results and optimization analysis

---

_This project demonstrates my understanding of Move language optimization techniques and secure smart contract design principles._
