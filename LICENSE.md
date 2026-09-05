# SYNAPTIC PUBLIC LICENSE v1.0 (SPL-1.0)
## Defensive Patent & Commercial Governance License
**Copyright (c) 2026 Synaptics Lab & SynapticChain Contributors. All Rights Reserved.**

---

### PREAMBLE
This license ("SPL-1.0") governs the use, reproduction, distribution, and benchmarking of the SynapticChain Layer-1 Blockchain Protocol, QuantumShield Post-Quantum Security Primitives, and Universal Multi-Rail Core Runtime. This license is explicitly constructed to foster academic research, open institutional interoperability, and hackathon evaluation while providing aggressive, unconditional defense of SynapticChain's proprietary patent claims.

---

### 1. RESERVED PATENT CLAIMS
Synaptics Lab expressly retains all rights, title, interest, and international patent claims in and to the following core cryptographic and consensus inventions:

- **PATENT CLAIM 1 (CE-WOTS+):** Consensus-Enforced Winternitz One-Time Signatures ($w=16$, 67 hash chains) wherein ephemeral key-folding ($K_{\text{ephem}}$) is cryptographically bound to the ADR-062 monotonic 256-lane watermark ($\mathcal{W}_k$), invalidating spent signatures upon checkpoint inclusion and eliminating hash-chain key leakage attacks with zero post-quantum wire bloat.
- **PATENT CLAIM 2 (UNIVERSAL 5-RAIL ATOMIC ISOMORPHISM):** Zero-bridge cross-rail key derivation wherein a single 32-byte Ed25519 root seed deterministically generates isomorphic native address commitments across SynapticChain (Bech32m), Ethereum (secp256k1 Keccak-256), XRP Ledger (Base58Check), Solana (SLIP-0010 Base58), and Bitcoin (BIP-84 SegWit Bech32), orchestrated via native VM Precompiles `0x10` and `0x11` with automatic protocol fee burn.
- **PATENT CLAIM 3 (STATIC 256-LANE DAG-PRIMARY PARALLEL SCHEDULER):** Compiler-scheduled 256-lane parallel execution pipeline decoupling read/write dependency sets at compile-time and executing transactions across independent hardware lanes with sub-500ms DAG-primary finality.

---

### 2. GRANT OF RIGHTS

#### 2.1 Academic, Research & Hackathon Evaluation Grant
Subject to the terms and conditions of this License, Synaptics Lab hereby grants to any person or institution obtaining a copy of this software a royalty-free, worldwide, non-exclusive license to:
- Inspect, compile, run, benchmark, stress-test, and evaluate the software.
- Build hackathon applications, autonomous agentic microservices, and proof-of-concept integrations.
- Interoperate with SynapticChain public testnets and mainnet clusters via JSON-RPC, WebSocket, and x402 APIs.

#### 2.2 Commercial Production Covenant
Any commercial entity, state sovereign body, or institutional consortium deploying private/consortium instances of the SynapticChain validator runtime or commercializing products directly implementing Patent Claims 1, 2, or 3 must enter into an authorized Commercial Patent Covenant with Synaptics Lab.

---

### 3. DEFENSIVE PATENT TERMINATION & RETALIATION CLAUSE
**ANY RIGHT GRANTED UNDER THIS LICENSE SHALL TERMINATE IMMEDIATELY AND AUTOMATICALLY IF:**
1. The licensee, or any affiliate, directly or indirectly files, institutes, maintains, or participates in any patent infringement claim, litigation, or legal proceeding against Synaptics Lab, SynapticChain, or any of its active contributors or validator operators.
2. The licensee attempts to patent, copyright, or file proprietary IP claims over any derivation or implementation of CE-WOTS+, the 256-lane monotonic watermark scheduler, or the Universal 5-Rail Isomorphism disclosed herein.
3. The licensee deploys an unauthorized, hostile hard fork or clone of the Layer-1 protocol designed to dilute, circumvent, or appropriate SynapticChain patent covenants.

Upon termination, all rights, permissions, and licenses granted to the infringing party under this agreement are permanently revoked, and Synaptics Lab reserves all legal remedies under international patent and copyright treaties.

---

### 4. DISCLAIMER OF WARRANTY & LIMITATION OF LIABILITY
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES.

---

**Synaptics Lab Protocol Governance & IP Office**  
*Ref: SPL-1.0-DEFENSIVE-PATENT-2026*  
