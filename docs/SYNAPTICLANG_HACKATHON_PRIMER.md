# SynapticLang Developer Primer: QuantumShield & Sovereign DPI Edition

> **The Definitive Smart Contract Guide for Hackathon Builders & Auditors on SynapticChain Layer-1.**  
> Target Runtime: **SynapticVM** with Static Dependency Scheduling & 256-Lane Lock-Free Concurrency.  
> Compiler CLI: `synlang` binary (`/usr/local/bin/synlang`).

---

## 1. Architectural Philosophy: Why SynapticLang?

Traditional smart contract environments (such as the Ethereum Virtual Machine) suffer from three structural dilemmas:
1. **Dynamic Reentrancy & Unbounded State Locks:** Contracts can execute arbitrary external callbacks, leading to reentrancy exploits and forcing the runtime to lock the entire global state sequentially.
2. **Dynamic Gas Metering Overhead:** EVM nodes spend substantial CPU cycles dynamically tracking opcode gas and branching during instruction execution.
3. **Sequential Execution Bottlenecks:** Transactions touching disjoint state are still processed in a single sequential thread because the runtime cannot deduce read/write sets prior to execution.

**SynapticLang (`.syn`)** was engineered specifically to eliminate these bottlenecks:
- **Compiler-Driven Static Scheduling:** Every function explicitly declares its state access footprint (`#[reads(...)]`, `#[writes(...)]`). The `synlang` compiler builds a dependency Directed Acyclic Graph (DAG) at compile time and emits a static execution plan (`.plan`).
- **Lock-Free Parallel Lanes:** Transactions with non-overlapping read/write sets are dispatched across up to **256 parallel Rayon execution lanes**, achieving high throughput with zero state contention.
- **Branchless-Preferred VM:** SynapticVM optimizes for branchless deterministic execution, eliminating speculative execution anomalies.
- **Deterministic Post-Quantum & Cross-Rail Binding:** Smart contracts natively integrate with L1 cryptographic precompiles, including **Consensus-Enforced Winternitz Signatures (CE-WOTS+)** and **Universal 5-Rail Isomorphism**.

---

## 2. Language Reference & Syntax

### 2.1 Contract Declaration
A contract is defined with the `contract` keyword. Each `.syn` file contains exactly one contract:

```syn
contract GovPayZMWToken {
    // 1. State Variables
    // 2. Constants
    // 3. Events
    // 4. Public Functions (pub fn)
}
```

**Rules:**
- One contract per `.syn` file.
- No inheritance (`is`, `extends`) or dynamic imports (`import`). All contract logic is modular and self-contained.

---

### 2.2 State Variables & Persistent Storage

Persistent storage variables **must** be declared with the `state` keyword at the very top of the contract body:

```syn
// Scalar state variables
state owner: Address;
state paused: bool;
state total_supply: u128;
state fee_bps: u64;
state name: String;

// Key-Value Map variables
state balances: Map<Address, u128>;
state nullifiers: Map<String, bool>;
state allowances: Map<Address, Map<Address, u128>>;
state swap_dest_chain: Map<String, u32>;
```

#### Supported Data Types

| Type | Size / Description | Common Hackathon Use Case |
|---|---|---|
| `Address` | 32-byte Bech32m address (`syn1...`) | Wallets, contracts, treasury accounts |
| `u128` | 128-bit unsigned integer | Token balances, currency amounts with 18 decimals |
| `u64` | 64-bit unsigned integer | Block heights, sequence counters, IDs |
| `u32` | 32-bit unsigned integer | Chain IDs (1: Solana, 2: XRPL, 3: Bitcoin, 4: Ethereum) |
| `u8` | 8-bit unsigned integer (0–255) | Token decimals (standard: `18`) |
| `u256` | 256-bit unsigned integer | Intermediate calculations to prevent arithmetic overflow |
| `bool` | Boolean (`true` or `false`) | Paused flags, nullifier claimed status |
| `String` | UTF-8 encoded string | Identity metadata URIs, payment entity names, hashlocks |
| `Map<K, V>` | Hash table lookup | Balances, allowances, identity registries |

> ⚠️ **CRITICAL RULE — Map Defaults:**  
> Accessing an uninitialized key in a `Map<K, V>` does **not** revert or throw a "key not found" error. It returns the type's default value (`0` for integers, `false` for booleans, `Address::zero()` for addresses, `""` for strings).

---

### 2.3 The Mandatory `self.` Prefix Rule

Every read or write to a state variable **MUST** be explicitly prefixed with `self.`:

