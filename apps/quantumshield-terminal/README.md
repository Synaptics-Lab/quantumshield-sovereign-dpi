# QuantumShield Terminal Wallet

> **Design System:** Canopy Evergreen (Spatial Light Mode · Zero Dark Mode)  
> **Architecture:** Zero-Dependency Institutional Web4 Terminal

## Overview
QuantumShield is an institutional-grade sovereign terminal wallet built for high-throughput public finance and treasury operations. Unlike consumer Web3 extension wallets, QuantumShield provides a hardware-inspired spatial operating console designed for central banks, autonomous agent operators, and institutional liquidity managers.

## Key Capabilities
- **Universal 5-Rail Key Isomorphism:** Derives native cryptographic addresses for SynapticChain, Ethereum, XRP Ledger, Solana, and Bitcoin Native SegWit from a single 32-byte master seed without custodial bridges.
- **CE-WOTS+ Quantum Defense:** Simulates and validates Consensus-Enforced Winternitz One-Time Signatures ($w=16$, 67 hash chains) bound to monotonic lane watermarks to eliminate quantum-computer signature forgery.
- **256-Lane Concurrency Matrix:** Live visual matrix displaying independent transaction watermarks across all 256 execution lanes.
- **ZRA Automated Tax Terminal:** Direct interface to the 0.50% statutory revenue-split router.
- **x402 Micropayment Tester:** Built-in tool to generate and verify RFC 9110 HTTP 402 payment headers.

## Running Locally
Open `index.html` in any modern web browser or serve via HTTP:
```bash
python3 -m http.server 3001 --directory .
```
