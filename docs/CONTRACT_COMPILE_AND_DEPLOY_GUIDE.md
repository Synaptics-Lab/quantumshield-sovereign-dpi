# Contract Compilation, Gas Patching & Deployment Guide

> **The Definitive Operational Runbook for Compiling, Deploying, and Initializing SynapticLang Smart Contracts on SynapticChain Layer-1.**  
> Target Environments: Local Validator Node, African Testnet Mesh (`https://nodes.synapticchain.xyz/rpc`).

---

## 1. Prerequisites & Toolchain Setup

Before compiling or deploying smart contracts, ensure you have the required CLI tools and dependencies:

### 1.1 The `synlang` Compiler Binary
The canonical SynapticLang compiler CLI is installed system-wide at `/usr/local/bin/synlang`.

Verify installation:
```bash
synlang compile --help 2>&1 | head -n 5
```

If building from source in the core repository (`/opt/synapticchain`):
```bash
cargo build --release -p synaptic-compiler --bin synlang
sudo cp target/release/synlang /usr/local/bin/synlang
```

### 1.2 Python 3 & Client SDK
Deployments can be scripted using Python 3 and the included SynapticChain SDK:
```bash
# Ensure Python 3.10+ is available
python3 --version
```
The Python SDK resides at `sdks/python/src` within the repository and provides:
- `Wallet`: Ed25519 signing, address derivation, and automatic transaction dispatch.
- `RpcClient`: Direct interface to Axum JSON-RPC endpoints.
- `Value`: Strongly-typed enum serializers (`Value.u128`, `Value.address`, `Value.string`, etc.).
- `derive_contract_address`: Deterministic contract address calculation from deployer address and lane nonce.

### 1.3 Target RPC Endpoints
- **African Testnet Public RPC:** `https://nodes.synapticchain.xyz/rpc`
- **Mesh Direct RPC:** `http://100.126.201.109:8545/`
- **Local Dev Node:** `http://127.0.0.1:8545/`

### 1.4 Deployer Keypair
Deploying contracts requires a 32-byte Ed25519 private key hex with a funded SYN balance. On the African testnet, genesis deployer credentials can be exported:
```bash
# Export genesis or funded developer key
export SYNAPTIC_PRIVATE_KEY="92d1be6895e3b1532e68b39ed4255d8470d188d81b7f725038dad720762fb34c"
export SYNAPTIC_RPC="https://nodes.synapticchain.xyz/rpc"
```

---

## 2. Step 1: Compiling Contracts to `.plan`

SynapticLang contracts (`.syn`) compile into binary **Execution Plans (`.plan`)** serialized via Borsh.

### 2.1 The Compilation Command
```bash
synlang compile contracts/GovPayZMWToken.syn contracts/GovPayZMWToken.plan
```

### 2.2 Expected Compilation Output
```text
🔧 SynapticLang Compiler
========================

Reading: contracts/GovPayZMWToken.syn
Compiling...

✅ Compilation successful!

Contract: Token
Functions: 11
State slots: 7

✅ Execution plan written to: contracts/GovPayZMWToken.plan (6645 bytes, Borsh)
🚀 Ready for deployment!
   Deploy with: synlang deploy contracts/GovPayZMWToken.plan <rpc_endpoint> --key <private_key_hex> --nonce <nonce>
```

### 2.3 What Is Inside an `ExecutionPlan`?
Unlike EVM bytecode which consists of flat opcode streams, a `.plan` file contains:
1. **Contract Metadata:** Contract name, version, and author.
2. **State Schema:** Slot indices, variable names, and types for storage packing.
3. **Function Descriptors:** Entry point signatures, function selectors (4-byte SHA3 hashes), and parameter types.
4. **Static Dependency DAG:** Read/write state sets per function, used by the consensus engine to assign transactions into lock-free parallel Rayon lanes.
5. **Static Gas Budgets:** Pre-calculated execution tick budgets per function.

---

