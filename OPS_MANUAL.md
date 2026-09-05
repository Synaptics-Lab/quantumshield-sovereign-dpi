# Master E2E Presentation & Operator's Field Manual
### QuantumShield™ & GovPay Sovereign DPI Suite — FINOS Hackathon 2026

```
========================================================================================
  CLASSIFICATION: OPERATIONAL FIELD RUNBOOK · NEVER LOOK UNPREPARED
  NETWORK: SYNAPTICCHAIN LAYER-1 (AFRICAN TESTNET MESH)
  PRIMARY RPC: https://nodes.synapticchain.xyz/rpc
========================================================================================
```

---

## 1. Pre-Flight Health Checklist (Run 2 Minutes Before Going On Stage)

Run this single command in your terminal. If all four sections return green, the system is 100% operational:

```bash
make preflight
```

### Manual Visual Sanity Check
Open these three browser tabs side-by-side:
1. **Tab 1 — Canopy Explorer:** [`https://nodes.synapticchain.xyz`](https://nodes.synapticchain.xyz)
   - *Check:* Block height is ticking upwards past #1,390; 3/3 validators showing green lockstep.
2. **Tab 2 — QuantumShield Terminal:** [`https://wallet.synapticchain.xyz/quantum/`](https://wallet.synapticchain.xyz/quantum/)
   - *Check:* Terminal console loads with Canopy light-mode styling; buttons responsive; XRPL XLS-20 soulbound anchor verified.
3. **Tab 3 — GovPay Sovereign Suite:** [`https://govpay.synapticchain.xyz`](https://govpay.synapticchain.xyz) (or [`https://synapticchain.xyz/govpay/`](https://synapticchain.xyz/govpay/))
   - *Check:* Bank of Zambia vault displays **150,000,000 ZMW**; recent settlements feed ticking.

---

## 2. The Foolproof 3-Minute Live Presentation Flow

### Phase 1: Establish Layer-1 Infrastructure (0:00 – 0:45)
**Screen:** Switch to **Tab 1** (`https://nodes.synapticchain.xyz`).

* **What to say:**  
  *"Judges, before showing the applications, we want to prove we are running on a live, high-throughput Layer-1 blockchain with native consensus, not a local mock or EVM clone. This is SynapticChain L1."*
* **What to point at:**  
  - Point to the **Canonical Height** ticking in real time: *"We are at block #1,390+ with sub-500 millisecond DAG finality."*
  - Point to the **3 Active Neurons**: *"The SCBFT consensus quorum is running 3 independent validators in active lockstep on our African testnet mesh."*
  - Point to the design: *"Our interface adheres strictly to the Canopy Evergreen spatial design system — light, institutional, zero dark-mode gaming aesthetic."*

---

### Phase 2: Solve the Quantum & Bridge Threats (0:45 – 1:45)
**Screen:** Switch to **Tab 2** (`https://wallet.synapticchain.xyz/quantum/`).

* **What to say:**  
  *"Institutional finance faces two existential cryptographic risks: cross-chain bridge hacks ($3.2B stolen) and the impending arrival of quantum computing breaking standard ECDSA and Ed25519 signatures ($Q$-Day). QuantumShield solves both at the protocol level."*
* **What to click & demonstrate:**
  1. Click **"Derive 5-Rail Isomorphism"**:  
     *"Watch this: From one single 32-byte master seed, our cryptographic engine deterministically projects native addresses across SynapticChain, Ethereum, XRP Ledger, Solana, and Bitcoin Native SegWit. Zero wrapped tokens, zero custodial bridges, 100% zero-bridge custody."*
  2. Point to the **XRPL XLS-20 Soulbound Anchor**:  
     *"We also anchor the sovereign L1 identity to the XRPL testnet ledger consensus via a native non-transferable XLS-20 NFToken (`Flags: 0`, Taxon `402`)."*
  3. Scroll to the **CE-WOTS+ Quantum Defense** card:  
     *"Existing post-quantum schemes like Dilithium create 3.5 to 4.5 KB of wire bloat per signature. We implement Consensus-Enforced Winternitz Signatures (CE-WOTS+, NIST SP 800-208) with 67 compact hash chains (2,144 bytes uncompressed)."*
  4. Click **"Verify Signature & Advance Watermark"**:  
     *"Classical WOTS suffers from key reuse leakage. SynapticChain solves this by folding the ephemeral public key directly into the ADR-062 monotonic 256-lane execution watermark. Advancing the watermark permanently invalidates past signatures in the VM for a flat 100 gas."*

---

### Phase 3: Deliver Sovereign DPI & Revenue Collection (1:45 – 2:30)
**Screen:** Switch to **Tab 3** (`https://govpay.synapticchain.xyz`).

* **What to say:**  
  *"Now let's examine national public infrastructure. We have deployed the GovPay Sovereign DPI Suite, piloted for the Republic of Zambia, Smart Zambia Institute, and the Bank of Zambia."*
* **What to point at & demonstrate:**
  1. Point to the **Bank of Zambia Vault**:  
     *"The Central Bank vault is funded with a 150,000,000 ZMW on-chain reserve backing the national digital currency."*
  2. Point to the **INRIS Biometric Anti-Ghost Identity**:  
     *"Every recipient identity is backed by a W3C-compliant Soulbound Token (SBT). Government payroll disbursements verify biometric uniqueness, mathematically eliminating 'ghost workers'."*
  3. Execute a **Demo Payment** (Enter 100 ZMW and click **Send**):  
     *"Notice the settlement: Our stateless ZraSplitRouter contract automatically pulls a 0.50% statutory revenue deduction directly into the Single Treasury Account (TSA) inside the exact same atomic transaction. No reconciliation, no manual tax filing, zero intermediary leakage."*

---

### Phase 4: The Terminal Proof & Conclusion (2:30 – 3:00)
**Screen:** Switch to your Terminal window.

* **What to do:**  
  Execute:
  ```bash
  make demo
  ```
* **What to say:**  
  *"To prove everything we just saw is cryptographically verified by the node runtime, here is our 6-pillar live telemetry runner executing in 2 seconds against our public endpoint: SCBFT consensus, 5-Rail isomorphism, CE-WOTS+ precompile 0x10, 150M ZMW vault, RFC 9110 x402 micropayments, and all production portals. All code is published under the Synaptic Public License v1.0. Thank you."*

---

## 3. The Complete Live `curl` Command Arsenal

Have these exact curl commands ready. If a judge asks *"Can you show me the raw JSON-RPC response?"*, run these:

### 1. Query L1 Consensus & Network Height
```bash
curl -s -X POST https://nodes.synapticchain.xyz/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"syn_getStatus","params":[],"id":1}' | jq .
```
*Expected Result:*
```json
{
  "jsonrpc": "2.0",
  "result": {
    "checkpoint_height": 680,
    "confirmed_tx_count": 1250,
    "neuron_count": 3,
    "peer_count": 2,
    "synced": true,
    "tps": 1208.58
  },
  "id": 1
}
```

### 2. Query the 3 Active SCBFT Quorum Validators
```bash
curl -s -X POST https://nodes.synapticchain.xyz/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"syn_getValidators","params":[],"id":1}' | jq .
```
*Expected Result:* Lists 3 neurons (`syn1k40...`, `syn1f88...`, `syn1t9e...`) with weight `0.466667`, 100 reputation, and active peer IDs.

### 3. Query Specific Checkpoint State & Transactions
```bash
curl -s -X POST https://nodes.synapticchain.xyz/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"syn_getCheckpoint","params":[650],"id":1}' | jq .
```

### 4. Query Sovereign Treasury (TSA) Balance
```bash
curl -s -X POST https://nodes.synapticchain.xyz/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"syn_getBalance","params":["syn1t9hp790tpp450jh0sd8lyd3znqccycal4m2z0u"],"id":1}' | jq .
```

### 5. Query Bank of Zambia (BoZ) 150M Reserve Vault
```bash
curl -s https://synapticchain.xyz/api/reserve | jq .
```
*Expected Result:*
```json
{
  "ok": true,
  "total_supply_zmw": "150224999.99",
  "reserve_vault_zmw": "150100000",
  "reserve_vault": "syn1r5vkuqaxss46uruj6c5k5wrnzxg04htpuylynr",
  "ratio_pct": "99.91"
}
```

### 6. Query Live Sovereign DPI Health & Contracts
```bash
curl -s https://synapticchain.xyz/api/status | jq .
```

### 7. Test RFC 9110 HTTP 402 ("Payment Required") Paywall
```bash
# Step 1: Probe endpoint -> Returns HTTP 402
curl -i -s http://localhost:8402/api/agent-alpha | grep -iE "HTTP|x402|WWW-Authenticate"

# Step 2: Run autonomous client agent settlement
cd /opt/quantumshield-sovereign-dpi/apps/x402-gateway && node client_agent.js
```

---

## 4. "If The Judge Asks..." — Defense Cheat Sheet

| Judge Question | The Perfect Answer |
|---|---|
| **"Winternitz (WOTS) signatures are one-time signatures. If an account sends two transactions, doesn't it leak the private key?"** | *"In classical WOTS, yes. In QuantumShield, **no**. We solve this via ADR-062: the ephemeral key is cryptographically folded into the monotonic 256-lane execution watermark ($\mathcal{W}_k$). Advancing the watermark on-chain permanently invalidates the old signature vector. Even with infinite quantum compute, a forged signature is rejected at consensus because its watermark has already expired."* |
| **"Why not just use Dilithium or SPHINCS+?"** | *"Dilithium signatures are 3.5 KB to 4.5 KB. In a high-throughput blockchain, that inflates blocks by 15x and bottlenecks P2P gossipsub. CE-WOTS+ uses pure hash chains, requiring only 2,144 bytes uncompressed. Furthermore, hash verification runs in pure SIMD in 0.05ms, costing only 100 gas flat."* |
| **"How can you claim 5-Rail custody without bridges?"** | *"Bridges require wrapped assets and third-party multisigs. Universal 5-Rail is an **isomorphic mathematical projection**: a single 32-byte seed deterministically derives valid native keypairs on SynapticChain, Ethereum, XRPL, Solana, and Bitcoin. The user or autonomous agent controls native keys on all five chains simultaneously."* |
| **"Is this simulated or running on real infrastructure?"** | *"It is 100% live on our 3-neuron physical mesh on Zeta. Our canonical checkpoint height is ticking continuously at sub-500ms intervals, and all contracts are deployed and funded on Layer-1."* |
| **"What is your open-source licensing model?"** | *"We use the Synaptic Public License v1.0 (SPL-1.0). It grants full royalty-free rights for hackathon evaluation, academic audit, and client dApp building, while retaining international defensive patent protection against hostile IP assertions."* |

---

## 5. Emergency Hot-Fix & Troubleshooting Runbook

If anything behaves unexpectedly during rehearsal:

```bash
# 1. Check if all local PM2 services are running on Delta
pm2 status

# 2. If sovereign-suite-server or flow-bot needs a quick restart:
pm2 restart sovereign-suite-server sovereign-flow-bot

# 3. Test L1 node connectivity directly to physical validator:
curl -s -X POST http://100.126.201.109:8545 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"syn_getStatus","params":[],"id":1}' | jq .

# 4. If Cloudflare or public Nginx needs reload:
nginx -t && systemctl reload nginx
```