```syn
// ❌ FATAL BUG — Silently creates a local variable! State is lost upon return!
pub fn init(initial_supply: u128) {
    total_supply = initial_supply;         // Local var, evaporates on return!
    balances[msg.sender] = initial_supply; // Local var, never written to disk!
}

// ✅ CORRECT — Persists directly to Layer-1 state storage
pub fn init(initial_supply: u128) {
    self.total_supply = initial_supply;
    self.balances[msg.sender] = initial_supply;
}
```

> 💡 **Diagnostic Indicator:** If your deployment's `init()` or `setup()` call succeeds but uses only `~20,000` gas instead of `> 100,000` gas, and all subsequent getter queries return zero, you forgot the `self.` prefix!

---

### 2.4 Functions: Public vs. Private

```syn
// Public entry point (callable via transaction or RPC)
pub fn transfer(to: Address, amount: u128) -> bool {
    // ...
    return true;
}

// Public void entry point
pub fn pause() {
    require!(msg.sender == self.owner, "Not owner");
    self.paused = true;
}
```

> ⚠️ **CRITICAL COMPILER BUG — Private Helper Functions:**  
> In the compiler release, calling a private function (`fn helper()`) from inside a `pub fn` causes register corruption and returns `Unit`.  
> **RULE:** **Inline ALL logic directly into your `pub fn` functions.** Do not call internal helper functions from public entry points.

---

### 2.5 Access Annotations: `#[reads]` & `#[writes]`

Before every public function, you **must** declare all state variables accessed by that function. The SynapticChain compiler uses these annotations to construct the static dependency matrix:

```syn
// Multi-slot access: declare each slot
#[reads(paused, balances, allowances)]
#[writes(balances, allowances)]
pub fn transfer_from(from: Address, to: Address, amount: u128) -> bool {
    require!(self.paused == false, "Paused");
    let allowed: u128 = self.allowances[from][msg.sender];
    require!(allowed >= amount, "Insufficient allowance");
    require!(self.balances[from] >= amount, "Insufficient balance");
    
    self.allowances[from][msg.sender] = allowed - amount;
    self.balances[from] = self.balances[from] - amount;
    self.balances[to] = self.balances[to] + amount;
    
    emit Transfer(from, to, amount);
    return true;
}
```

#### Safe Annotation Formatting Rule:
While modern `synlang` compiler versions accept comma-separated slots inside annotations (e.g. `#[reads(a, b, c)]`), older releases expect separate lines (e.g. `#[reads(a)] #[reads(b)]`). When writing new contracts, ensure every state slot read or written is explicitly covered. If you omit a written slot from `#[writes(...)]`, the VM static scheduler will reject the transaction at runtime.

---

### 2.6 Events: Emitting Telemetry

Events provide off-chain transparency for block explorers (Canopy Explorer), indexing nodes, and client applications:

```syn
// 1. Event Declaration (at contract top)
event Transfer(from: Address, to: Address, amount: u128);
event Routed(payer: Address, payee: Address, entity: String, amount: u128, fee: u128, seq: u64);
event IdentityMinted(to: Address, token_id: u64, nullifier: String);

// 2. Emitting Events (inside pub fn)
emit Transfer(msg.sender, to, amount);
emit Routed(msg.sender, payee, entity, amount, fee, seq);
```

---

### 2.7 Built-in Primitives & Global Context

| Expression | Type | Description |
|---|---|---|
| `msg.sender` | `Address` | Caller address (transaction signer or calling contract) |
| `msg.value` | `u128` | Native SYN transferred with this transaction (in units of 0^{-18}$ SYN) |
| `block_height()` | `u64` | Monotonically increasing canonical L1 block height |
| `Address::zero()` | `Address` | The null address (`syn1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq...`) |
| `transfer(to, amount)` | void | Sends native SYN from the contract to `to` |
| `call_contract(addr, "func", args...)` | any | Cross-contract execution call |

> ⚠️ **NO `block.timestamp`:**  
> SynapticChain uses deterministic, verifiable block heights instead of wall-clock timestamps (`block.timestamp` is rejected at compile time). For time locks, use block count heuristics (African testnet: ~2 blocks per second; 1 hour = 7,200 blocks).

---

### 2.8 Invariants & Validation: `require!`

```syn
require!(condition, "Static error string literal");
```

*Rules:*
- If `condition` is `false`, execution immediately halts, all state modifications are reverted, and unused gas is refunded.
- The error message **must** be a string literal. Do not pass dynamic variables or integers.
- **Explicit Booleans:** Do **not** use `!self.paused`. The `!` unary operator on storage booleans can fail in certain VM versions. Always use:
  ```syn
  require!(self.paused == false, "Contract is paused");
  ```

---

## 3. High-Throughput & Safe Math Patterns

### 3.1 Overflow-Safe Precision with `u256` Intermediates

When multiplying large numbers with 18 decimals (`u128`), intermediate products will overflow ^{128} - 1$. Cast intermediate products to `u256` before dividing:

```syn
// Calculate statutory fee: fee = (amount * fee_bps) / 10000
let amount_256: u256 = amount as u256;
let fee_bps_256: u256 = (self.fee_bps as u128) as u256;
let denom_256: u256 = 10000 as u256;

let fee_intermediate: u256 = (amount_256 * fee_bps_256) / denom_256;
let fee: u128 = fee_intermediate as u128;
let proceeds: u128 = amount - fee;
```

### 3.2 Division by Literal Constants
Avoid dividing directly by raw numeric literals like `x / 10000`. Either:
1. Define a contract constant: `const FEE_DENOMINATOR: u64 = 10000;`
2. Or store the denominator in a state variable initialized during `init()`.

---

## 4. Production Sovereign DPI Contract Patterns

The `quantumshield-sovereign-dpi` repository contains 5 production-hardened contract templates. Hackathon participants should use these reference architectures:

### 4.1 Pattern 1: National Currency Token (`GovPayZMWToken.syn`)
Demonstrates the **SRC-20 Token Standard** for sovereign central bank digital currencies.
- Fixed or governed supply managed by the Central Bank of Zambia reserve vault (`syn1r5vkuqaxss46uruj6c5k5wrnzxg04htpuylynr`).
- Full allowance delegator pattern (`approve`, `allowance`, `transfer_from`) enabling one-click statutory tax routing.

```syn
contract Token {
    state name: String;
    state symbol: String;
    state decimals: u8;
    state total_supply: u128;
    state balances: Map<Address, u128>;
    state allowances: Map<Address, Map<Address, u128>>;
    state owner: Address;

    event Transfer(from: Address, to: Address, amount: u128);
    event Approval(owner: Address, spender: Address, amount: u128);

    #[writes(name, symbol, decimals, total_supply, balances, owner)]
    pub fn init(token_name: String, token_symbol: String, token_decimals: u8, initial_supply: u128) {
        self.name = token_name;
        self.symbol = token_symbol;
        self.decimals = token_decimals;
        self.total_supply = initial_supply;
        self.owner = msg.sender;
        self.balances[msg.sender] = initial_supply;
        emit Transfer(Address::zero(), msg.sender, initial_supply);
    }

    #[reads(balances, allowances)]
    #[writes(balances, allowances)]
    pub fn transfer_from(from: Address, to: Address, amount: u128) -> bool {
        let sender: Address = msg.sender;
        let allowed: u128 = self.allowances[from][sender];
        require!(allowed >= amount, "Insufficient allowance");
        require!(self.balances[from] >= amount, "Insufficient balance");
        self.allowances[from][sender] = allowed - amount;
        self.balances[from] = self.balances[from] - amount;
        self.balances[to] = self.balances[to] + amount;
        emit Transfer(from, to, amount);
        return true;
    }
}
```

---

### 4.2 Pattern 2: Statutory Revenue Splitter (`ZraSplitRouter.syn`)
Demonstrates **Non-Custodial Atomic Revenue Collection**.
- In a single atomic transaction, pulls pre-approved sovereign currency from the citizen/merchant.
- Dispatches 99.5% proceeds to the commercial payee and 0.50% statutory deduction directly into the Zambia Revenue Authority Single Treasury Account (TSA: `syn1t9hp790tpp450jh0sd8lyd3znqccycal4m2z0u`).
- Zero escrow custody: funds never pool in the router.

```syn
contract ZraSplitRouter {
    state zmw_token: Address;
    state treasury: Address;   // ZRA Single Treasury Account
    state fee_bps: u64;        // 50 = 0.50%
    state payment_count: u64;

    const FEE_DENOMINATOR: u64 = 10000;

    event Routed(payer: Address, payee: Address, entity: String, amount: u128, fee: u128, seq: u64);

    #[reads(zmw_token, treasury, fee_bps, payment_count)]
    #[writes(payment_count)]
    pub fn pay(amount: u128, payee: Address, entity: String) {
        require!(amount > 0, "Zero amount");
        let fee: u128 = (amount * (self.fee_bps as u128)) / (FEE_DENOMINATOR as u128);
        let proceeds: u128 = amount - fee;
        let seq: u64 = self.payment_count + 1;
        
        // Atomic dual transfers via cross-contract calls
        call_contract(self.zmw_token, "transfer_from", msg.sender, payee, proceeds);
        call_contract(self.zmw_token, "transfer_from", msg.sender, self.treasury, fee);
        
        self.payment_count = seq;
        emit Routed(msg.sender, payee, entity, amount, fee, seq);
    }
}
```

---

