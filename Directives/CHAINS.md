# The 9-Chain Sovereign Mesh
**SpookyID Trust Architecture Specification**  
**Version**: 2.1 (Hardened)
**Status**: Canonical Reference (Phases 6-11 Verified)

---

## Philosophy & Ethics

Traditional identity systems conflate all trust concerns into a single monolithic credential (e.g., SSL certificates combine encryption + authentication + authorization). This creates systemic fragility: compromise one aspect, lose everything.

SpookyID's **9-Chain Sovereign Mesh** separates trust concerns into **orthogonal cryptographic chains**. Each chain solves a specific problem independently, enabling:
- **Granular Revocation**: Ban a user from one site without affecting others
- **Selective Disclosure**: Prove entitlements without revealing identity
- **Offline Delegation**: Transfer authority without server involvement
- **Sovereign Recovery**: Restore identity without custodial trust

**Design Principle**: *"Separation of Concerns in Cryptographic Space"*

---

## For AI Agents: Understanding Trust Architecture

**When you (an AI agent) are working on SpookyID features, you MUST understand:**

### The Core Ethical Principles

1. **User Sovereignty** (Chains 1, 5, 7)
   - Users OWN their identity, not SpookyID
   - Recovery doesn't depend on SpookyID's permission (Chain 5: Shamir)
   - Hardware binding prevents SpookyID from impersonating users (Chain 7)
   - **Implication**: Never design features that give SpookyID custody of user secrets

2. **Privacy by Default** (Chains 2, 3, 6)
   - Prove only what's necessary (Chain 2: Selective disclosure)
   - Sites can't track users across platforms (Chain 3: Unlinkable pseudonyms)
   - Audit without surveillance (Chain 6: Salted hashes)
   - **Implication**: Never log plaintext PII, never correlate across sites

