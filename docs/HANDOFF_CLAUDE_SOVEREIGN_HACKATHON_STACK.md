# HANDOFF: GOVPAY SOVEREIGN DPI & FINOS HACKATHON STACK

**To:** Incoming Claude Instance  
**From:** Antigravity / Gemini Instance  
**Date:** September 5, 2026  
**Status:** **100% PRODUCTION / DEMO READY — ALL 8 PILLARS PASSING (CODE 0)**  
**Branch:** `production-1` (Repo: `https://github.com/Synaptics-Lab/Synapse1.git`)  

---

## 1. PRIVILEGES & ACCESS CREDENTIALS

> [!IMPORTANT]
> **Privilege Level:** You have **FULL root and administrative privileges** across the entire environment.
> - **Build Box / Gateway (Delta):** Local root access (`/opt/synapticchain`), PM2 daemon control, systemd, Nginx, Docker.
> - **Validator Mesh (Zeta):** Passwordless SSH root access to `root@100.126.201.109` (the ONLY active physical validator host).
> - **Git & Embedded PAT:** You have full access to push and commit to GitHub (`origin` -> `https://github.com/Synaptics-Lab/Synapse1.git`) with the embedded personal access token (PAT) configured in the git credential store / environment.
> - **Key Vault:** Vaulted credentials and agent keystores live under `/root/.synaptic/vault/`.

> [!CAUTION]
> **CRITICAL GIT PULL INSTRUCTION FOR YOUR CHECKOUT:**
> If your checkout has an uncommitted `addresses.json` that predates the registry deployment, a plain `git pull` will refuse (`error: Your local changes to the following files would be overwritten by merge`).
> **You MUST discard the outdated local file before pulling:**
> ```bash
> git checkout -- contracts/production/addresses.json && git pull origin production-1
> ```

---

## 2. INFRASTRUCTURE & TOPOLOGY MAP

```
                                  [ CLOUDFLARE EDGE ]
                                           │
                    ┌──────────────────────┴──────────────────────┐
                    │                                             │
         [ Delta (89.117.48.66) ]                      [ Zeta (100.126.201.109) ]
         Build, Gateway & Microservices                ONLY Physical Validator Box
         ─────────────────────────────                 ──────────────────────────
         • Nginx Reverse Proxy / Ingress               • synaptic-zeta-1 (:8545, :9000)
         • sovereign-suite-server (:8310)              • synaptic-zeta-2 (:8547, :9002)
         • sovereign-flow-bot (Ring settler)           • synaptic-zeta-3 (:8549, :9004)
         • x402-gateway (:8402)                        • SCBFT Consensus Lockstep (Height > 100)
         • x402-consumer (:3006)                       • release-fast binary (MD5: 1eb72b30d...)
         • matrix_wallet (:3005)
         • artemis-bot (:8080)
         • terrarium-auto-onboard (:8090)
```

> [!WARNING]
> **Decommissioned Nodes:** Alpha (`100.81.111.43`) and Bravo (`100.78.228.39`) are **OFFLINE / DECOMMISSIONED**. Never attempt to connect to or wait for them. All consensus runs on Zeta; all web/PM2 services run on Delta.

---

## 3. WHAT WAS ACCOMPLISHED

### A. New Binary Deployment & Clean Genesis Launch
- **Binary:** Verified and deployed `target/release-fast/synaptic-node` (MD5: `1eb72b30d376ab10553dec747e422ac9`) to Zeta (`100.126.201.109`).
- **Clean Genesis Wipe:** Wiped validator state directories on Zeta (`synaptic-zeta-1..3`), launched clean genesis on Shard 0.
- **SCBFT Lockstep:** 3-neuron consensus quorum confirmed in active lockstep (`synced: true`, peer count: 2).
- **Genesis Historical Stamp:** Broadcasted the immutable genesis manifesto stamp on L1.

### B. Anti-Slop Rebranding (Zero-Gesco Audit)
- Completely scrubbed all mentions of the former partner ("Gesco" / "Gibel Boye") across the entire codebase, UI templates, backend APIs, briefs, and demo runners.
- Established the official **GovPay Sovereign DPI Suite**:
  - Web package: `packages/sovereign-dpi-suite`
  - Web root: `/var/www/govpay/`
  - Vhost: `govpay.synapticchain.xyz` (and direct route `https://synapticchain.xyz/govpay/`)
  - Backends: Updated `router.ts` and `flow-bot.ts` with institutional sovereign naming.

### C. Sovereign DPI Smart Contracts Deployed & Funded
All 4 core sovereign contracts were compiled, deployed, initialized, and verified on L1:
1. **National Currency (ZMW):** `syn1dj2a3nlrc44lqtwzeg9ws0d6plzeayrmxy98m2` (SRC-20 token standard).
2. **ZRA Automated Tax Split Router:** `syn122h32ja44hhz8ut543krjrrzz9jkd8lxw3m9f7` (0.50% TSA treasury split).
3. **INRIS Sovereign Identity SBT:** `syn1zy8dsuvpc7mt6m8lnp7ueeq808a49q6xmef06l` (Biometric anti-ghost employee registry).
4. **ISO 20022 Pacs.008 Payment Router:** `syn1kf0wmhqzwy649a67cv5kaapyt3pl4cga9cyuku` (Commercial bank RTGS settlement).
5. **Bank of Zambia (BoZ) Vault:** Seeded with **150,000,000 ZMW** backed sovereign reserve at `syn1r5vkuqaxss46uruj6c5k5wrnzxg04htpuylynr`.
6. **Ambient Flow-Bot Ring:** 6 wallets funded with ZMW and SYN gas, actively executing automated tax-split settlements on-chain every 20 seconds.

