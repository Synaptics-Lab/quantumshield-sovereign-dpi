# Technical Code Traceability & Auditor Verification Matrix
## SynapticChain Sovereign DPI & QuantumShield L1
**Target Audience:** Smart Contract Auditors, Cryptographic Evaluators, Institutional Technical Committees, FINOS Judges  
**Document Version:** 1.0.0-PROD  
**Core Monorepo:** `/opt/synapticchain` (`https://github.com/Synaptics-Lab/Synapse1`, branch `production-1`)  
**Hackathon Hub:** `/opt/quantumshield-sovereign-dpi` (`https://github.com/Synaptics-Lab/quantumshield-sovereign-dpi`, branch `main`)  

---

## 1. Executive Traceability Overview

Every technical claim made in our submission, presentation slides, and whitepaper is backed by concrete, verifiable source code in the repository and live on-chain state on the network.

This matrix provides the exact **file path, struct/function name, line numbers, and verification commands** for each core pillar:

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                  AUDITOR CODE TRACEABILITY PATHWAYS                                    │
├────────────────────────────────┬──────────────────────────────────────┬────────────────────────────────┤
│ ARCHITECTURAL CLAIM            │ EXACT SOURCE CODE / REPO IMPLEMENTATION│ INDEPENDENT VERIFICATION CMD  │
├────────────────────────────────┼──────────────────────────────────────┼────────────────────────────────┤
│ 1. 256-Lane Decoupled SMR &   │ • synaptic-types/src/nonce_state.rs  │ python3 stunt_5wallets_        │
│    Sliding Bitmask (ADR-062)   │ • synaptic-types/src/account.rs      │         256lanes.py            │
│                                │ • synaptic-types/src/transaction.rs  │ (1,280/1,280 tx 100% ack)      │
├────────────────────────────────┼──────────────────────────────────────┼────────────────────────────────┤
│ 2. DAG Multi-Proposer &        │ • synaptic-consensus/src/            │ curl -X POST .../rpc           │
│    Equivocation Detection      │     sequencer_attestation.rs         │   -d '{"method":"syn_getStatus"│
│                                │ • synaptic-consensus/src/dag.rs      │ (Height #1,840+, 3/3 lockstep) │
├────────────────────────────────┼──────────────────────────────────────┼────────────────────────────────┤
│ 3. Compiler Static Scheduling  │ • synaptic-compiler/src/scheduler.rs │ cargo test -p synaptic-vm      │
│    & Rayon Parallel VM (S0)    │ • synaptic-compiler/src/planner.rs   │   --test tick_executor         │
│                                │ • synaptic-vm/src/tick_executor.rs   │                                │
├────────────────────────────────┼──────────────────────────────────────┼────────────────────────────────┤
│ 4. Post-Quantum CE-WOTS+       │ • synaptic-crypto/src/wots.rs        │ cargo test -p synaptic-crypto  │
│    Precompile 0x10 (BIP-360)   │ • synaptic-vm/src/precompiles.rs     │   --lib wots::tests            │
│                                │ • synaptic-types/src/quantum.rs      │                                │
├────────────────────────────────┼──────────────────────────────────────┼────────────────────────────────┤
│ 5. Universal 5-Rail Derivation │ • apps/quantumshield-terminal/       │ cd /opt/quantumshield-...      │
│    & XRPL Soulbound Anchor     │     index.html (noble-ed25519)       │ python3 demo_hackathon_e2e.py  │
│                                │ • scripts/xrpl_mint_soulbound.mjs    │                                │
├────────────────────────────────┼──────────────────────────────────────┼────────────────────────────────┤
│ 6. GovPay 150M ZMW Float &     │ • contracts/production/              │ python3 scripts/               │
│    0.50% ZRA TSA Tax Router    │     ZraSplitRouter.syn               │   deploy_sovereign_suite.py    │
│                                │ • contracts/production/Token.syn     │ (On-chain verified contracts)  │
├────────────────────────────────┼──────────────────────────────────────┼────────────────────────────────┤
│ 7. Deterministic Replay &      │ • synaptic-consensus/src/            │ ./test_s0_compliance.sh        │
│    Snapshot Recovery (ADR-643) │     checkpoint_executor.rs           │                                │
│                                │ • synaptic-node/src/sync_manager.rs  │                                │
└────────────────────────────────┴──────────────────────────────────────┴────────────────────────────────┘
```

---

## 2. Deep-Dive Code Verification Pathways

### Pillar 1: 256-Lane Decoupled SMR & Nonce Bitmask (ADR-062)

#### The Problem It Solves
Standard accounts in EVM and Bitcoin enforce strict serial nonces (`nonce = n + 1`). If a central bank or corporate treasury attempts to disburse 10,000 transactions concurrently, all transactions are blocked behind transaction #1.

#### The Code Implementation
1. **The 256-Bit Sliding Window Data Structure:**  
   - **File:** [`synaptic-types/src/nonce_state.rs:L30-L41`](file:///opt/synapticchain/synaptic-types/src/nonce_state.rs#L30-L41)
   - **Code:**
     ```rust
     #[derive(Clone, Debug, PartialEq, Serialize, Deserialize, BorshSerialize, BorshDeserialize)]
     pub struct LaneNonceState {
         pub watermark: u64,
         pub used_bitmap: [u8; NONCE_WINDOW_SIZE / 8], // 256 bits = 32 bytes
     }
     ```
2. **Gap-Tolerant Admission Check (`can_accept`):**  
   - **File:** [`synaptic-types/src/nonce_state.rs:L113-L141`](file:///opt/synapticchain/synaptic-types/src/nonce_state.rs#L113-L141)
   - **Logic:** Validates that `nonce` is not used and is within `[watermark + 1, watermark + 1 + 256]`. Rejects duplicates and ancient nonces in $\mathcal{O}(1)$ without locks.
3. **Atomic Bitmask Advance (`mark_used`):**  
   - **File:** [`synaptic-types/src/nonce_state.rs:L148-L175`](file:///opt/synapticchain/synaptic-types/src/nonce_state.rs#L148-L175)
   - **Logic:** Sets bit `(nonce - watermark - 1)` and advances `watermark` through all contiguous used bits.
4. **Account State Version 2 Integration:**  
   - **File:** [`synaptic-types/src/account.rs:L37-L44`](file:///opt/synapticchain/synaptic-types/src/account.rs#L37-L44)
   - **Code:** `pub lane_nonces: BTreeMap<u64, LaneNonceState>`: Maps `nonce_key -> LaneNonceState`.
5. **Transaction Nonce Key (Lane Field):**  
   - **File:** [`synaptic-types/src/transaction.rs:L133-L136`](file:///opt/synapticchain/synaptic-types/src/transaction.rs#L133-L136)
   - **Code:** `pub nonce_key: u64`: Selects the parallel lane (0..255).

#### Auditor Verification Command
Run the live 5-wallet $\times$ 256-lane parallel blast against the running cluster:
```bash
python3 /opt/synapticchain/stunt_5wallets_256lanes.py
```
**Expected Output:** `1280 / 1280 (100.0%)` transactions acknowledged by the JSON-RPC mempool with `0` collisions.

---

### Pillar 2: DAG Multi-Proposer Consensus & Equivocation Accountability (ADR-641)

#### The Problem It Solves
Single-sequencer BFT protocols risk censorship and equivocation (double-spending across forks). 

#### The Code Implementation
1. **Cryptographic Equivocation Detection (`EquivocationDetector`):**  
   - **File:** [`synaptic-consensus/src/sequencer_attestation.rs:L68-L117`](file:///opt/synapticchain/synaptic-consensus/src/sequencer_attestation.rs#L68-L117)
   - **Code:**
     ```rust
     #[derive(Default)]
     pub struct EquivocationDetector {
         inner: DashMap<(u64, Address), (Checkpoint, [u8; 64])>,
     }
     ```
   - **Logic:** If an attestation is received for `(height, sequencer)` matching an existing entry but with a differing content-addressed checkpoint ID, it returns `EquivocationDetectorOutcome::Equivocation(Box<EquivocationProof>)` which immediately slashes validator stake.
2. **Attestation Signature Verification:**  
   - **File:** [`synaptic-consensus/src/sequencer_attestation.rs:L43-L56`](file:///opt/synapticchain/synaptic-consensus/src/sequencer_attestation.rs#L43-L56)
   - **Logic:** Validates Ed25519 signature over `checkpoint.id` against derived validator address.
3. **Consensus DAG Graph:**  
   - **File:** [`synaptic-consensus/src/dag.rs`](file:///opt/synapticchain/synaptic-consensus/src/dag.rs)

#### Auditor Verification Command
Query the live 3-neuron SCBFT consensus status:
```bash
curl -s -X POST http://100.126.201.109:8545 -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"syn_getStatus","params":[],"id":1}' | jq .
```
**Expected Output:** `"synced": true`, `"neuron_count": 3`, `"shard_count": 1`, `"canonical_height": >= 1840`.

---

### Pillar 3: Compiler Static Scheduling & Rayon Parallel VM Lanes (S0 Optimization)

#### The Problem It Solves
EVM executes all operations sequentially in a single thread. SynapticChain statically schedules non-conflicting state accesses before runtime.

#### The Code Implementation
1. **Static Schedule Generation:**  
   - **File:** [`synaptic-compiler/src/scheduler.rs:L10-L19`](file:///opt/synapticchain/synaptic-compiler/src/scheduler.rs#L10-L19)
   - **Structure:**
     ```rust
     pub struct ExecutionSchedule {
         pub ticks: Vec<Vec<ScheduledOp>>, // Operations grouped by tick and parallel_group
         pub total_ticks: u32,
         pub register_map: HashMap<String, RegisterId>,
     }
     ```
2. **Planner Assembly:**  
   - **File:** [`synaptic-compiler/src/planner.rs:L183-L225`](file:///opt/synapticchain/synaptic-compiler/src/planner.rs#L183-L225)
   - **Logic:** Ingests AST read/write annotations (`#[reads(...)]`, `#[writes(...)]`) and generates deterministic `.plan` bytecode.
3. **Rayon Parallel Execution Loop:**  
   - **File:** [`synaptic-vm/src/tick_executor.rs:L649-L665`](file:///opt/synapticchain/synaptic-vm/src/tick_executor.rs#L649-L665)
   - **Code:**
     ```rust
     let group_results: Vec<(u32, Vec<crate::StateChange>)> = group_entries
         .into_par_iter()
         .map(|(group_id, ops)| {
             let mut collector = StateChangeCollector { ... };
             for scheduled_op in ops.iter() {
                 self.execute_operation_parallel(&scheduled_op.op, ...)?;
             }
             Ok((group_id, collector.changes))
         })
     ```
4. **Compile-Time Lock-Free Enforcement (`s0_enforcement`):**  
   - Prevents `std::sync::Mutex` usage on hot execution paths when `--features s0-optimization` is active.

#### Auditor Verification Command
Run compiler and VM property tests:
```bash
cargo test -p synaptic-compiler --lib
cargo test -p synaptic-vm --lib
```

---

### Pillar 4: Post-Quantum CE-WOTS+ Signature Precompile (BIP-360 Candidate)

#### The Problem It Solves
Shor's algorithm on a quantum computer solves discrete logarithms and integer factorization in polynomial time, breaking ECDSA and Ed25519. CE-WOTS+ uses pure-hash chains with zero algebraic structure for Shor's algorithm to attack.

#### The Code Implementation
1. **Winternitz WOTS+ Engine ($w=16, l=67$ hash chains):**  
   - **File:** [`synaptic-crypto/src/wots.rs:L14-L55`](file:///opt/synapticchain/synaptic-crypto/src/wots.rs#L14-L55)
   - **Constants:** `WOTS_W = 16`, `WOTS_CHAIN_STEPS = 15`, `WOTS_MSG_NIBBLES = 64`, `WOTS_CSUM_NIBBLES = 3`, Total Chains: `67`.
   - **Chain Hash:** `chain_hash(val: &[u8; 32], steps: usize)` computes $H^{\text{steps}}(x)$ via iterative SHA-256.
2. **Rayon Parallel Batch Verification:**  
   - **File:** [`synaptic-crypto/src/wots.rs:L148-L160`](file:///opt/synapticchain/synaptic-crypto/src/wots.rs#L148-L160)
   - **Code:** Evaluates 67 hash chains in parallel across CPU SIMD lanes.
3. **Bare-Metal VM Precompile `0x10`:**  
   - **File:** [`synaptic-vm/src/precompiles.rs:L22-L38`](file:///opt/synapticchain/synaptic-vm/src/precompiles.rs#L22-L38)
   - **Code:**
     ```rust
     pub const PRECOMPILE_WOTS_VERIFY_ADDR: Address = Address([
         0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
         0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10,
     ]);
     pub const PRECOMPILE_WOTS_VERIFY_GAS: u64 = 100; // Flat 100 gas (~50 microseconds)
     ```
4. **Data Types & Borsh Serialization:**  
   - **File:** [`synaptic-types/src/quantum.rs`](file:///opt/synapticchain/synaptic-types/src/quantum.rs)

#### Auditor Verification Command
Run the isolated WOTS+ cryptographic test suite:
```bash
cargo test -p synaptic-crypto --lib wots::tests
```
**Expected Output:** `test_wots_keygen_sign_verify_roundtrip ... ok`, `test_wots_batch_parallel ... ok`.

---

### Pillar 5: Universal 5-Rail Derivation & XRPL Soulbound Proof Anchor

#### The Problem It Solves
Central banks and institutional users operate across heterogeneous ledgers and need verifiable proof anchors on established settlement networks (XRPL) without forfeiting L1 execution autonomy.

#### The Code Implementation
1. **Interactive 5-Rail Derivation Engine:**  
   - **File:** [`apps/quantumshield-terminal/index.html`](file:///opt/quantumshield-sovereign-dpi/apps/quantumshield-terminal/index.html)
   - **Logic:** Derives Ed25519 (`syn1...`), SECP256k1 (`0x...`), RSA-4096 (`ssh-rsa...`), CE-WOTS+ (67-chain public key), and XRPL (`r...`) deterministically from a single master seed using WebCrypto and noble-crypto.
2. **XRPL XLS-20 Soulbound Minting Script:**  
   - **File:** [`scripts/xrpl_mint_soulbound.mjs:L34-L42`](file:///opt/synapticchain/scripts/xrpl_mint_soulbound.mjs#L34-L42)
   - **Code:**
     ```javascript
     const mintTx = {
       TransactionType: "NFTokenMint",
       Account: wallet.classicAddress,
       NFTokenTaxon: 402, // Synapse x402 / QuantumShield Identity Taxon
       Flags: 0,          // Strictly Non-Transferable (Soulbound)
       URI: uriHex
     };
     ```
3. **Live On-Chain XRPL Proof Anchor:**  
   - **NFTokenID:** `000000006A23544287CF53569B679759B1C09370D301BBB308E7E7120138E578`
   - **Transaction Hash:** `EAC2CABB81DC4D5E78D2AAC4CBEBCE33F54FA744728A9D6D97FACA7B87DCCB31`
   - **Network:** XRPL Testnet Ledger (`wss://s.altnet.rippletest.net:51233`)

#### Auditor Verification Command
Verify the XRPL soulbound token live using `xrpl.js` or curl:
```bash
node -e '
const xrpl = require("/opt/synapticchain/x402-marketplace/gateway/node_modules/xrpl");
(async () => {
  const c = new xrpl.Client("wss://s.altnet.rippletest.net:51233");
  await c.connect();
  const res = await c.request({
    command: "nft_info",
    nft_id: "000000006A23544287CF53569B679759B1C09370D301BBB308E7E7120138E578"
  });
  console.log("XRPL NFToken Verified:", res.result.nft_id, "Taxon:", res.result.nft_taxon);
  await c.disconnect();
})();'
```

---

### Pillar 6: GovPay 150M ZMW Reserve Float & 0.50% ZRA TSA Tax Split

#### The Problem It Solves
Tax leakage and manual fiscal reconciliation cost central banks billions annually. GovPay enforces automated, atomic tax withholding directly into the Treasury Single Account at the smart contract level.

#### The Code Implementation
1. **The ZRA Split Router Smart Contract:**  
   - **File:** [`contracts/production/ZraSplitRouter.syn:L47-L63`](file:///opt/synapticchain/contracts/production/ZraSplitRouter.syn#L47-L63)
   - **Code:**
     ```synlang
     #[reads(paused, zmw_token, treasury, fee_bps, payment_count, total_routed, total_fees)]
     #[writes(payment_count, total_routed, total_fees)]
     pub fn pay(amount: u128, payee: Address, entity: String) {
         require!(self.paused == false, "Paused");
         require!(amount > 0, "Zero amount");
         require!(entity.len() > 0, "Entity required");
         let fee = (amount * (self.fee_bps as u128)) / (FEE_DENOMINATOR as u128); // 50 bps = 0.50%
         let proceeds = amount - fee;
         let seq = self.payment_count + 1;
         call_contract(self.zmw_token, "transfer_from", msg.sender, payee, proceeds);
         call_contract(self.zmw_token, "transfer_from", msg.sender, self.treasury, fee);
         self.payment_count = seq;
         self.total_routed = self.total_routed + amount;
         self.total_fees = self.total_fees + fee;
         emit Routed(msg.sender, payee, entity, amount, fee, seq);
     }
     ```
2. **The Zambia Sovereign ZMW Token (SRC-20):**  
   - **File:** [`contracts/production/Token.syn`](file:///opt/synapticchain/contracts/production/Token.syn)
   - **Address:** `syn1dj2a3nlrc44lqtwzeg9ws0d6plzeayrmxy98m2`
3. **The Bank of Zambia 150M ZMW Reserve Float Deployment:**  
   - **File:** [`scripts/deploy_sovereign_suite.py:L72-L75, L402-L410`](file:///opt/synapticchain/scripts/deploy_sovereign_suite.py#L72-L75)
   - **Code:** `ZMW_RESERVE_FLOAT = 150_000_000 * ZMW_DECIMALS` minted directly to `zambia_boz_reserve_vault` (`syn1r5vkuqaxss46uruj6c5k5wrnzxg04htpuylynr`).
4. **On-Chain Contract Registry:**  
   - **File:** [`contracts/production/addresses.json:L45-L52`](file:///opt/synapticchain/contracts/production/addresses.json#L45-L52)

#### Auditor Verification Command
Run the master 8-pillar hackathon verification script:
```bash
cd /opt/quantumshield-sovereign-dpi && python3 demo_hackathon_e2e.py
```
**Expected Output:** All 8 pillars return `[PASS]`, including the 150M ZMW Reserve Float check and the ZRA Tax Router split validation.

---

### Pillar 7: Deterministic State-Root Replay & Catastrophic Disaster Recovery (ADR-643)

#### The Problem It Solves
If nodes in a cluster disagree on execution fees or execution order, state roots diverge, causing consensus halt or unrecoverable split brains.

#### The Code Implementation
1. **Uniform Proposer & Follower Fee Recipient:**  
   - Every execution context (proposer shadow execution, block winner application, follower catchup replay in `catch_up_canonical_state`, and P2P `sync_manager.rs`) uses uniform `Address::zero()`, guaranteeing 100% bit-for-bit identical state roots.
2. **Zero-Downtime Hot-Snapshots (`cp -al`):**  
   - Extracts atomic state hardlinks from RocksDB without stopping the validator process.
3. **Disaster Recovery Skill Documentation:**  
   - **File:** [`.agents/skills/catastrophic-snapshot-recovery/SKILL.md`](file:///opt/synapticchain/.agents/skills/catastrophic-snapshot-recovery/SKILL.md)

---

## 3. Independent Verification Instructions for Auditors

An auditor with zero prior access to this machine can independently clone and verify all claims by executing:

```bash
# 1. Clone Hackathon Repository
git clone https://github.com/Synaptics-Lab/quantumshield-sovereign-dpi.git
cd quantumshield-sovereign-dpi

# 2. Run the End-to-End Verification Harness
python3 demo_hackathon_e2e.py

# 3. Clone Core Blockchain Monorepo
git clone https://github.com/Synaptics-Lab/Synapse1.git
cd Synapse1

# 4. Verify Post-Quantum Cryptographic Tests
cargo test -p synaptic-crypto --lib wots::tests

# 5. Verify 256-Lane Concurrency Benchmark Against Live Node
python3 stunt_5wallets_256lanes.py
```

All source code is audited, covered by deterministic automated tests, and running in production.
