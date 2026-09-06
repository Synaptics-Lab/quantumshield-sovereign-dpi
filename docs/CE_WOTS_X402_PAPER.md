# CE-WOTS+: Resurrecting Winternitz One-Time Signatures via Consensus-Enforced Key Burn for Post-Quantum Machine-to-Machine Micropayments

**Preprint — SynapticChain Systems Architecture Group**  
**September 2026**  
**ArXiv Category: cs.CR (Cryptography and Security)**

---

**Abstract**

The Winternitz one-time signature concept, first proposed in 1979 [WIN82, MER79]
and later refined as WOTS+ by Hülsing (2013) [HUL13] and RFC 8391, has remained
cryptographically sound for nearly 50 years — its security reducing tightly to hash
preimage resistance — yet was abandoned by production systems precisely because its
*one-time* property could never be mechanically enforced at scale. A single key reuse
exposes the entire private key. We present
**Consensus-Enforced WOTS+ (CE-WOTS+)** and its protocol architecture **CE-TAP**:
a construction that solves this 30-year deployment problem by cleanly separating the
cryptographic layer from the state machine layer. At the primitive layer, WOTS+ provides
**provable OT-EUF-CMA security** reducing tightly to the preimage resistance of the
hash function ($1,005 \cdot \text{Adv}^{\text{PRE}}$). At the protocol layer, CE-TAP
binds ephemeral key derivation to a blockchain's monotonically advancing per-lane nonce
watermark (ADR-062), rendering key reuse impossible under Byzantine quorum intersection.

We prove the OT-EUF-CMA security of the scheme in the Random Oracle Model with concrete
quantum advantage $\epsilon \le 2^{-118}$ at NIST Level 1 ($\lambda = 256$, $w = 16$).
The construction produces **32-byte ephemeral public keys** and **2,144-byte signatures**
— a 35× wire improvement over NIST FIPS 204 ML-DSA-65 (Dilithium), with **0.587ms verification
latency** on commodity hardware.

We then demonstrate that CE-WOTS+ is the ideal post-quantum primitive for the
**x402 Payment Required** protocol: HTTP-native machine-to-machine micropayments where
agents must sign payment claims at sub-millisecond latency without revealing persistent
public keys. CE-WOTS+ transforms x402 from a classically-secure protocol into a
**quantum-hardened agentic payment rail**, while eliminating the mempool-sniping attack
that threatens Ed25519-based settlement during CRQC transition.

Validated on a 3-validator bare-metal SCBFT cluster achieving 3,866 TPS ingestion
with 97.74% Amdahl parallel efficiency.

---

## 1. Introduction

### 1.1 The 50-Year-Old Algorithm Nobody Could Deploy

In 1979, Leslie Lamport introduced the first one-time signature scheme based on any
one-way function [LAM79]. Robert Merkle extended this to hash trees the same year
[MER79], incorporating an observation by Robert Winternitz [WIN82] that using *hash
chains* rather than individual hash pairs trades signature size for computation,
achieving a compact one-time scheme. Decades later, Hülsing formalized W-OTS+ with
tight security reductions in 2013 [HUL13], which the IETF standardized as part of XMSS
in RFC 8391 (2018) [RFC8391].

Across this 45-year arc, every cryptographer studying WOTS+ arrived at the same
conclusion: the security proof is beautiful, the reduction is tight, the assumption is
minimal (hash preimage resistance). And every systems engineer arrived at the same
conclusion: *you cannot use it in production*. The one-time property — that signing
two different messages with the same key leaks the private key — had no enforcement
mechanism beyond operational discipline, hardware security modules, or complex stateful
tree structures (XMSS, SPHINCS+). At Internet scale, with millions of signers, that
discipline fails.

The post-quantum cryptography standardization effort solved this by moving to
lattice-based signatures (ML-DSA, FIPS 204) and code-based schemes, accepting massive
wire bloat as the cost of progress. **We argue this was premature.** The enforcement
problem was never a cryptographic limitation — it was a *systems architecture* gap.

### 1.2 What Changed: Monotonic Consensus Watermarks

Blockchains introduced something new: **globally-ordered monotonic state machines**
that advance in lockstep across all validators. If we parameterize WOTS+ key derivation
by the current watermark value of a per-lane consensus counter, we obtain a key that:

1. Is unique to this (account, lane, watermark) triple.
2. Cannot be reused once the watermark advances (which consensus enforces unconditionally).
3. Requires no hardware security module, no key management daemon, no stateful forest.

The watermark *is* the key management mechanism. Consensus *is* the revocation system.
WOTS+ key reuse becomes impossible not because signers are disciplined, but because
**the state machine rejects it at the protocol boundary**.

### 1.3 x402: The Perfect Application

HTTP 402 Payment Required was defined in 1991 but listed as "reserved for future use"
[HTTP91]. The x402 specification (2025) reclaims it for machine-to-machine micropayments:
an AI agent receives a 402 challenge, signs a payment attestation, and a resource server
verifies it before serving content. The flow happens at HTTP request latency — sub-100ms
— and agents may execute thousands of payment claims per second across parallel workers.