### D. Protocol-Level L1 Features (Universal 5-Rail & CE-WOTS+ Quantum Shield)
Implemented and unit-tested directly in the Rust node runtime:
- **`synaptic-types`:** `ChainRail`, `MultiRailAddresses`, `PreimageHashLock`, `AtomicSwapCondition`, `WotsSignature`, `WotsPublicKey`, `QuantumWitness`.
- **`synaptic-crypto`:** 
  - Pure-Rust `cross_rail.rs`: Universal keypair derivation for SynapticChain, Ethereum, XRPL, Solana, Bitcoin Native SegWit from a single 32-byte seed.
  - `wots.rs`: CE-WOTS+ ($w=16$, 67 hash chains) keygen, signing, and Rayon parallel batch verification.
  - `fold.rs`: Ephemeral key folding bound to ADR-062 monotonic lane watermarks ($\mathcal{W}_k$).
- **`synaptic-vm`:**
  - `0x10` (`PRECOMPILE_WOTS_VERIFY`): 100 gas flat.
  - `0x11` (`PRECOMPILE_ATOMIC_ROUTER`): 150 gas flat with automated 0.1% SYN burn.
- **`synaptic-node`:** Added JSON-RPC methods: `syn_deriveMultiRail`, `syn_verifyQuantumWitness`, `syn_verifyWotsSignature`, `syn_executePrecompile`.

### E. Frontend & PM2 Standalone Stability
- Resolved Next.js 16 standalone server routing errors by creating permanent standalone shell runners:
  - `matrix_wallet/run_standalone.sh` (port 3005)
  - `x402-marketplace/consumer/run_standalone.sh` (port 3006)
- Automatically link and copy `public` and `.next/static` assets into standalone directories.
- All PM2 services online and healthy.

### F. Automation Tooling & Skills Created
- `start_clean_sovereign_stack.sh`: One-click clean genesis wipe, contract deploy, reserve seeding, PM2 restart, and verification.
- `verify_clean_stack.py`: 8-pillar verification suite (exits with code 0).
- `demo_finos_e2e.py`: Interactive CLI demonstration for FINOS / hackathons.
- `.agents/skills/govpay-sovereign-finos-stack/SKILL.md`: Master operational runbook and architecture specification.

---

## 4. VERIFIED 8-PILLAR HEALTH STATUS

Run at any time:
```bash
python3 /opt/synapticchain/verify_clean_stack.py
```

Current Live Output:
```
[PILLAR 1] Live SCBFT 3-Neuron Consensus (Zeta Mesh)      ✓ PASS (Quorum: 2 peers, height advancing)
[PILLAR 2] Universal 5-Rail Native Derivation Standard    ✓ PASS (Precompile 0x11 bound)
[PILLAR 3] CE-WOTS+ Post-Quantum Shield & Monotonic Watermarks ✓ PASS (Precompile 0x10 bound)
[PILLAR 4] Machine-to-Machine RFC 9110 x402 Gateway       ✓ PASS (HTTP 402 verified)
[PILLAR 5] GovPay Sovereign DPI Smart Contracts           ✓ PASS (4/4 verified, 150M ZMW reserve)
[PILLAR 6] Sovereign Backend & Ambient Flow-Bot Streaming ✓ PASS (Ring settlement active)
[PILLAR 7] Production Web & Dashboard Services            ✓ PASS (6/6 HTTP 200 OK)
[PILLAR 8] Zero-Gesco Anti-Slop Rebranding Audit          ✓ PASS (100% clean across UI, code, APIs)

  >>> ALL 8 CORE PILLARS PASSED — STACK IS 100% DEMO READY <<<
```

---

## 5. LIVE PRODUCTION ENDPOINTS

| Service | URL / Port | Notes |
| :--- | :--- | :--- |
| **GovPay Sovereign DPI Suite** | `https://govpay.synapticchain.xyz/` | Primary government & central bank portal |
| **Direct Web Route** | `https://synapticchain.xyz/govpay/` | Direct path on apex domain |
| **Interactive Architecture Portal** | `https://synapticchain.xyz/architecture.html` | Visual 5-Rail & PQC architecture |
| **Matrix Web4 Wallet** | `https://wallet.synapticchain.xyz/` (:3005) | 256-lane concurrency terminal wallet |
| **x402 M2M Marketplace** | `https://api.synapticchain.xyz/` (:8402) | RFC 9110 machine-payable APIs |
| **x402 Consumer App** | Internal port `:3006` | Standalone client portal |
| **Block Explorer** | `https://explorer.synapticchain.xyz/` | Zero-database direct Axum firehose stream |
| **Public JSON-RPC** | `https://nodes.synapticchain.xyz/rpc` | Proxies to Zeta `:8545` |
| **WebSocket Firehose** | `wss://nodes.synapticchain.xyz/ws` | Proxies to Zeta `:9000` |

---

## 6. QUICK COMMAND REFERENCE FOR CLAUDE

- **Run the Master Verification:**
  ```bash
  python3 /opt/synapticchain/verify_clean_stack.py
  ```
- **Run the Interactive Hackathon / FINOS Demo:**
  ```bash
  python3 /opt/synapticchain/demo_finos_e2e.py
  ```
- **Perform a Full Clean Stack Restart (if ever needed):**
  ```bash
  /opt/synapticchain/start_clean_sovereign_stack.sh
  ```
- **Skip the Zeta wipe and only redeploy contracts/restart PM2:**
  ```bash
  /opt/synapticchain/start_clean_sovereign_stack.sh --skip-wipe
  ```
- **Check PM2 Daemons:**
  ```bash
  pm2 status
  ```
- **Check Consensus on Zeta:**
  ```bash
  curl -s -X POST http://100.126.201.109:8545 \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"syn_getStatus","params":[],"id":1}' | jq .
  ```
