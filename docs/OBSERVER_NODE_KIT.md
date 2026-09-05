# SynapticChain Observer Node Kit — Auditor & Operator Guide

> **The Decentralization Flex:** Cryptographic proof of live Layer-1 consensus running locally on your own machine.  
> Zero Trust in Remote Endpoints · Zero Validator Stake · 100% Intellectual Property Protection.

---

## 1. Why the Observer Node Kit Matters

When evaluating Layer-1 blockchain architectures, technical evaluators, Ethereum Foundation grantees, and FINOS hackathon judges face a common dilemma:

| Typical Blockchain Submissions (Centralized API Risk) | SynapticChain Layer-1 (The Observer Flex) |
|---|---|
| *"Here is our hosted REST API at api.example.com"* | *"Run `make observer` and verify live P2P blocks streaming on your localhost in 30 seconds."* |
| **Skepticism:** "Is this just an AWS PostgreSQL / Redis database mock behind an Express proxy?" | **Result:** **100% Trustless Verification.** Every block header and state root is verified locally by your own machine. Zero skepticism remaining. |

Running an **Observer Node** allows any developer, auditor, or financial regulator to independently verify every state transition from the live continental validator mesh (Alpha 🇩🇪, Bravo 🇿🇦, Zeta 🇺🇸) without relying on third-party servers.

---

## 2. Intellectual Property Protection & Boundary

To preserve SynapticChain's proprietary IP (including our static schedule compiler DAG and lock-free consensus leader algorithms), the Observer Node Kit enforces a strict disclosure boundary:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                            OBSERVER KIT DISCLOSURE BOUNDARY                            │
├─────────────────────────────────────────────┬──────────────────────────────────────────┤
│ Included in Public Hackathon Repository     │ Protected / Sequestered Core IP          │
├─────────────────────────────────────────────┼──────────────────────────────────────────┤
│ ✓ docker-compose.observer.yml               │ 🔒 Raw Rust consensus & DAG source code  │
│ ✓ config/observer.toml (Bootstrap config)   │ 🔒 Validator private keys & vault roots  │
│ ✓ config/genesis-testnet.toml (Genesis state)│ 🔒 NVMe direct-kernel storage drivers    │
│ ✓ scripts/run-observer.sh (1-click launcher)│                                          │
│ ✓ Pre-compiled read-only Docker container   │                                          │
└─────────────────────────────────────────────┴──────────────────────────────────────────┘
```

The node operates in **`light` (Observer) mode**:
- Connects to the live mesh over libp2p GossipSub (`:9000`).
- Performs fast-forward state synchronization.
- Independently verifies cryptographic state roots and block headers.
- Exposes a local JSON-RPC API (`:8545`) and WebSocket firehose (`:8546`).
- **Never participates in block production, voting, or validator leader races.**
- **Requires zero stake and holds zero private keys.**

---

## 3. The 1-Command Auditor Experience

### Option A: Launch via Makefile (Recommended)
```bash
# Launch the observer node and local Canopy Explorer
make observer
```

### Option B: Launch via Docker Compose Directly
```bash
docker compose -f docker-compose.observer.yml up -d
```

### Option C: Native Linux Execution (No Docker)
If running directly on Linux x86_64:
```bash
./scripts/run-observer.sh --native
```
*(The script automatically downloads the official release binary from `https://synapticchain.xyz/downloads/synaptic-node` and launches it in background mode).*

---

## 4. Verifying Local P2P Block Streaming

Once launched, your local observer node is listening at `http://localhost:8545`. Query it directly:

### 4.1 Node Synchronization & Peer Status
```bash
curl -s -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"syn_getStatus","params":[],"id":1}' | jq .
```

*Expected output:*
```json
{
  "jsonrpc": "2.0",
  "result": {
    "checkpoint_height": 3410,
    "checkpoints_in_epoch": 3410,
    "confirmed_tx_count": 8940,
    "current_epoch": 1,
    "epoch_target": 100000,
    "neuron_count": 3,
    "peer_count": 2,
    "shard_count": 1,
    "synced": true
  },
  "id": 1
}
```

### 4.2 Query Account Balance Locally
```bash
# Query the Bank of Zambia 150M ZMW reserve vault
curl -s -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"syn_getBalance","params":["syn1r5vkuqaxss46uruj6c5k5wrnzxg04htpuylynr"],"id":1}' | jq .
```

### 4.3 Query Recent Transactions
```bash
curl -s -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"syn_getRecentTransactions","params":[5],"id":1}' | jq .
```

---

## 5. Local Canopy Explorer Integration

The observer compose stack automatically provisions a local instance of the **Canopy Evergreen Explorer**:
- **URL:** [http://localhost:3000](http://localhost:3000)
- Interfaces directly with your local observer node at `http://observer-node:8545`.
- Real-time telemetry, transaction inspector, address balance lookup, and checkpoint DAG stream rendered straight from your local container.

---

## 6. Stopping the Observer Node

```bash
# Stop via Makefile
make observer-down

# OR via script
./scripts/run-observer.sh --stop

# OR via Docker Compose
docker compose -f docker-compose.observer.yml down
```

---

## 7. Configuration Reference (`config/observer.toml`)

```toml
[node]
mode = "light"                        # Observer mode (no shard production)
log_level = "info"
skip_stake_check = true                # Zero stake required

[network]
chain_id = 0                           # Synaptic African Testnet
shards = 1
rpc_port = 8545
p2p_port = 9000
metrics_port = 9090
data_dir = "./data/observer"

[p2p]
# Live Continental Mesh Bootstrap Relays
bootstrap_peers = [
    "/ip4/100.126.201.109/tcp/9000",     # Zeta (New Jersey, US)
    "/ip4/100.81.111.43/tcp/9000",      # Alpha (Frankfurt, Germany)
    "/ip4/100.78.228.39/tcp/9000"       # Bravo (Johannesburg, South Africa)
]
```