3. **Fail-Closed Security** (All Chains)
   - Database error? Reject request (don't accept by default)
   - Invalid proof? Reject (don't give benefit of doubt)
   - Revoked credential? Reject even if DB unavailable
   - **Implication**: Every chain has "fail-closed" error handling (see R-ERR-001)

4. **Minimal Trust** (Chains 4, 9)
   - Delegation expires automatically (no manual revocation needed)
   - Offline verification doesn't trust server (Chain 9: cryptographic leases)
   - **Implication**: Design features that work even if SpookyID broker goes down

5. **Granular Control** (Chains 1, 3, 4)
   - Ban from one site ≠ ban everywhere (Chain 3: per-site linkage tags)
   - Revoke one credential ≠ lose all access (Chain 1: lifecycle independence)
   - Delegate specific permissions, not "all or nothing" (Chain 4)
   - **Implication**: Never design global bans or all-access tokens

### What Each Chain Protects Against

| Chain | Protects User From | Protects Relying Party From | Protects SpookyID From |
|-------|-------------------|----------------------------|----------------------|
| **1: Lifecycle** | Permanent compromise (can revoke) | Using revoked credentials | Storing PII (only commitments) |
| **2: Entitlements** | Over-disclosure ("age>21" not birthdate) | Fake credentials (crypto proof) | Knowing user details (ZKP) |
| **3: Contextual** | Cross-site tracking | Sybil attacks (hardware-bound) | Storing PII (linkage tags only) |
| **4: Delegation** | Permanent device loss (temp delegation) | Unauthorized sharing | N/A |
| **5: Recovery** | "Forgot password" hell | N/A | Being single point of failure |
| **6: Audit** | Surveillance (anonymized logs) | Unauditable access | GDPR violations (privacy logs) |
| **7: Attestation** | Software key extraction | Bot accounts (hardware req) | Sybil attacks (one device = one identity) |
| **8: Federation** | Vendor lock-in | N/A | Scaling costs (share issuance) |
| **9: Leasing** | Locked out offline | N/A | Always-online requirement |

### Chain Interaction Rules (For AI Agents)

**When modifying code, understand these dependencies:**

1. **Chain 1 (Lifecycle) affects ALL other chains**
   - Revoke anchor → All credentials invalid
   - Resurrection → New linkage tags generated (Chain 3)
   - **Rule**: Check Chain 1 status BEFORE checking other chains

2. **Chain 2 (Entitlements) depends on Chain 1**
   - Can't issue credential if anchor revoked
   - **Rule**: Always verify anchor active before BBS+ signing (R-REV-002)

3. **Chain 3 (Contextual) is read-only for sites**
   - Sites can ban linkage tags, but can't revoke anchor
   - **Rule**: Site-specific revocation NEVER affects other sites

4. **Chain 7 (Attestation) is one-time verification**
   - Verified at anchor registration, not every login
   - **Rule**: Don't re-verify attestation on every auth (expensive)

5. **Chain 9 (Leasing) cascades from Chain 1**
   - Anchor revoked → All leases invalid
   - **Rule**: Check anchor status when verifying lease (R-LEASE-004)

### Decision Tree for AI Agents

**"Which chain should I use for this feature?"**

```
Is this about credential lifecycle?
 ├─ YES → Chain 1 (Lifecycle)
 └─ NO ↓

Is this about proving attributes?
 ├─ YES → Chain 2 (Entitlements - BBS+)
 └─ NO ↓

Is this about per-site identity?
 ├─ YES → Chain 3 (Contextual - linkage tags)
 └─ NO ↓

Is this about temporary access?
 ├─ YES (online) → Chain 4 (Delegation)
 ├─ YES (offline) → Chain 9 (Leasing)
 └─ NO ↓

Is this about device loss recovery?
 ├─ YES → Chain 5 (Recovery - Shamir)
 └─ NO ↓

Is this about compliance logging?
 ├─ YES → Chain 6 (Audit)
 └─ NO ↓

Is this about hardware verification?
 ├─ YES → Chain 7 (Attestation)
 └─ NO ↓

Is this about multiple issuers?
 └─ YES → Chain 8 (Federation)
```

### Common Mistakes AI Agents Make

❌ **WRONG**: Store email address in database for account creation
✅ **RIGHT**: Store `hash(email || pepper)` (Chain 1: commitments only)

❌ **WRONG**: Return full credential on `/api/oidc/verify`
✅ **RIGHT**: Return only verified attributes requested (Chain 2: selective disclosure)

❌ **WRONG**: Use same linkage tag for all sites
✅ **RIGHT**: Generate `H(SK + site_id)` per site (Chain 3: unlinkability)

❌ **WRONG**: Delegation tokens never expire
✅ **RIGHT**: Include `expires_at` and `max_uses` (Chain 9: time-bounded)

❌ **WRONG**: Accept DB error as "not revoked"
✅ **RIGHT**: Reject request on DB error (fail-closed - R-ERR-001)

---

## Trust Architecture Loosely Based on Okta

SpookyID's chain architecture draws inspiration from Okta's multi-tenant identity model but **radically differs** in three ways:

1. **Okta is custodial** (they hold your keys) → **SpookyID is sovereign** (you hold your keys)
2. **Okta tracks users globally** → **SpookyID has unlinkable pseudonyms** (Chain 3)
3. **Okta requires online access** → **SpookyID works offline** (Chain 9: Leasing)

**If you want to propose cryptographically perfect improvements**, create a separate pitch document. CHAINS.md is the **current implemented architecture**, not the ideal future state.

---

## The 9 Chains

### Chain 1: Lifecycle (Birth, Death, Resurrection)

**Purpose**: Manage the fundamental existence states of an identity

**Cryptographic Primitive**: Hash commitments + PostgreSQL registry

**Operations**:
1. **Birth**: Anchor registers with Broker via `/api/anchor/register`
   - Broker stores `hash(device_commitment)` in `anchors` table
   - No PII stored, only cryptographic commitment
2. **Death**: User revokes compromised Anchor
   - Issues signed revocation certificate
   - Commitment added to `revocations` table ("The Graveyard")
3. **Resurrection**: Generate new Anchor, reclaim identity
   - Use Chain 5 (Recovery) to prove ownership
   - Issue new commitment, old one remains in Graveyard

**Implementation**:
- **Backend**: `backend/src/db/repositories.rs` (`store_anchor`, `revoke_tag`)
- **Database**: `backend/migrations/20260113000000_init_schema.sql`

**Business Value**: 
- GDPR "Right to be Forgotten" compliance
- Instant breach response (revoke within seconds)

---

### Chain 2: Entitlements (Selective Disclosure)

**Purpose**: Prove possession of attributes without revealing them

**Cryptographic Primitive**: BBS+ Signatures (BLS12-381)

**Mathematical Foundation**:
```
Signature: σ = (A, e, s)
Proof: π = (Ā, ê, r̂₁, r̂₂, m̂_hidden, challenge c)

Verifier receives:
- Revealed messages: {m₀, m₃} 
- Hidden messages proven via ZKP: {m₁, m₂, m₄, m₅, m₆, m₇}
```

**Use Cases**:
- Prove "Age > 21" without revealing birthdate
- Prove "US Citizen" without revealing state
- Prove "Security Clearance = Secret" without revealing agency

**Implementation**:
- **Crypto Core**: `multipass_app/rust/src/bbs.rs` (`bbs_sign`, `bbs_verify`)
- **mDoc Integration**: `multipass_app/rust/src/mdoc.rs` (ISO 18013-5 DeviceResponse)
- **Service**: Native Bridge via `ffi.rs`

**Standards Alignment**:
- W3C VC-DI-BBS (Verifiable Credentials Data Integrity BBS)
- ISO 18013-5 mdoc selective disclosure (via `isomdl` Rust crate)

**Business Value**:
- Privacy-by-design (NIST 800-63-3 AAL3 requirement)
- Competitive moat (YubiKey/Apple Passkey don't support this)

---

### Chain 3: Contextual (Unlinkable Pseudonyms)

**Purpose**: Prevent cross-site tracking while enabling site-specific user identification

**Cryptographic Primitive**: Deterministic linkage tags

**Formula**:
```
T = G₁ × (SK + H(site_id))

Where:
- G₁ = BLS12-381 generator point
- SK = User's secret key (never revealed)
- H(site_id) = Hash of domain name (e.g., "reddit.com")
```

**Properties**:
1. **Deterministic**: Same user + same site = same tag
2. **Unlinkable**: Cannot correlate tags across different sites
3. **Revocable**: Site can ban tag without deanonymizing user

**Attack Prevention**:
- **Cross-Site Tracking**: Reddit cannot determine if their user is the same person as Twitter user
- **Census Attacks**: Cannot enumerate all SpookyID users globally
- **Rainbow Tables**: Cannot precompute tags without knowing SK

**Implementation**:
- **Crypto**: `common/crypto/src/lib.rs` (`create_proof_safe` embeds linkage tag)
- **Revocation**: `backend/src/db/repositories.rs` (`is_tag_revoked`)

**Business Value**:
- GDPR Article 25 "Privacy by Design" compliance
- Enables spam/abuse bans without surveillance

---

### Chain 4: Delegation (Temporary Authority Transfer)

**Purpose**: Allow a primary identity to grant temporary privileges to secondary entities

**Cryptographic Primitive**: HMAC-signed time-boxed tokens

**Token Structure**:
```json
{
  "grantor": "anchor_12345",
  "grantee": "temp_device_xyz",
  "scope": ["read:profile", "write:messages"],
  "expires_at": 1704628800,
  "nonce": "abc123...",
  "signature": "HMAC-SHA256(...)"
}
```

**Use Cases**:
- Corporate laptop delegates to mobile phone for 2FA
- Parent delegates limited access to child's account
- Primary device delegates to backup device during travel

**Implementation**:
- **Service**: `backend/src/bin/oidc_service.rs` (`verify_delegated` handler)
- **Database**: `sessions` table tracks delegation lineage

**Business Value**:
- Enterprise workflow automation (contractors, temp workers)
- Consumer convenience (multi-device ecosystems)

---

### Chain 5: Recovery (Sovereign Resurrection)

**Purpose**: Restore identity after device loss *without* custodial intermediaries

**Cryptographic Primitive**: Shamir Secret Sharing (SSS)

**Protocol**:
1. **Setup**: User splits master seed into `n` shares (e.g., 5 shares)
2. **Distribution**: Shares given to trusted parties (friends/family)
3. **Recovery**: Collect `k` shares (e.g., 3 of 5) to reconstruct seed
4. **Resurrection**: Generate new Anchor from reconstructed seed

**Implementation**:
- **Crypto**: `common/crypto/src/lib.rs` (`reconstruct_secret`)
- **Service**: `backend/src/bin/oidc_service.rs` (`/api/anchor/recover`)

**Security Properties**:
- **Threshold**: Must compromise k parties (not just one)
- **Dealer-Free**: No central authority holds complete secret
- **Forward Secrecy**: Old shares useless after Anchor regenerated

**Business Value**:
- Consumer resilience (no "forgot password" hell)
- Enterprise continuity (employee leaves, company recovers access)

---

### Chain 6: Audit (Privacy-Preserving Logs)

**Purpose**: Enable compliance auditing *without* deanonymizing users

**Cryptographic Primitive**: Salted hash commitments

**Log Entry Format**:
```
Event: User logged into system
Identity: H(linkage_tag || salt)  <- Cannot reverse to find user
Timestamp: 2026-01-13T22:34:10Z
Action: "authentication_success"
```

**Use Cases**:
- SOC 2 compliance (prove authentication logs exist)
- HIPAA audit trails (prove who accessed medical records)
- Forensics (identify malicious actor *after* incident)

**Reveal Mechanism**:
- During investigation, user (or court order) provides salt
- Auditor recomputes `H(tag || salt)` to verify match
- User identity revealed only when legally required

**Implementation**:
- **Backend**: `backend/src/db/repositories.rs` (logs stored in PostgreSQL)
- **Witness**: Merkle tree root published periodically (future enhancement)

**Business Value**:
- Regulatory compliance (SOC 2, ISO 27001, GDPR Article 30)
- Liability reduction (prove due diligence in breach investigations)

---

### Chain 7: Attestation (Hardware Verification)

**Purpose**: Prove identity operations occur in genuine hardware (anti-Sybil)

**Cryptographic Primitive**: X.509 certificate chain validation

**Verification Flow**:
1. Device generates attestation keypair in Secure Element
2. OS signs public key with device-specific certificate
3. SpookyID Broker validates chain to trusted root CA:
   - **Android**: Google Hardware Attestation (OID `1.3.6.1.4.1.11129.2.1.17`)
   - **Apple**: Secure Enclave attestation
   - **JavaCard**: NXP J3H145 attestation (GlobalPlatform)

**Attack Prevention**:
- **Emulators**: Cannot generate valid attestation (no hardware key)
- **Rooted Devices**: Attestation fails if bootloader unlocked
- **Cloned Keys**: Each device has unique factory-provisioned certificate

**Implementation**:
- **Crypto**: `common/crypto/src/attestation.rs` (`verify_device_attestation`)
- **Service**: `backend/src/bin/oidc_service.rs` (`register_mobile_device`)

**Standards**:
- Android Key Attestation (Android 8.0+)
- Apple DeviceCheck API
- FIDO2/WebAuthn attestation formats

**Business Value**:
- NIST AAL3 compliance ("hardware authenticator" requirement)
- Anti-fraud (prevents bot farms, credential stuffing)

---

### Chain 8: Federation (Trust Between Issuers)

**Purpose**: Enable multiple issuers to participate in the SpookyID ecosystem

**Cryptographic Primitive**: OIDC Discovery + JWKS (JSON Web Key Set)

**Federation Model**:
```
┌─────────────────┐      Trust       ┌─────────────────┐
│  SpookyID Core  │ ←──────────────→ │ Partner Issuer  │
│   (Primary)     │                  │  (e.g., Bank)   │
└─────────────────┘                  └─────────────────┘
         │                                    │
         ├─ Issues: HardwareAnchorCredential  │
         │                                    ├─ Issues: BankAccountCredential
         │                                    │
         └───────────── User Wallet ──────────┘
                    (Holds both VCs)
```

**Protocol**:
1. Partner publishes OIDC discovery endpoint
2. SpookyID fetches JWKS (public keys)
3. User presents credential signed by partner
4. SpookyID verifies signature using partner's public key

**Implementation**:
- **Service**: `backend/src/bin/oidc_service.rs` (`/.well-known/openid-configuration`)
- **Future**: OpenID Federation 1.0 support (automatic trust resolution)

**Business Value**:
- Network effects (more issuers = more use cases)
- B2B partnerships (banks, universities, governments as co-issuers)

---

### Chain 9: Leasing (Sudo Access)

**Purpose**: Enable offline, cryptographically-secured identity delegation

**Cryptographic Primitive**: Anchor-signed lease tokens

**Token Format**:
```rust
struct LeaseToken {
    grantor_commitment: [u8; 32],    // Hash of Anchor's secret
    grantee_public_key: [u8; 33],    // Temporary device key
    scope: Vec<String>,               // ["read:messages", "write:posts"]
    max_uses: u32,                    // e.g., 10 authentications
    expires_at: i64,                  // Unix timestamp
    signature: [u8; 64],              // Ed25519 sig by Anchor
}
```

**Use Cases**:
- **Airgapped Systems**: Government facility with no internet connectivity
- **Burner Phones**: Temporary delegation to disposable device
- **Emergency Access**: Hospital staff accessing patient records during outage

**Verification (Offline)**:
1. Verifier receives lease token from grantee
2. Verifies `signature` matches `grantor_commitment` (proof of authentic lease)
3. Checks `expires_at` and `max_uses` not exceeded
4. Accepts authentication *without* contacting SpookyID Broker

**Implementation**:
- **Crypto**: `common/crypto/src/lib.rs` (`sign_delegation`, `verify_delegation`)
- **Service**: `backend/src/multipass/lease.rs`

**Security Properties**:
- **Non-Transferable**: Lease bound to `grantee_public_key` (cannot share)
- **Time-Bounded**: Automatic expiration (no manual revocation needed)
- **Auditable**: Grantor can query Broker for all active leases

**Business Value**:
- **Enterprise**: $5-25 per lease (high-margin SaaS revenue)
- **Defense**: Only solution for airgapped Zero-Trust networks
- **Unique IP**: No competitor has cryptographic offline delegation

---

## Chain Interaction Matrix

| Chain 1 (Lifecycle) | Chain 2 (Entitlements) | Chain 3 (Contextual) | ... | Chain 9 (Leasing) |
|---------------------|------------------------|----------------------|-----|-------------------|
| Creates anchor_id   | Uses anchor_id for VC  | Derives tag from SK  | ... | Signs lease token |
| Revokes commitment  | Invalidates proofs     | Bans linkage tag     | ... | Expires leases    |
| Enables resurrection| Preserves after recovery| New tag post-recovery| ... | Re-delegate allowed|

**Key Insight**: Chains are **loosely coupled** but **cryptographically bound**. Revoking Chain 1 (Lifecycle) doesn't erase Chain 3 tags from sites' local databases—but it prevents new tag generation.

---

## Implementation Checklist

| Chain | Status | Module | Tests | Production |
|-------|--------|--------|-------|------------|
| 1. Lifecycle | ✅ Complete | `db/repositories.rs` | ✅ | ✅ Live |
| 2. Entitlements | ✅ Complete | `lib.rs` (BBS+) | ⚠️ 1 test failing | ✅ Live |
| 3. Contextual | ✅ Complete | `lib.rs` (linkage) | ✅ | ✅ Live |
| 4. Delegation | ✅ Complete | `oidc_service.rs` | ✅ | ✅ Live |
| 5. Recovery | ✅ Complete | `lib.rs` (Shamir) | ✅ | ✅ Live |
| 6. Audit | ✅ Complete | `db/repositories.rs` | ✅ | ✅ Live |
| 7. Attestation | ✅ Complete | `attestation.rs` | ✅ | ✅ Live |
| 8. Federation | ❌ Planned | N/A | ❌ | 📋 Roadmap Q2 2026 |
| 9. Leasing | ✅ Complete | `lib.rs` (BBS+) | ✅ Verified | 🚧 Ready for UI |

---

## Regulatory Mapping

**NIST 800-63-3 AAL3 (Authenticator Assurance Level 3)**:
- Chain 7 (Attestation) → Hardware authenticator requirement
- Chain 3 (Contextual) → Verifier impersonation resistance
- Chain 2 (Entitlements) → Replay resistance (nonce binding)

**GDPR (EU General Data Protection Regulation)**:
- Chain 1 (Lifecycle) → Right to erasure (Article 17)
- Chain 6 (Audit) → Proof of compliance (Article 30)
- Chain 3 (Contextual) → Privacy by design (Article 25)

**eIDAS 2.0 (EU Digital Identity Regulation)**:
- Chain 8 (Federation) → Interoperability with national eID schemes
- Chain 2 (Entitlements) → Attribute attestation framework
- Chain 7 (Attestation) → QSCD (Qualified Signature Creation Device) compatibility

**ISO 18013-5 (Mobile Driving License)**:
- Chain 2 (Entitlements) → Selective disclosure (mdoc DeviceResponse)
- Chain 3 (Contextual) → Session binding (prevent relay attacks)
- Chain 7 (Attestation) → Device key binding

---

## Future Enhancements

**Chain 10: Reputation (Decentralized Trust Scores)** [Proposed]
- Accumulate "trust tokens" from successful verifications
- Privacy-preserving reputation (zero-knowledge range proofs)
- Use case: Prove "I've been verified 100+ times" without revealing where

**Chain 11: Interoperability (Cross-Chain Bridges)** [Proposed]
- Bridge SpookyID credentials to blockchain identity systems (ENS, DID:Ethr)
- Two-way attestations (prove blockchain wallet ownership + SpookyID anchor)

---

## References

- **BBS+ Specification**: [W3C VC-DI-BBS](https://w3c.github.io/vc-di-bbs/)
- **Shamir Secret Sharing**: Shamir, A. (1979). "How to share a secret"
- **NIST 800-63-3**: Digital Identity Guidelines (Authentication & Lifecycle)
- **ISO 18013-5**: Personal identification — ISO-compliant driving license

---

**Maintainer**: SpookyOS Project  
**Last Updated**: January 13, 2026  
**Status**: Living Document (v2.0 Post-PostgreSQL Migration)
