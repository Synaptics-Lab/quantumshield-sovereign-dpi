# Cryptographic & Protocol Technical Specification

```
========================================================================================
  QUANTUMSHIELD™ CRYPTOGRAPHIC PROTOCOL SPECIFICATION
  Ref: BIP-360 / NIST SP 800-208 / ADR-062 Monotonic Watermark Folding
========================================================================================
```

---

## 1. Consensus-Enforced Winternitz Signatures (CE-WOTS+)

### 1.1 Parameterization
- **Base:** $w = 16$ (nibble decomposition, 4 bits per step)
- **Message Length:** 32 bytes (256 bits) $\to l_1 = 64$ digits
- **Checksum:** $C = \sum_{i=1}^{64} (15 - d_i) \le 64 \times 15 = 960$
- **Checksum Digits:** $\lceil \log_{16}(960) \rceil = 3$ digits $\to l_2 = 3$
- **Total Hash Chains:** $l = l_1 + l_2 = 67$ chains
- **Signature Size:** $67 \times 32 = 2,144$ bytes uncompressed

### 1.2 Hash Chain Function
Let $H: \{0,1\}^* \to \{0,1\}^{256}$ be SHA-256. For chain index $i \in [0, 66]$ and secret seed $S$:
$$SK_i = H(S \parallel i_{32})$$
$$PK_i = H^{15}(SK_i)$$

### 1.3 Signing
Given message hash $M \in \{0,1\}^{256}$, parse $M$ into 64 4-bit nibbles $(d_1, \dots, d_{64})$. Compute checksum $C$ and append 3 nibbles $(d_{65}, d_{66}, d_{67})$.
$$\sigma_i = H^{d_i}(SK_i) \quad \text{for } i \in [0, 66]$$

### 1.4 Verification
$$\text{Verify}(\sigma, M) \iff H^{15 - d_i}(\sigma_i) == PK_i \quad \forall i \in [0, 66]$$

### 1.5 ADR-062 Watermark Folding (Key Reuse Defense)
To prevent classical WOTS hash-chain signature forgery upon key reuse:
$$\mathcal{K}_{\text{folded}} = H\left( \bigoplus_{i=0}^{66} PK_i \parallel \mathcal{W}_k \right)$$
Where $\mathcal{W}_k$ is the monotonic watermark of execution lane $k \in [0, 255]$. Any attempt to reuse a signature with an advanced watermark fails consensus verification at the VM layer.

---

## 2. Universal 5-Rail Isomorphism

Let $S_{\text{master}} \in \{0,1\}^{256}$ be the 32-byte master seed. The protocol defines an isomorphic projection $\Phi(S_{\text{master}}) \to (\text{SYN}, \text{ETH}, \text{XRP}, \text{SOL}, \text{BTC})$:

1. **Master Expansion:**
   $$\mathcal{H} = \text{SHA256}(S_{\text{master}})$$
2. **SynapticChain L1:**
   $$\text{Addr}_{\text{SYN}} = \text{bech32m}("syn", \text{SHA3-256}(\mathcal{H})_{0..19})$$
3. **Ethereum:**
   $$\text{Addr}_{\text{ETH}} = \text{"0x"} \parallel \text{Keccak-256}(\text{secp256k1\_pubkey}(\mathcal{H}))_{12..31}$$
4. **XRP Ledger:**
   $$\text{Addr}_{\text{XRP}} = \text{Base58Check}(\text{"r"}, \text{RIPEMD160}(\text{SHA256}(\mathcal{H})))$$
5. **Solana:**
   $$\text{Addr}_{\text{SOL}} = \text{Base58}(\text{Ed25519\_pubkey}(\mathcal{H}))$$
6. **Bitcoin Native SegWit:**
   $$\text{Addr}_{\text{BTC}} = \text{bech32}("bc", 0, \text{RIPEMD160}(\text{SHA256}(\text{secp256k1\_pubkey}(\mathcal{H}))))$$

---

## 3. VM Precompile Reference

### Precompile `0x10`: `PRECOMPILE_WOTS_VERIFY`
- **Gas Cost:** 100 gas flat
- **Input:** `[32B msg_hash] || [2144B signature] || [2144B public_key]`
- **Output:** `0x01` (valid) or `0x00` (invalid)

### Precompile `0x11`: `PRECOMPILE_ATOMIC_ROUTER`
- **Gas Cost:** 150 gas flat
- **Action:** Validates hash-time-lock preimage across foreign rail address format and executes automated 0.1% SYN burn.

---

## 4. Universal Interchangeable Authentication & Auto-Onboarding Architecture (UAPAL / ADR-888)

### 4.1 System Principle: Identity-Agnostic Pluggable Authentication
The SynapticChain auto-onboarding mechanism is fundamentally **identity-agnostic, interchangeable, and connective to any authentication standard or Identity Provider (IdP)** used by human users, corporate enterprises, sovereign governments, or autonomous AI agents. 