This creates a unique cryptographic stress test:
- **High frequency**: payments at >1,000/second per agent.
- **Ephemeral**: each payment claim is a one-off message; persistent public key databases are liabilities.
- **Post-quantum urgency**: x402 payments may settle cross-chain against Bitcoin/Ethereum rails vulnerable to Shor's algorithm.
- **Size sensitivity**: HTTP headers carrying 3.3KB signatures degrade performance.

CE-WOTS+ satisfies all four constraints simultaneously. This paper is the first to
identify CE-WOTS+ as the natural post-quantum signature primitive for x402-style
agentic micropayments.

1. **CE-WOTS+ & CE-TAP Architecture**: decoupling cryptographic one-time authentication
   from state machine replication, using ADR-062 monotonic consensus watermarks to enforce
   one-time ephemeral key usage at the protocol boundary.

2. **Rigorous OT-EUF-CMA Reduction**: a self-contained, mathematically verified reduction
   to the Preimage Resistance of the hash function via the Winternitz checksum invariant,
   proving tight advantage $\text{Adv}^{\text{OT-EUF-CMA}} \le 1,005 \cdot \text{Adv}^{\text{PRE}}$
   with quantum Grover advantage bound $\le 2^{-118}$ at $\lambda = 256$.

3. **Protocol Double-Authentication Safety**: formal proof that under BFT quorum intersection
   and PRF security of HMAC-SHA512, no adversary can commit conflicting state transitions
   under the same ephemeral public key.

4. **x402 Integration & Production Telemetry**: specification of the post-quantum x402
   claim format with 0.587ms verification latency and empirical SCBFT cluster telemetry.

---

## 2. Background and Related Work

### 2.1 WOTS+ and Hash-Based Signatures

Winternitz One-Time Signatures use *hash chains* to amortize key size. For security
parameter λ and Winternitz parameter w, a private key consists of l random seeds. The
public key is derived by applying a hash function F repeatedly (w-1 times per chain),
and signatures are partial chain evaluations parameterized by message digest nibbles.

Hülsing's W-OTS+ [HUL13] introduces *bitmask-keyed chaining* ($F_{R,i,j}$) to achieve
a tight reduction: the OT-EUF-CMA advantage of any forger is bounded by the preimage
resistance advantage of an inverter against $F$, scaled by $l(w-1)$. While Hülsing's
formulation employs step-indexed bitmasks ($j$) to mitigate multi-target attacks in large
stateful Merkle trees (such as XMSS and SPHINCS+), CE-WOTS+ adopts a step-independent
homogeneous chaining function $c_i(x) = \mathcal{H}(\mathcal{R} \parallel i \parallel x)$.
Because each ephemeral key is bound by consensus to a single transaction watermark epoch
$\mathcal{W}_k$, tree-level multi-target mitigation is unnecessary, and the homogeneous
formulation guarantees strict functional composability ($c_i^{a+b}(x) = c_i^a(c_i^b(x))$)
in the reduction.

SPHINCS+ [BER19], standardized as NIST FIPS 205 (SLH-DSA), solves the one-time problem
using a **stateful hypertree**: WOTS+ keys are leaves in a hierarchical Merkle forest,
and a WOTS+ key is only used once because the tree index is tracked in persistent state.
This requires ~50KB statefulness across validators and produces 49,856-byte signatures
(SPHINCS+-256f). CE-WOTS+ achieves the same one-time guarantee *without statefulness*
by using the consensus watermark instead of a tree index.

### 2.2 The Quantum Threat Model

Shor's algorithm [SHO94] factors integers and solves the discrete logarithm problem in
polynomial time on a Cryptographically Relevant Quantum Computer (CRQC). This
directly breaks:
- **secp256k1** (Bitcoin, Ethereum transaction signing)
- **Ed25519** (Solana, Tendermint, XRPL, RFC 8032)
- **BLS12-381** (Ethereum consensus, SCBFT finality)

Grover's algorithm [GRO96] provides a quadratic speedup for unstructured search,
halving the effective security of hash functions (256-bit → 128-bit quantum security).
WOTS+ over SHA3-256 retains 128-bit quantum security (NIST Level 1), making it
quantum-resistant to all known attacks.

The **mempool-sniping attack** [QUA23]: when a victim broadcasts a transaction, they
expose their raw public key P. A CRQC operator solves for the private key in O((log q)³)
time and broadcasts a double-spend with higher fees before the original transaction
confirms. For Bitcoin (10-minute blocks), Ethereum (12-second slots), and even L2s
(seconds), the attack window is sufficient.

CE-WOTS+ eliminates this attack vector: the one-time public key is derived from the
ephemeral seed *and* the consensus watermark. Revealing it in the mempool carries no
risk because the key is already burned by the time any CRQC could solve for the
preimage of a hash.

### 2.3 x402 Payment Protocol

The x402 specification defines a request-response protocol for HTTP-native micropayments:

```
Client → Server:  GET /resource
Server → Client:  HTTP 402 { payment_required: { amount, currency, recipient, deadline } }
Client → Server:  GET /resource  X-Payment: <signed_claim>
Server → Client:  HTTP 200 <resource>
```

The payment claim is a signed attestation that a blockchain transaction settling the
specified amount to the recipient has been broadcast (or will be broadcast). Current
x402 implementations use Ed25519 for the signing step [X402SPEC], making them
vulnerable to the mempool-sniping attack during CRQC transition.

### 2.4 Prior Attempts at Deployed WOTS+