## 3. Step 2: Gas Economics & Sizing

### 3.1 Deployment Gas Sizing Formula
Deployment transactions carry contract bytecode onto Layer-1 state storage. The minimum gas limit for a deployment transaction is determined by:

$$	ext{gas\_limit} = \max(200{,}000{,}000,\; 5{,}000{,}000 + (	ext{code\_bytes} 	imes 100{,}000) + 1{,}000{,}000)$$

- **Base Deployment Gas:** 5,000,000 gas.
- **State Storage Fee:** 100,000 gas per serialized plan byte.
- **Consensus Headroom:** 1,000,000 gas buffer.
- **Default CLI Allocation:** `synlang deploy` automatically applies this formula and caps at a safe limit of **200,000,000 gas**.

### 3.2 Function Invocation Gas Sizing
When calling contract functions post-deployment:
- **Read-Only Getters (`get_total_supply`, `balance_of`):** 100,000 gas.
- **State Mutation Functions (`transfer`, `approve`):** 500,000 gas.
- **Complex Multi-Contract Calls (`ZraSplitRouter.pay`):** 1,000,000 – 5,000,000 gas.
- **Initializers (`init`, `setup`):** 2,000,000 – 5,000,000 gas (due to multi-slot cold storage initialization).

---

## 4. Step 3: Deploying Contracts

### Method A: Deploy via `synlang` CLI (Recommended for Single Contracts)

The `synlang deploy` command automatically:
1. Derives your deployer address from the private key.
2. Formulates the `DeployPayload`.
3. Signs the transaction using Ed25519.
4. Computes the deterministic contract address: `Crypto::contract_address(deployer, nonce)`.
5. Submits the transaction through consensus via `syn_sendTransaction`.

```bash
# 1. Fetch the latest nonce for lane 0
NONCE=$(curl -s -X POST https://nodes.synapticchain.xyz/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"syn_getNonce","params":["syn1c2p5829xmy46muue0d3yrt3a3w7myn23x8l3t5", 0],"id":1}' | jq .result)

# 2. Deploy the compiled plan
synlang deploy contracts/GovPayZMWToken.plan https://nodes.synapticchain.xyz/rpc \
  --key 92d1be6895e3b1532e68b39ed4255d8470d188d81b7f725038dad720762fb34c \
  --nonce $NONCE
```

#### Expected Output:
```text
🚀 SynapticLang Deploy
=====================

Deployer address: syn1c2p5829xmy46muue0d3yrt3a3w7myn23x8l3t5
Reading plan: contracts/GovPayZMWToken.plan
Plan size: 6645 bytes
RPC endpoint: https://nodes.synapticchain.xyz/rpc
Nonce: 42

📡 Submitting deployment transaction...
✅ Deployment transaction submitted!
   TX ID: 0xa9f848b598d9e2b10294e019f727395029a738bf58c49e29a9e38d728194ad61
   Contract address: syn1dj2a3nlrc44lqtwzeg9ws0d6plzeayrmxy98m2
   Note: Wait 3-6 seconds for consensus confirmation.
```

---

### Method B: Deploy via Python SDK (Recommended for Full Suites & Automation)

Here is a complete, copy-pasteable script to compile, deploy, and verify contracts programmatically:

```python
#!/usr/bin/env python3
import subprocess
import time
from pathlib import Path
from synapticchain import Wallet, RpcClient, Address, derive_contract_address
from synapticchain.wallet import TxOptions

RPC_URL = "https://nodes.synapticchain.xyz/rpc"
PRIVATE_KEY_HEX = "92d1be6895e3b1532e68b39ed4255d8470d188d81b7f725038dad720762fb34c"

rpc = RpcClient(RPC_URL)
wallet = Wallet.from_hex(PRIVATE_KEY_HEX, rpc)
deployer_addr = wallet.address()

print(f"Deployer: {deployer_addr.to_bech32()}")
print(f"Balance: {rpc.get_balance(deployer_addr) / 1e18:.2f} SYN")

# 1. Compile contract
syn_file = Path("contracts/GovPayZMWToken.syn")
plan_file = Path("contracts/GovPayZMWToken.plan")
subprocess.run(["synlang", "compile", str(syn_file), str(plan_file)], check=True)

# 2. Read Borsh plan
plan_bytes = plan_file.read_bytes()

# 3. Fetch latest lane 0 nonce
nonce = rpc._call("syn_getNonce", [deployer_addr.to_bech32(), 0])
print(f"Using Nonce: {nonce}")

# 4. Dispatch deployment transaction
tx_hash = wallet.deploy(
    plan_bytes,
    constructor_args=[],
    options=TxOptions(gas_limit=5_000_000, gas_price=100, nonce=nonce, nonce_key=0)
)
contract_addr = derive_contract_address(deployer_addr, nonce)

print(f"✅ Deployed! Tx Hash: {tx_hash}")
print(f"📍 Contract Address: {contract_addr.to_bech32()}")

# Wait for consensus block inclusion
print("Waiting 4 seconds for checkpoint finality...")
time.sleep(4)
```

---

## 5. Step 4: Post-Deployment Initialization (`init` / `setup`)

Because SynapticLang contracts do **not** use implicit constructor execution, state variables (such as token name, symbol, total supply, or owner) must be explicitly initialized via a post-deployment transaction.

### 5.1 Value Serialization Schema for RPC Calls
When invoking contract functions via `syn_callContractV2` or SDK, parameters must follow the **externally-tagged JSON enum format**:

| Parameter Type | JSON Schema Format | Example Payload |
|---|---|---|
| `Address` | `{"Address": "<bech32m>"}` | `{"Address": "syn1c2p5829xmy46muue0d3yrt3a3w7myn23x8l3t5"}` |
| `u128` | `{"U128": "<string_integer>"}` | `{"U128": "150000000000000000000000000"}` (Always string!) |
| `u64` | `{"U64": <integer>}` | `{"U64": 50}` |
| `u32` | `{"U32": <integer>}` | `{"U32": 1}` |
| `u8` | `{"U8": <integer>}` | `{"U8": 18}` |
| `bool` | `{"Bool": <boolean>}` | `{"Bool": false}` |
| `String` | `{"String": "<utf8_text>"}` | `{"String": "Bank of Zambia"}` |

> ⚠️ **CRITICAL WARNING — `U128` Must Be a String:**  
> Never pass raw numbers for `U128` or `U256` in JSON payloads! Large numbers like $10^{18}$ will be parsed as IEEE 754 floats by standard JSON parsers (e.g., `1e+18`), causing immediate deserialization panics in the node runtime.

---

### 5.2 Initializing via JSON-RPC (`curl`)

Initialize the deployed `GovPayZMWToken` contract with **150,000,000 ZMW**:

```bash
curl -s -X POST https://nodes.synapticchain.xyz/rpc \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "syn_callContractV2",
    "params": {
      "address": "syn1dj2a3nlrc44lqtwzeg9ws0d6plzeayrmxy98m2",
      "function": "init",
      "args": [
        {"String": "GovPay Zambian Kwacha"},
        {"String": "ZMW"},
        {"U8": 18},
        {"U128": "150000000000000000000000000"}
      ],
      "from": "syn1c2p5829xmy46muue0d3yrt3a3w7myn23x8l3t5",
      "gas_limit": 2000000
    },
    "id": 1
  }' | jq .
```

---

### 5.3 The Golden Verification Metric: `gas_used`

Examine the JSON-RPC response from your initialization transaction:

```json
{
  "jsonrpc": "2.0",
  "result": {
    "status": "success",
    "gas_used": 142850,
    "return_value": null
  },
  "id": 1
}
```

- **Success Indicator:** `gas_used > 100,000` confirms that state variables were properly allocated in RocksDB storage.
- **Failure Indicator:** `gas_used ~20,000` indicates that state writes were discarded (usually due to a missing `self.` prefix in the contract code).