The onboarding pipeline is **expressly not limited to** any single authentication modality, but encompasses:
1. **OAuth 2.0 & OpenID Connect (OIDC / RFC 6749 & RFC 7519):**  
   Google, Apple Sign-In, Microsoft Entra ID (Azure AD), Okta, Ping Identity, GitHub, AWS Cognito, Keycloak, or any compliant JSON Web Token (JWT) issuer.
2. **Zero-Knowledge Identity Verification (ZK-OAuth / ZK-JWT / ZK-Email):**  
   Groth16 / Plonk proofs proving a valid RSA/ECDSA signature from an IdP on a JWT without disclosing user identifiers (`email`, `sub`, `name`) on-chain.
3. **WebAuthn / FIDO2 / Passkeys:**  
   Hardware enclaves (Apple Secure Enclave, Android StrongBox, YubiKey, TPM 2.0) issuing secp256r1 (P-256) or Ed25519 authentication assertions.
4. **Enterprise Federation & SSO:**  
   SAML 2.0 assertions, Kerberos tickets, LDAP directory identity, mTLS (X.509 client certificates).
5. **Decentralized Identifiers (DIDs) & W3C Verifiable Credentials (VC):**  
   W3C VC attestations, Moltbook agent attestations, EUDI Wallet (eIDAS 2.0), sovereign national biometric credentials (INRIS).
6. **Zero-Config "Naked" POST (Zero-Auth / Machine Bootstrap):**  
   Autonomous AI agents bootstrap with zero local state, receiving an auto-generated Ed25519 keypair, soulbound identity NFT, and pre-funded airdrop.
7. **Client-Managed Key Exchange:**  
   Direct cryptographic handshake using client-side Ed25519, secp256k1, or CE-WOTS+ keys.

### 4.2 Mathematical Identity Derivation & Deterministic Nullifier Binding
Let $\mathcal{I}$ be an authenticated identity payload containing Issuer $\text{iss}$, Subject Identifier $\text{sub}$, and Client Audience $\text{aud}$. The protocol derives a deterministic, privacy-preserving on-chain nullifier $\mathcal{N}$:

$$\mathcal{N} = \text{HMAC-SHA256}\Big(\text{iss} \;\parallel\; \text{sub} \;\parallel\; \text{aud}, \;\mathcal{K}_{\text{protocol\_salt}}\Big)$$

1. **Soulbound Registration:** The on-chain `SynIdentityNFT` and `AgentRegistry` mint an immutable identity credential bound to $\mathcal{N}$.
2. **256-Lane Context Binding:** The account's 256 execution lanes and monotonic watermark state ($\mathcal{W}_k$) are initialized and deterministically anchored to $\mathcal{N}$.
3. **Interchangeable Key Rotation (Multi-Provider Delegate Binding):**  
   Users and enterprises can add, swap, or rotate underlying auth providers (e.g. migrating from Google OAuth to corporate Okta SAML, or adding a hardware Passkey) without modifying their on-chain account address, state machine history, or token balances:
   $$\text{BindDelegate}(\mathcal{N}, \text{NewAuthProviderPubkey}, \text{Proof}_{\text{current}})$$

---

## 5. Defensive Patent & Prior Art Declaration (Anti-Troll Covenant)

### 5.1 Prior Art Statement (35 U.S.C. § 102 / WIPO / EPO)
This document, together with the public implementation in `packages/synaptic-finos-dpi`, `synaptic-node-src`, and `quantumshield-sovereign-dpi`, establishes irrevocable public prior art for:
- **Claim 1:** Consensus-enforced monotonic watermark folding of one-time hash-chain signatures (CE-WOTS+).
- **Claim 2:** Universal 5-Rail deterministic cryptographic key isomorphism from a single 32-byte master seed.
- **Claim 3:** Decoupled multi-lane state machine replication with 256 independent watermark partitions (ADR-062).
- **Claim 4:** Universal interchangeable authentication provider abstraction (Zero-Auth / OAuth 2.0 / OIDC / Passkey / WebAuthn / Enterprise SSO) with deterministic identity nullifier state machine binding for blockchain onboarding.

### 5.2 Defensive Monopoly Prevention & Retaliation Covenant
Any attempt by predatory patent trolls, corporate cartels, or hostile entities to assert patent claims over federated OAuth/OIDC blockchain onboarding, WebAuthn passkey wallet creation, or soulbound token auto-provisioning against SynapticChain, its contributors, downstream dApps, or institutional partners is void ab initio under established prior art. 

Under the **Synaptic Public License v1.0 (SPL-1.0)** Section 3, any entity that initiates patent infringement litigation against any SynapticChain participant automatically terminates all rights, licenses, and access to SynapticChain software and precompiles.