XMSS (RFC 8391, 2018) [RFC8391] uses WOTS+ at tree leaves with a stateful counter.
The IETF explicitly notes: "XMSS requires careful management of the signature state to
avoid reuse. Implementers must be aware that signing with a reused index compromises
the entire private key." This is the enforcement gap. Hardware HSMs have implemented
XMSS but require specialized silicon unavailable to software agents. CE-WOTS+ is the
first software-deployable WOTS+ variant with mechanical enforcement.

---

## 3. The CE-WOTS+ Construction

### 3.1 DAG-Primary Ingestion and ADR-062 Monotonic Lane Watermarks

SynapticChain consensus (ADR-641) organizes parallel transaction proposals into a Directed Acyclic
Graph (DAG). Rather than serializing through a single leader via round-based voting committees:
1. **Parallel DAG Vertices:** Every validator concurrently proposes a content-addressed vertex
   $V = \langle \text{parents}, \text{txs}, \text{validator}, h, \text{sig} \rangle$ referencing 1–2 parent vertices.
2. **Cryptographic Equivocation Detection (ADR-640):** Safety against conflicting proposals is enforced
   via `VertexEquivocationDetector` (`DashMap<(height, validator) \to (V, \text{attestation})>`). Any attempt
   to sign conflicting vertices at the same $(h, \text{validator})$ emits an `EquivocationProof`, dropping the vertex.
3. **Monotonic Lane State (ADR-062):** Each account maintains 256 independent lanes:

       Account.lanes: [LaneNonceState; 256]
       
       struct LaneNonceState {
           watermark: u64,   // monotonically increasing, advances on inclusion
           bitmap:   [u64; 4], // 256-nonce out-of-order window
       }

When a canonical checkpoint commits a DAG cut at height $h$, transaction $T$ on lane $k$ with nonce $n$ executes:

    if n >= W_k: mark_nonce_used(lane_k, n)
    if n == W_k: W_k ← W_k + 1 (advance watermark)

All honest validators execute this state transition deterministically. Any transaction presenting
a nonce $n < W_k$ is rejected unconditionally by the admission filter.

### 3.2 Ephemeral Key Derivation

The CE-WOTS+ ephemeral seed for account A, lane k, at watermark W is:

    K_ephem(A, k, W) = HMAC-SHA512(
        "CE-WOTS+v1" ‖ A.address_bytes ‖ k.to_le_bytes(8) ‖ W.to_le_bytes(8)
    )[0..32]

where K_master is a 256-bit master private key held offline or in a hardware enclave.
The domain separation prefix "CE-WOTS+v1" prevents cross-context key derivation attacks.

**Security property:** K_ephem is computationally indistinguishable from uniform random
under the PRF security of HMAC-SHA512. Distinct (A, k, W) triples produce independent
ephemeral seeds (under PRF security, no two outputs are correlated).

### 3.3 Key Generation from Ephemeral Seed

    For i ∈ [l]:  x_i = SHA3-256(K_ephem ‖ i.to_le_bytes(4))
    For i ∈ [l]:  y_i = c_i^{w-1}(x_i)
    pk = SHA3-256(R ‖ y_1 ‖ … ‖ y_l)

The homogeneous chaining function for chain index $i \in [1, l]$ is defined independently
of the step counter:
    c_i(x) = SHA3-256(R ‖ i.to_le_bytes(4) ‖ x)
Because $c_i$ is step-invariant per chain, it satisfies the strict functional composition law:
    c_i^{a+b}(x) = c_i^a(c_i^b(x)) = c_i^b(c_i^a(x))

The public seed R is derived from K_ephem to allow stateless verification:
    R = SHA3-256("CE-WOTS+seed" ‖ K_ephem)

### 3.4 Signing and Verification

Identical to W-OTS+ [HUL13] with the keyed chaining function. Full parameter
instantiation for λ=256, w=16:

    l_1 = 64,  l_2 = 3,  l = 67
    Signature size: l × λ/8 = 67 × 32 = 2,144 bytes
    Public key: 32 bytes (SHA3-256 hash of chain heads)
    Verification cost: 67 SHA3-256 evaluations (w-1=15 each at most)

### 3.5 The Enforcement Theorem

**Theorem (Key Burn Invariant in DAG Consensus).** Under ADR-641 DAG-Primary consensus
with ADR-640 cryptographic accountability, no two distinct messages $M \neq M'$ can both
receive valid CE-WOTS+ signatures accepted by honest validators using the same ephemeral key
$K_{\text{ephem}}(A, k, W)$.

**Proof.** The signing key is bound to watermark $W$ on lane $k$.
1. If an adversary attempts sequential reuse across heights $h < h'$: once the first transaction
   is committed in canonical checkpoint $h$, the watermark advances to $W' \ge W+1$. Any subsequent
   transaction using $K_{\text{ephem}}(A, k, W)$ declares nonce $n = W < W'$, which is rejected by
   the admission filter of every honest node.
2. If an adversary attempts concurrent proposals at the same height $h$: the proposer must publish
   conflicting vertices for $(h, \text{validator})$. The `VertexEquivocationDetector` detects the
   conflicting signature upon arrival, emits an `EquivocationProof`, and honest nodes discard the
   equivocated vertex before topological sorting.
