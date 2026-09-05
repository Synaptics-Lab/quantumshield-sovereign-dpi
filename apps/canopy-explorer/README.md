# Canopy Evergreen Block Explorer

> **Design System:** Canopy Evergreen (Mist `#F2F6F2`, Pine `#0D2B24`, Fern `#1E7A5C`, Rice `#B9E04C`)  
> **Architecture:** Zero-Dependency Single Page Application (SPA) with Real-Time JSON-RPC Telemetry

## Overview
The Canopy Evergreen Explorer is the official network telemetry and block inspector for SynapticChain Layer-1. Built with zero external framework overhead (no React/Next.js hydration delays, zero database dependencies), it interfaces directly with the SynapticChain node JSON-RPC and WebSocket firehose.

## Key Features
- **Deterministic SPA Navigation:** Seamless client-side routing across Overview, Checkpoints, Validators, Sovereign DPI, Quantum Defense, and AgentFi without page reloads.
- **Live SCBFT Consensus Visualizer:** Real-time checkpoint height, DAG commit latency, transaction counts, and validator quorum state.
- **Sovereign Contract Registry:** Direct links to on-chain contracts, central bank vaults, and token contracts.
- **Public Endpoints:** Configured to point to the live testnet (`https://nodes.synapticchain.xyz/rpc`).

## Running Locally
Open `index.html` in any browser or serve via HTTP:
```bash
python3 -m http.server 3000 --directory .
```
