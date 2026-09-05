# Smart Contracts & Deployed Address Registry

> **Language:** SynapticLang (`.syn`)  
> **Target Runtime:** SynapticVM (Parallel execution via static dependency schedules)

## Core Contract Architecture

| Contract | File | Purpose | Live Testnet Address |
|---|---|---|---|
| **GovPayZMWToken** | [`GovPayZMWToken.syn`](./GovPayZMWToken.syn) | National currency digital token standard (SRC-20) | `syn1dj2a3nlrc44lqtwzeg9ws0d6plzeayrmxy98m2` |
| **ZraSplitRouter** | [`ZraSplitRouter.syn`](./ZraSplitRouter.syn) | Automated 0.50% statutory revenue deduction to TSA | `syn122h32ja44hhz8ut543krjrrzz9jkd8lxw3m9f7` |
| **SynIdentityNFT** | [`SynIdentityNFT.syn`](./SynIdentityNFT.syn) | INRIS W3C biometric soulbound identity credential | `syn1zy8dsuvpc7mt6m8lnp7ueeq808a49q6xmef06l` |
| **ISO20022Payment** | [`ISO20022Payment.syn`](./ISO20022Payment.syn) | Pacs.008 RTGS commercial bank settlement router | `syn1kf0wmhqzwy649a67cv5kaapyt3pl4cga9cyuku` |
| **AtomicRouter** | [`AtomicRouter.syn`](./AtomicRouter.syn) | 5-Rail cross-rail atomic hash-time-lock routing | `syn15wcyqdzktwwgn0j76cau74hgcav68hxn7tzrpv` |

## Sovereign Treasury & Reserve Accounts
- **Bank of Zambia (BoZ) Reserve Vault:** `syn1r5vkuqaxss46uruj6c5k5wrnzxg04htpuylynr` (Holds **150,000,000 ZMW** backed sovereign reserve)
- **ZRA Single Treasury Account (TSA):** `syn1t9hp790tpp450jh0sd8lyd3znqccycal4m2z0u`
- **Ambient Flow-Bot Execution Ring:** 6 on-chain merchant and citizen simulation accounts actively settling tax-split transactions.

## Developer Documentation & Primers
- **[SynapticLang Developer Primer](../docs/SYNAPTICLANG_HACKATHON_PRIMER.md):** Language specification, syntax, storage annotations, types, branchless design, and verified compiler workarounds.
- **[Contract Compile & Deploy Guide](../docs/CONTRACT_COMPILE_AND_DEPLOY_GUIDE.md):** Step-by-step runbook for `synlang compile`, gas estimation, deployment via CLI/SDK/RPC, `init()` state initialization, and on-chain verification.

## Machine-Readable ABIs
JSON ABIs for client integrations are located under [`contracts/abi/`](./abi/).