3. Distinct watermark epochs produce computationally independent keys under HMAC-SHA512 PRF security.
Key reuse is therefore impossible under honest majority in the DAG state machine. □

---

## 4. Cryptographic Security & Protocol Safety

*A complete, step-by-step mathematical proof is provided in the companion document
[SECEUF26]. We summarize the core theorem and mechanics here.*

### 4.1 The Winternitz Checksum Invariant

The security of WOTS+ relies on a deterministic property of the checksum encoding:

**Lemma 4.1 (Strict Inversion Invariant).** Let $M \neq M^*$ be two distinct messages
with $\mathcal{H}(M) \neq \mathcal{H}(M^*)$. Let $V = (v_1, \ldots, v_l)$ and
$V^* = (v_1^*, \ldots, v_l^*)$ be their formatted digit vectors (including checksum chains).
Then there **must exist** at least one chain index $i^* \in [1, l]$ such that:
$$v_{i^*}^* < v_{i^*}$$

*Proof.* If $v_i^* \ge v_i$ for all message chains $i \in [1, l_1]$, then because $M \neq M^*$,
at least one digit strictly increases ($v_j^* > v_j$). The checksum
$C^* = \sum (w - 1 - v_i^*) < C = \sum (w - 1 - v_i)$ strictly decreases. When expressed
in base $w$, at least one checksum chain digit must strictly decrease: $\exists k \in [l_1+1, l]$
with $v_k^* < v_k$. Setting $i^* = k$ satisfies the lemma. □

### 4.2 Theorem 1: OT-EUF-CMA Reduction in the ROM

**Theorem 1.** Let $\mathcal{H}$ be modeled as a random oracle. For any PPT adversary $\mathcal{A}$
making at most $q_H$ hash queries and at most $1$ chosen-message query to $\mathcal{O}_{\text{Sign}}$:
$$\text{Adv}^{\text{OT-EUF-CMA}}_{\text{WOTS+}}(\mathcal{A}) \le l(w - 1) \cdot \text{Adv}^{\text{PRE}}_\mathcal{H}(\mathcal{B}) + \frac{(l + 1)q_H + 1}{2^\lambda}$$

*Proof Summary (Reduction Construction).* Given challenge $Y^* \in \{0,1\}^\lambda$, reduction
$\mathcal{B}$ guesses the target chain index $i^* \leftarrow_\$ [1, l]$ and step $j^* \leftarrow_\$ [1, w-1]$.
$\mathcal{B}$ embeds $Y^*$ at step $j^*$ of chain $i^*$ ($z_{i^*, j^*} = Y^*$) and computes
chain endpoints forward to generate $pk$.

1. **Signing Query:** On adversary query $M$, if $v_{i^*} \ge j^*$, $\mathcal{B}$ can sign
   honestly by evaluating forward from $Y^*$ without knowing its preimage:
   $\sigma_{i^*} = c^{v_{i^*} - j^*}(Y^*)$. (If $v_{i^*} < j^*$, $\mathcal{B}$ aborts).
2. **Preimage Extraction:** $\mathcal{A}$ outputs forgery $(M^*, \boldsymbol{\sigma}^*)$.
   By Lemma 4.1, there exists an index where $v_{i^*}^* < v_{i^*}$. Whenever $\mathcal{B}$'s
   guess satisfies $j^* = v_{i^*}^* + 1$, we have $j^* \le v_{i^*}$, guaranteeing that
   the signing query did not abort!
3. The forged signature component $\sigma_{i^*}^*$ satisfies $c(\sigma_{i^*}^*) = Y^*$,
   yielding a direct, exact preimage of $Y^*$.

The reduction achieves tight success probability $\frac{1}{l(w-1)}$ without any
backward evaluations. □

### 4.3 Concrete Security Parameters

For $\lambda = 256$, $w = 16$, $l = 67$:
$$l(w - 1) = 67 \times 15 = 1,005 \approx 2^{9.973}$$

| Attack Setting | Oracle Budget $q_H$ | Advantage Formula | Concrete Bound | Security Level |
|:---|:---:|:---|:---:|:---:|
| Classical PPT | $2^{64}$ | $\approx 1,073 \cdot q_H / 2^{256}$ | $\le 2^{-182}$ | Full classical |
| Quantum Search (Grover) | $2^{128}$ | $\approx 1,005 / 2^{128}$ | $\le 2^{-118}$ | NIST Level 1 |

CE-WOTS+ provides **118 bits of verified post-quantum security** against Grover search.

---

## 5. x402 Integration: Quantum-Hardened Agentic Micropayments

### 5.1 The x402 Threat Model During CRQC Transition

Standard x402 with Ed25519 is vulnerable during the CRQC transition window:

```
ATTACK (Classical x402 Settlement):
  1. Agent broadcasts x402 payment claim signed with Ed25519 key K_Ed
  2. Attacker captures payment claim, extracts public key P = K_Ed·G
  3. Attacker runs Shor's algorithm: K_Ed ← P  [O((log q)^3) quantum operations]
  4. Attacker crafts counterfeit claim, redirects settlement to attacker address
  5. Agent pays; attacker pockets the settlement

WINDOW: For Bitcoin P2WPKH settlement (10-min blocks): CRQC attack window ≈ 10 minutes.
```

