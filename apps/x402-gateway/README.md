# x402 Micropayment Gateway & Agent Client

> **Standard:** IETF RFC 9110 HTTP 402 ("Payment Required")  
> **Settlement:** SynapticChain Layer-1 (Sub-500ms DAG Finality, 256-Lane Static Scheduling)

## Overview
The x402 Gateway enables machine-to-machine (M2M) API monetisation and autonomous AI agent commerce without credit cards, subscriptions, or custodial balances.

## Flow
1. **Challenge:** An autonomous agent requests a paywalled API route without credentials. The server responds with `HTTP 402 Payment Required` accompanied by standard payment headers (`WWW-Authenticate: x402`, recipient address, price in SYN).
2. **Settlement:** The agent creates and signs a transaction on SynapticChain L1, completing finality in under 500ms.
3. **Redemption:** The agent retries the request with `Authorization: x402 <tx_hash>`.
4. **Delivery:** The gateway validates the transaction and serves the unlocked payload.

## Quickstart
```bash
# Start Gateway
npm install
node server.js

# Run Autonomous Client Agent
node client_agent.js
```