### 4.3 Pattern 3: Soulbound Post-Quantum Identity (`SynIdentityNFT.syn`)
Demonstrates **Biometric Anti-Ghost Credentialing with Nullifiers**.
- Issues non-transferable Soulbound Tokens (SBTs) representing verified human citizens or sovereign entities.
- Enforces an unforgeable cryptographic **Nullifier Registry**: `nullifier = SHA3-256(IMEI + biometric + salt)`.
- Prevents double-claiming while preserving identity privacy.

```syn
contract SynIdentityNFT {
    state total_supply: u64;
    state address_to_token: Map<Address, u64>;
    state nullifiers: Map<String, bool>;
    state minted: Map<u64, bool>;

    #[reads(total_supply, address_to_token, nullifiers, minted)]
    #[writes(total_supply, address_to_token, nullifiers, minted)]
    pub fn mint(token_id: u64, uri: String, nullifier: String) {
        require!(self.minted[token_id] == false, "Token already minted");
        require!(self.nullifiers[nullifier] == false, "Identity nullifier already used");
        require!(self.address_to_token[msg.sender] == 0, "Address already has identity");
        require!(nullifier.len() > 0, "Nullifier required");

        self.minted[token_id] = true;
        self.nullifiers[nullifier] = true;
        self.address_to_token[msg.sender] = token_id;
        self.total_supply = self.total_supply + 1;
    }
}
```

---

### 4.4 Pattern 4: Universal 5-Rail Cross-Rail Router (`AtomicRouter.syn`)
Demonstrates **Universal Cross-Chain Settlement without Bridge Custody**.
- Locks native SYN or sovereign assets with a cryptographic hashlock and block-height deadline.
- Enables atomic settlement across SynapticChain, Solana, XRPL, Bitcoin, and Ethereum.
- Features automatic protocol burn of native SYN gas on successful claim.

---

### 4.5 Pattern 5: ISO 20022 Pacs.008 Settlement (`ISO20022Payment.syn`)
Demonstrates **Institutional Financial Interoperability**.
- Native parsing and logging of pacs.008 commercial bank payment clearing messages.
- Carries EndToEndId, InstructionId, DebtorAgent BIC, and CreditorAgent BIC on-chain for real-time central bank auditability.

---

## 5. The 10 Inviolable Rules of SynapticLang

Before testing or submitting smart contracts for the hackathon, ensure you have not violated any of these rules:

| # | Inviolable Rule | Why It Breaks | The Clean Solution |
|---|---|---|---|
| **1** | Always prefix state with `self.` | Without `self.`, writes become ephemeral local variables; state is lost upon function return. | `self.balance = balance;` |
| **2** | No private helper functions | Calling private `fn` from `pub fn` corrupts VM registers and returns `Unit`. | Inline all logic directly into `pub fn`. |
| **3** | Annotate every accessed slot | Unannotated writes cause runtime permission aborts in the static scheduler. | Use `#[reads(X)]` and `#[writes(Y)]`. |
| **4** | Explicit boolean checks | The `!` operator on storage booleans can misbehave in VM verification. | Use `require!(self.paused == false, "Paused");`. |
| **5** | No `block.timestamp` | Wall-clock time is non-deterministic; compiler rejects `block.timestamp`. | Use `block_height()` with fixed block rate. |
| **6** | No constructors | SynapticLang contracts do not have constructors. | Declare `pub fn init(...)` and invoke immediately post-deploy. |
| **7** | Intermediate `u256` math | Multiplying two 0^{18}$ `u128` values overflows 128-bit integers. | Cast to `u256`: `(a as u256 * b as u256) / c as u256`. |
| **8** | No division by literals | Raw literal divisors can panic during constant folding. | Store divisor in constant or state variable. |
| **9** | No tuple returns | Public functions cannot return tuples `(u64, u128)`. | Create multiple dedicated getter functions. |
| **10** | String literal error messages | `require!` accepts only string literals for error descriptions. | `require!(x > 0, "Must be positive");` |

---

## 6. Pre-Flight Compilation Checklist

- [ ] Every persistent variable is declared with `state` at the top of the contract.
- [ ] Every state read and write uses the `self.` prefix.
- [ ] All `pub fn` entry points have matching `#[reads(...)]` and `#[writes(...)]` attributes.
- [ ] No private helper functions are invoked from public functions.
- [ ] All token amounts use `u128` with 18 decimals; timestamps and heights use `u64`.
- [ ] `require!` checks use `== false` or `== true` instead of `!`.
- [ ] Math multiplications with large numbers use `as u256` intermediates.
- [ ] An `init()` or `setup()` function is defined to initialize owner, total supply, or metadata.
- [ ] Compiled with `/usr/local/bin/synlang compile <file.syn> <file.plan>`.
- [ ] Deployment plan verified with `gas_used > 100,000` on first call.