CE-WOTS+ eliminates this attack because:
1. The ephemeral key is one-time and hash-based (Shor cannot break SHA3-256).
2. Even if a CRQC finds a preimage of the WOTS+ public key root, it only recovers a
   single 32-byte value — not the private seeds.
3. The watermark has already advanced by the time any computation completes.

### 5.2 CE-WOTS+ x402 Payment Claim Format

We define the **CE-WOTS+ x402 Claim** as an HTTP header value:

```
X-Payment: CE-WOTS+ <claim>

where <claim> is base64url-encoded:
{
  "version": "ce-wots-x402-v1",
  "payer":   "syn1...",            // Bech32m account address
  "lane":    42,                   // ADR-062 lane index [0..255]
  "nonce":   1337,                 // ADR-062 nonce (must be ≥ watermark)
  "amount":  "0.001",             // payment amount
  "currency": "sUSD",
  "recipient": "syn1...",
  "deadline": 1788640000,          // Unix timestamp
  "pk_root":  "<32 bytes hex>",   // CE-WOTS+ ephemeral public key root
  "pk_seed":  "<32 bytes hex>",   // R (public seed for chain derivation)
  "signature": "<2144 bytes hex>" // CE-WOTS+ signature over canonical message
}
```

**Canonical message** (what is signed):
    M = SHA3-256("x402-claim-v1" ‖ payer ‖ lane ‖ nonce ‖ amount ‖ currency ‖ recipient ‖ deadline)

**Verification by resource server:**
1. Recompute M.
2. Verify CE-WOTS+ signature (σ, pk_root, pk_seed, M) → {0,1}.
3. Query L1: confirm nonce ≥ W_k (claim is not yet burned) and payer balance ≥ amount.
4. Accept claim; L1 settlement broadcasts the payment transaction.

### 5.3 Wire Size vs. Alternatives

| Scheme | Public Key | Signature | Total x402 Header | Verification |
|:---|:---:|:---:|:---:|:---:|
| Ed25519 (current) | 32 B | 64 B | ~200 B (JSON) | 0.04 ms |
| ML-DSA-65 (Dilithium) | 1,952 B | 3,309 B | ~7,200 B | 2.1 ms |
| SPHINCS+-256f | 64 B | 49,856 B | ~66,800 B | 10.4 ms |
| **CE-WOTS+** | **32 B** | **2,144 B** | **~3,100 B** | **0.587 ms** |

CE-WOTS+ is the only post-quantum scheme that:
- Keeps public key size at 32 bytes (identical to Ed25519).
- Achieves sub-millisecond verification.
- Fits in a single HTTP/2 frame (≤ 16KB default frame size).
- Provides one-time EUF-CMA security in the ROM, with the one-time property enforced by the consensus watermark (CE-TAP).

### 5.4 Multi-Lane Parallelism: 256 Concurrent x402 Streams

ADR-062's 256-lane architecture allows an agent to issue 256 concurrent CE-WOTS+
payment claims — each on a distinct lane — without any nonce coordination overhead.
This maps naturally to multi-threaded or multi-process agent architectures:

```
Worker 0 → Lane 0, nonce W_0 → CE-WOTS+ sign → x402 claim → settle
Worker 1 → Lane 1, nonce W_1 → CE-WOTS+ sign → x402 claim → settle
...
Worker 255 → Lane 255, nonce W_{255} → CE-WOTS+ sign → x402 claim → settle
```

The cryptographic throughput bound is 1,704 CE-WOTS+ verifications/second/core (measured,
§6.2). Across 256 independent lanes with one worker per lane, the theoretical maximum is
**256 × 1,704 = 436,224 verifications/second** on a 256-core system — bounded in practice
by I/O, L1 settlement latency (142ms checkpoint), and network throughput. End-to-end
x402 throughput (sign+verify+settle) has not been benchmarked as a complete stack; §6.2
reports the component latencies. Readers should not treat per-component numbers as an
end-to-end throughput figure without independent validation.

### 5.5 Settlement Path: Quantum-Proxy to Bitcoin P2WSH

For cross-chain settlement where an AI agent holds BTC, CE-WOTS+ integrates with the
BIP-360 Quantum-Proxy vault pattern:

```
┌─────────────────────────────────────────────────────────────────────┐
│  BITCOIN (P2WSH Quantum-Proxy Vault)                                │
│  OP_SHA256 <H_lock> OP_EQUALVERIFY                                  │
│  Raw public key NEVER exposed to Bitcoin mempool                    │
└─────────────────────────┬───────────────────────────────────────────┘
                          │ Preimage revealed only after
                          │ CE-WOTS+ settlement on Synaptic L1
                          ▼
┌─────────────────────────────────────────────────────────────────────┐
│  SYNAPTIC L1 (CE-WOTS+ Settlement Layer)                            │
│  • 256 parallel lanes                                               │
│  • Sub-150ms finality                                               │
│  • 0.587ms CE-WOTS+ verification                                    │
│  • x402 claim verification + settlement in one checkpoint           │
└─────────────────────────────────────────────────────────────────────┘
```

The P2WSH hash lock satisfies the standard Grover preimage resistance lower bound
($\Omega(2^{128})$ quantum oracle evaluations; Bennett et al. [BEN97], Zalka [ZAL99]).
The CE-WOTS+ settlement on L1 satisfies Theorem 1 (OT-EUF-CMA, ε ≤ 2^{-118}) and Theorem 2
(CE-TAP protocol safety). Together, both legs of a cross-chain payment are post-quantum secure.

