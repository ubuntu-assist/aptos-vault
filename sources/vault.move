module the_vault::vault {
    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin; 
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::account;
    use aptos_std::table::{Self, Table};

    // Error 
    const E_NOT_ADMIN: u64 = 1;
    const E_INSUFFICIENT_BALANCE: u64 = 2;
    const E_NO_ALLOCATION: u64 = 3;

    // Events
    struct AllocationMadeEvent has drop, store { 
        address: address,
        amount: u64
    }
    struct AllocationClaimedEvent has drop, store {
        address: address,
        amount: u64
    }
    struct TokenDepositedEvent has drop, store { amount: u64 }
    struct TokenWithdrawedEvent has drop, store { amount: u64 }
    struct VaultTransferEvent has drop, store {
        vault_address: address,
        from: address,
        to: address
    }

    struct Vault has key {
        admin: address,
        vault_address: address,
        allocations: Table<address, u64>,
        total_allocated: u64,
        total_balance: u64,
        allocation_made_events: EventHandle<AllocationMadeEvent>,
        allocation_claimed_events: EventHandle<AllocationClaimedEvent>,
        token_deposited_events: EventHandle<TokenDepositedEvent>,
        token_withdrawed_events: EventHandle<TokenWithdrawedEvent>,
        transfer_events: EventHandle<VaultTransferEvent>
    }

    struct VaultSignerCapability has key {
        cap: account::SignerCapability  
    }

    fun init_module(resource_account: &signer) {
        let resource_account_address = signer::address_of(resource_account);
        let (vault_signer, vault_signer_cap) = account::create_resource_account(resource_account, b"Vault");  
        let vault_address = signer::address_of(&vault_signer);

        if(!coin::is_account_registered<AptosCoin>(vault_address)) {
            coin::register<AptosCoin>(&vault_signer);
        };

        move_to(&vault_signer, Vault {
            admin: resource_account_address,  
            vault_address,
            allocations: table::new(),
            total_allocated: 0,
            total_balance: 0,
            allocation_made_events: account::new_event_handle<AllocationMadeEvent>(&vault_signer),  
            allocation_claimed_events: account::new_event_handle<AllocationClaimedEvent>(&vault_signer),
            token_deposited_events: account::new_event_handle<TokenDepositedEvent>(&vault_signer),
            token_withdrawed_events: account::new_event_handle<TokenWithdrawedEvent>(&vault_signer),
            transfer_events: account::new_event_handle<VaultTransferEvent>(&vault_signer)
        });

        move_to(resource_account, VaultSignerCapability {
            cap: vault_signer_cap
        });
    }

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

    public entry fun deposit_tokens(admin: &signer, vault_address: address, amount: u64) acquires Vault {
        let vault = borrow_global_mut<Vault>(vault_address);

        coin::transfer<AptosCoin>(admin, vault_address, amount);
        vault.total_balance = vault.total_balance + amount;
        event::emit_event(&mut vault.token_deposited_events, TokenDepositedEvent {
            amount
        });
    }

    public entry fun allocate_tokens(admin: &signer, vault_address: address, to: address, amount: u64) acquires Vault {
        let vault = borrow_global_mut<Vault>(vault_address); 

        assert!(vault.admin == signer::address_of(admin), E_NOT_ADMIN);
        assert!(vault.total_balance >= vault.total_allocated + amount, E_INSUFFICIENT_BALANCE);

        let current_allocation = if (table::contains(&vault.allocations, to)) {
            *table::borrow(&vault.allocations, to)
        } else {
            0
        };  

        table::upsert(&mut vault.allocations, to, current_allocation + amount);
        vault.total_allocated = vault.total_allocated + amount;
        event::emit_event(&mut vault.allocation_made_events, AllocationMadeEvent {
            address: to,
            amount
        });
    }

    public entry fun claim_tokens(account: &signer, vault_address: address) acquires Vault, VaultSignerCapability {  
        let account_address = signer::address_of(account);  
        let vault = borrow_global_mut<Vault>(vault_address); 

        assert!(table::contains(&vault.allocations, account_address), E_NO_ALLOCATION);
        let amount = table::remove(&mut vault.allocations, account_address);

        assert!(vault.total_balance >= amount, E_INSUFFICIENT_BALANCE);
        vault.total_allocated = vault.total_allocated - amount;

        let vault_signer_cap = &borrow_global<VaultSignerCapability>(vault.admin).cap;
        let vault_signer = account::create_signer_with_capability(vault_signer_cap);

        if(!coin::is_account_registered<AptosCoin>(account_address)) {
            coin::register<AptosCoin>(account);
        };

        coin::transfer<AptosCoin>(&vault_signer, account_address, amount);
        vault.total_balance = vault.total_balance - amount;  
        event::emit_event(&mut vault.allocation_claimed_events, AllocationClaimedEvent {
            address: account_address,
            amount
        });
    }

    public entry fun withdraw_tokens(admin: &signer, vault_address: address, amount: u64) acquires Vault, VaultSignerCapability {
        let admin_address = signer::address_of(admin);
        let vault = borrow_global_mut<Vault>(vault_address); 

        assert!(vault.admin == admin_address, E_NOT_ADMIN);
        let available_balance = vault.total_balance - vault.total_allocated; 
        assert!(available_balance >= amount, E_INSUFFICIENT_BALANCE);

        let vault_signer_cap = &borrow_global<VaultSignerCapability>(vault.admin).cap;
        let vault_signer = account::create_signer_with_capability(vault_signer_cap);

        coin::transfer<AptosCoin>(&vault_signer, admin_address, amount);
        vault.total_balance = vault.total_balance - amount; 
        event::emit_event(&mut vault.token_withdrawed_events, TokenWithdrawedEvent {
            amount
        });
    }

    #[view]
    public fun get_balance(vault_address: address): u64 acquires Vault {
        let vault = borrow_global<Vault>(vault_address);
        vault.total_balance
    }

    #[view]
    public fun get_total_allocated(vault_address: address): u64 acquires Vault {
        let vault = borrow_global<Vault>(vault_address);
        vault.total_allocated
    }

    #[view]
    public fun get_allocation(vault_address: address, user_address: address): u64 acquires Vault { 
        let vault = borrow_global<Vault>(vault_address);
        if(table::contains(&vault.allocations, user_address)) {
            *table::borrow(&vault.allocations, user_address)
        } else {
            0
        }
    }

    #[view]
    public fun vault_address(admin_address: address): address acquires VaultSignerCapability {
        let vault_signer_cap = &borrow_global<VaultSignerCapability>(admin_address).cap;
        account::get_signer_capability_address(vault_signer_cap)  
    }
}