---

## 6. Step 5: On-Chain State Verification

Once initialized, verify that the contract state is publicly queryable.

### 6.1 Verify Contract Bytecode (`syn_getCode`)
```bash
curl -s -X POST https://nodes.synapticchain.xyz/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"syn_getCode","params":["syn1dj2a3nlrc44lqtwzeg9ws0d6plzeayrmxy98m2"],"id":1}' | jq .
```
*Expected:* Returns `result` with non-empty bytecode hex.

### 6.2 Verify Total Supply
```bash
curl -s -X POST https://nodes.synapticchain.xyz/rpc \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "syn_callContractV2",
    "params": {
      "address": "syn1dj2a3nlrc44lqtwzeg9ws0d6plzeayrmxy98m2",
      "function": "get_total_supply",
      "args": [],
      "from": "syn1c2p5829xmy46muue0d3yrt3a3w7myn23x8l3t5",
      "gas_limit": 100000
    },
    "id": 1
  }' | jq .
```
*Expected:* Returns `{"U128": "150000000000000000000000000"}`.

### 6.3 Verify Deployer Balance
```bash
curl -s -X POST https://nodes.synapticchain.xyz/rpc \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "syn_callContractV2",
    "params": {
      "address": "syn1dj2a3nlrc44lqtwzeg9ws0d6plzeayrmxy98m2",
      "function": "balance_of",
      "args": [{"Address": "syn1c2p5829xmy46muue0d3yrt3a3w7myn23x8l3t5"}],
      "from": "syn1c2p5829xmy46muue0d3yrt3a3w7myn23x8l3t5",
      "gas_limit": 100000
    },
    "id": 1
  }' | jq .
```

---

## 7. Step 6: Contract Gas Provisioning (Funding Sweep)

If your smart contract executes outbound native transfers (such as `transfer(recipient, amount)` in `AtomicRouter.syn`) or interacts via cross-contract calls, the contract address itself must hold a native SYN balance:

```bash
# Fund the contract address with 10 SYN for operational gas
python3 -c "
from synapticchain import Wallet, RpcClient, Address
from synapticchain.wallet import TxOptions

rpc = RpcClient('https://nodes.synapticchain.xyz/rpc')
wallet = Wallet.from_hex('92d1be6895e3b1532e68b39ed4255d8470d188d81b7f725038dad720762fb34c', rpc)

target = Address.from_bech32('syn1dj2a3nlrc44lqtwzeg9ws0d6plzeayrmxy98m2')
n = rpc._call('syn_getNonce', [wallet.address().to_bech32(), 0])
wallet.transfer(target, int(10 * 1e18), options=TxOptions(gas_limit=100_000, gas_price=100, nonce=n, nonce_key=0))
print('✓ Contract funded with 10 SYN')
"
```

---

## 8. Diagnostic & Troubleshooting Runbook

| Error / Symptom | Root Cause | Solution |
|---|---|---|
| `"Nonce already used" or "Invalid nonce"` | Concurrent transactions submitted on the same lane without incrementing nonce. | Query `syn_getNonce(address, lane)` before submission, or rotate across lanes 0–255. |
| `gas_used ~20,000` on `init()` | State variable assignments missing `self.` prefix; assignments evaporated as local variables. | Prepend `self.` to every state write and recompile. |
| `"Execution reverted: Insufficient balance"` | Payer does not hold enough token balance or pre-approved allowance. | Execute `approve(router, amount)` on the token contract before calling the router. |
| `Float parsing error (1e+18)` | Passed a raw integer for `U128` in JSON-RPC payload. | Enclose `U128` values in quotes: `{"U128": "1000000000000000000"}`. |
| `"Contract not found"` after node restart | Contract was deployed via an ephemeral RPC method rather than consensus. | Always deploy using `synlang deploy` or signed `syn_sendTransaction`. |