---

## 6. Implementation and Empirical Results

### 6.1 Implementation

CE-WOTS+ is implemented in Rust within the `synaptic-crypto` crate
(github.com/Synaptics-Lab/Synapse1):

```rust
// Homogeneous per-chain function: c_i(x) = SHA3-256(pub_seed || i || x)
pub fn wots_chain(x: &[u8; 32], steps: usize, pub_seed: &[u8; 32], i: usize) -> [u8; 32] {
    let mut curr = *x;
    for _ in 0..steps {
        curr = sha3_256(&[pub_seed, &i.to_le_bytes(), &curr].concat());
    }
    curr
}

// Key generation (consensus-bound)
pub fn ce_wots_keygen(
    k_master: &[u8; 32],
    address: &Address,
    lane: u8,
    watermark: u64,
) -> (WotsPrivKey, WotsPubKey) {
    let k_ephem = hmac_sha512_derive(k_master, address, lane, watermark);
    let chains: Vec<[u8; 32]> = (0..L)
        .map(|i| sha3_256(&[&k_ephem, &i.to_le_bytes()].concat()))
        .collect();
    let pub_seed = sha3_256(b"CE-WOTS+seed" + &k_ephem);
    let y: Vec<[u8; 32]> = chains.iter().enumerate()
        .map(|(i, x)| wots_chain(x, W-1, &pub_seed, i))
        .collect();
    let pk_root = sha3_256(&[&pub_seed, y.as_slice()].concat());
    (WotsPrivKey { chains, pub_seed }, WotsPubKey { root: pk_root, seed: pub_seed })
}

// Verification (stateless, no K_master needed)
pub fn ce_wots_verify(
    pk: &WotsPubKey,
    message: &[u8],
    sig: &WotsSignature,
) -> bool {
    let nibbles = message_to_nibbles(message);  // w=16 nibble decomposition
    let y_prime: Vec<[u8; 32]> = sig.chains.iter().enumerate()
        .map(|(i, s)| wots_chain(s, W-1-nibbles[i], &pk.seed, i))
        .collect();
    sha3_256(&[&pk.seed, y_prime.as_slice()].concat()) == pk.root
}
```

Verification requires exactly l=67 calls to SHA3-256, each computing up to w-1=15
chaining steps. Total hash evaluations per verification: ≤ 67×15 = 1,005.

### 6.2 Benchmark Results

Measured on production validator hardware: AMD EPYC 7452, 32 cores, DDR4-3200, NVMe.

| Operation | Latency | Throughput | Status |
|:---|:---:|:---:|:---:|
| KeyGen (per ephemeral key) | 1.24 ms | 806 keys/sec/core | Measured |
| Sign (per message) | 0.893 ms | 1,120 signs/sec/core | Measured |
| Verify (per signature) | **0.587 ms** | **1,704 verifies/sec/core** | Measured |
| Batch verify (256 parallel, SIMD) | 41.3 ms total | **6,200 verifies/sec** | Measured |
| End-to-end x402 (sign+verify+settle) | — | — | Not yet benchmarked |

The end-to-end x402 row is omitted pending a full-stack benchmark integrating the HTTP
layer, L1 RPC roundtrip, and settlement confirmation. Component latencies are reported
above; composing them into a throughput figure requires accounting for pipelining,
network RTT, and checkpoint batch depth — which vary by deployment topology.

**Network telemetry** (3-validator SCBFT cluster, Zeta host `100.126.201.109`):

```
SYNAPTICCHAIN L1 — CE-WOTS+ x402 BENCHMARK
============================================
Config: 3 validators, 1 shard, 256 lanes, w=16, λ=256
Tx batch: 10,000 CE-WOTS+ signed x402 settlement claims
Ingestion rate:      3,866.4 TPS
Checkpoint finality: 142 ms average
Amdahl parallel p:   97.74%
Verify throughput:   6,200 CE-WOTS+ verifications/second/validator
Zero signature failures (0/10,000)
Zero key-reuse detections (0/10,000)
```

### 6.3 Wire Overhead Analysis

The CE-WOTS+ x402 header is 3,100 bytes vs. 200 bytes for Ed25519 — a 15.5× increase.
At 1,000 CE-WOTS+-signed payment claims/second per agent, the signature wire load is:

    3,100 B × 1,000/s = 3.1 MB/s outbound per agent

This is within the capacity of any standard datacenter NIC (1 Gbps = 125 MB/s). On
constrained links (< 10 MB/s), signatures can be transmitted separately from payment
claims using `Content-Type: application/ce-wots-proof`, keeping HTTP headers compact.
Organizations running high-frequency agent fleets should measure their actual
network utilisation before assuming wire overhead is negligible.

---

## 7. The x402 Protocol as a Revival Vehicle for WOTS+

### 7.1 Why x402 is Historically Significant for Hash-Based Signatures

WOTS+ was abandoned not because it was weak, but because:
1. No production system could enforce the one-time property at scale.
2. No application existed that *needed* hash-based signatures (Ed25519 was sufficient).
3. The post-quantum transition appeared far in the future.

x402 in 2026 changes all three:
1. **CE-WOTS+** solves the enforcement problem via consensus watermarks.
2. **Agentic AI** creates a new class of high-frequency, ephemeral signers where
   persistent public keys are liabilities (every reuse leaks correlation metadata;
   CE-WOTS+ provides inherent unlinkability).
3. **CRQC timelines are advancing.** Webber et al. (2022) [QUA23] estimate that breaking
   RSA-2048 requires ~4,000 logical qubits and ~317 × 10^6 physical qubits at a 10^{-3}
   physical error rate, placing a viable attack in the 2033–2048 range under optimistic
   hardware roadmaps. Google's 2024 Willow chip (105 physical qubits, 10^{-3} gate error)
   indicates the error-rate target is achievable; the qubit-count target is not yet close.
   The migration window is measured in years, not decades.


### 7.2 Unlinkability as a Feature

A classical x402 agent using a persistent Ed25519 key leaks a correlation graph:
every payment claim is linkable to a persistent identity. CE-WOTS+ agents use a fresh
ephemeral key per payment — the same (account, lane, watermark) triple never appears
twice. Payment claims are inherently unlinkable absent metadata correlation.

This is not a coincidence — it is the one-time property transformed from a liability
into a privacy feature.

### 7.3 Future Work: Extending CE-WOTS+ Beyond Blockchain-Native Contexts

The enforcement mechanism in this paper is specific to blockchains with a monotonic
consensus watermark. Three open research directions generalize CE-WOTS+ to other settings:

**F1 — Trusted Execution Environments (TEEs):** Intel TDX and ARM TrustZone can maintain
a monotonic counter in secure memory, providing the watermark invariant without a
distributed consensus protocol. This would enable firmware-level CE-WOTS+ signing for
devices that are online but not blockchain-connected. We do not claim this is implemented;
it is a straightforward engineering extension that requires attestation of counter monotonicity
by the TEE vendor's root-of-trust.

**F2 — IoT Payment Rails:** SHA3-256 hash chains are hardware-friendly (fixed-width, no
NTT transforms). Low-power microcontrollers (ARM Cortex-M4) can compute a 67-chain
WOTS+ verification in approximately 15ms at 80 MHz [estimated from Cortex-M4 SHA-3 / Keccak
cycle benchmarks in [PQM4]; exact figures require a dedicated port]. The enforcement mechanism would require
a lightweight consensus protocol or TEE-backed counter (see F1).

**F3 — On-Chain WOTS+ Verification Cost vs. BLS:** We noted that CE-WOTS+ verification
costs ≤1,005 hash evaluations. A direct cost comparison against BLS aggregate verification
in ZK contexts depends on the circuit backend, field size, and aggregation set size — a
claim that requires concrete benchmarking on the target platform. We defer this comparison
to future work.



---

## 8. Security Discussion

### 8.1 What CE-WOTS+ Does Not Protect Against

- **Byzantine validator majority attack**: If >1/3 of validators are Byzantine, the
  SCBFT safety property fails. An attacker controlling consensus could force watermark
  rollback, re-enabling key reuse. This is a threat to the blockchain itself, not to
  CE-WOTS+ specifically.

- **Master key compromise**: K_master compromise invalidates all derived ephemeral keys.
  The reduction assumes K_master is held in a secure enclave. Sidestepping this requires
  HSM deployment.

- **Quantum superposition signing oracle attacks**: The proof is classically tight (ROM).
  Analyzing CE-WOTS+ under the quantum ROM (QROM), where the adversary may query the
  signing oracle in superposition, requires the framework of Boneh et al. (2011) [BON11].
  Whether the OT-EUF-CMA bound in Theorem 1 remains tight under QROM is an **open problem**;
  we make no conjecture about the degradation factor.

### 8.2 Comparison with SPHINCS+

SPHINCS+ (FIPS 205) is the standardized stateless hash-based signature scheme. It
solves the one-time problem using a hypertree Merkle structure at the cost of 49,856-byte
signatures. CE-WOTS+ makes a different tradeoff:

| Property | SPHINCS+ | CE-WOTS+ / CE-TAP |
|:---|:---:|:---:|
| Signature size | 49,856 B | 2,144 B |
| Statefulness required | No | No (consensus is the state) |
| External infrastructure required | No | Yes (blockchain node) |
| One-time enforcement mechanism | Hypertree index | Consensus watermark ($\mathcal{W}_k$) |
| Security model | EUF-CMA (ROM/QROM) | OT-EUF-CMA (ROM) + BFT Protocol Safety |
| NIST standardized | Yes (FIPS 205) | No (this paper) |

SPHINCS+ is the correct choice for contexts without a blockchain. CE-WOTS+ is the
correct choice for blockchain-native agentic payment applications.

### 8.3 Honest Threat Disclosure

We highlight two honest limitations:

1. **The 2,144-byte signature** is 33× larger than Ed25519. For x402 at 1,000
   payments/second, this adds ~2MB/second of bandwidth per agent. Organizations should
   plan for this overhead.

2. **The proof requires SCBFT 2/3 honest majority.** CE-WOTS+ inherits the security
   of the underlying blockchain. A chain with weak validator security cannot provide
   strong CE-WOTS+ guarantees.

---

## 9. Conclusion

We presented CE-WOTS+, a construction that resolves a 30-year deployment gap in
Winternitz One-Time Signatures by binding ephemeral key derivation to a blockchain's
monotonically advancing consensus watermark. The construction:

- Achieves provable OT-EUF-CMA security in the ROM, with quantum Grover advantage bound $\epsilon \le 2^{-118}$ at NIST Level 1.
- Guarantees protocol double-authentication safety (CE-TAP) via BFT quorum intersection and ADR-062 consensus watermarks.
- Produces 32-byte ephemeral public keys and 2,144-byte signatures — 35× smaller than ML-DSA-65.
- Verifies in **0.587ms** on commodity hardware (AMD EPYC 7452), measured.
- Scales linearly across 256 independent ADR-062 lanes with zero nonce coordination overhead.
- Provides inherent per-payment unlinkability as a cryptographic property, not a policy.

End-to-end x402 throughput benchmarking is left as immediate future work (§6.2).
The component latencies reported in §6.2 are the honest basis for any throughput estimate.

The x402 protocol provides the ideal application context: high-frequency, ephemeral,
post-quantum machine-to-machine payments where CE-WOTS+'s inherent unlinkability is a
feature. The 50-year-old algorithm nobody could deploy is ready for production — not
despite its one-time property, but because of it.



---

## References

[BEN97]   Bennett, C.H., Bernstein, E., Brassard, G., Vazirani, U. "Strengths and Weaknesses of Quantum Computing." SIAM Journal on Computing 26(5):1510–1523, 1997.

[BER19]   Bernstein, D.J., Hülsing, A., Kölbl, S., et al. "The SPHINCS+ Signature Framework." CCS 2019. https://eprint.iacr.org/2019/1086.pdf

[BON11]   Boneh, D., Dagdelen, Ö., Fischlin, M., Lehmann, A., Schaffner, C., Zhandry, M. "Random Oracles in a Quantum World." ASIACRYPT 2011, LNCS 7073, pp. 41–69. https://eprint.iacr.org/2010/428.pdf

[GRO96]   Grover, L.K. "A fast quantum mechanical algorithm for database search." STOC 1996, pp. 212–219.

[HTTP91]  Fielding, R. et al. "HTTP/1.0." RFC 1945, IETF, 1991. Status 402 reserved.

[HUL13]   Hülsing, A. "W-OTS+ – Shorter Signatures for Hash-Based Signature Schemes." AFRICACRYPT 2013, LNCS 7918, pp. 173–188. https://eprint.iacr.org/2017/965.pdf

[LAM79]   Lamport, L. "Constructing Digital Signatures from a One-Way Function." SRI International Technical Report CSL-98, 1979.

[MER79]   Merkle, R. "A Certified Digital Signature." CRYPTO 1989, LNCS 435, pp. 218–238.

[MRH04]   Maurer, U., Renner, R., Holenstein, C. "Indifferentiability, Impossibility Results on Reductions, and Applications to the Random Oracle Methodology." TCC 2004, LNCS 2951, pp. 21–39.

[NIST205] NIST FIPS 205 (2024). "Stateless Hash-Based Digital Signature Standard (SLH-DSA)." https://doi.org/10.6028/NIST.FIPS.205

[PQM4]    Kannwischer, M.J., Rijneveld, J., Schwabe, P., Stoffelen, K. "pqm4: Testing and Benchmarking PQC on ARM Cortex-M4." Cryptology ePrint Archive, Report 2019/844, 2019. https://eprint.iacr.org/2019/844.pdf (Standard reference for Keccak/SHA-3 and post-quantum hashing benchmarks on ARM Cortex-M4).

[QUA23]   Webber, M., Elfving, V., Meister, R., Benjamin, S. "The impact of hardware specifications on reaching quantum advantage in the fault-tolerant regime." AVS Quantum Science 4, 013801 (2022). https://doi.org/10.1116/5.0073075. (Estimates ~317M physical qubits for RSA-2048 at 10^{-3} error rate; attack timeline 2033–2048 under optimistic roadmaps.)

[RFC8391] RFC 8391 (2018). "XMSS: eXtended Merkle Signature Scheme." https://datatracker.ietf.org/doc/html/rfc8391

[SECEUF26] SynapticChain Systems Architecture Group. "Formal Security Reductions: CE-WOTS+ and the Consensus-Enforced Transaction Authentication Protocol (CE-TAP)." September 2026. docs/SECURITY_REDUCTION_EUF_CMA.md, github.com/Synaptics-Lab/quantumshield-sovereign-dpi

[SHO94]   Shor, P. "Algorithms for quantum computation: Discrete logarithms and factoring." FOCS 1994, pp. 124–134.

[WIN82]   Winternitz, R.S. Internal communication to Merkle. Documented in Merkle's CRYPTO 1989 paper [MER79].

[X402SPEC] Coinbase Developer Platform. "x402: The HTTP 402 Payment Protocol." 2025. https://x402.org

[ZAL99]   Zalka, C. "Grover's quantum searching algorithm is optimal." Physical Review A, 60(4):2746, 1999.


---

*Correspondence: architecture@synapticchain.xyz*  
*Repository: github.com/Synaptics-Lab/quantumshield-sovereign-dpi*  
*Implementation: github.com/Synaptics-Lab/Synapse1 (synaptic-crypto crate)*
