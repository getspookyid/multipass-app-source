# RULES - SpookyID Constraint Bible

**Purpose**: Comprehensive reference for all security constraints, operational rules, and business logic enforced throughout the SpookyID stack.
**Version**: 1.0.0
**Last Updated**: 2026-01-16
**Audience**: AI coding agents, security auditors, developers

---

## Document Structure

This document contains:
1. **Rule Template & Categories** - How rules are organized
2. **Complete Rule Catalog** - All 50+ rules with full details
3. **Endpoint-to-Rules Mapping** - Which rules apply to which API endpoints
4. **Feature-to-Rules Mapping** - Which rules govern which features
5. **Rule-to-Chain Mapping** - How rules integrate with trust chains
6. **Code Location Index** - Where each rule is enforced
7. **Maintenance Procedures** - How to add/modify rules

---

## Rule Template

Each rule follows this structure:

```markdown
### R-CATEGORY-NNN: Rule Name

- **Rule**: MUST/MUST NOT statement (the constraint itself)
- **Enforcement**: Code location(s) where enforced
- **Violation**: What happens when rule is violated
- **Rationale**: Why this rule exists (security/privacy/business reason)
- **Chains**: Which trust chains this rule affects
- **Code Example**: Actual implementation snippet (optional)
```

---

## Rule Categories

| Category | Prefix | Count | Purpose |
|----------|--------|-------|---------|
| Cryptographic | R-CRYPTO-* | 8 | BBS+ signatures, entropy, key management |
| Protocol | R-PROTO-* | 7 | OIDC flows, nonce handling, anti-replay |
| Hardware | R-HW-* | 5 | Attestation, JavaCard, TEE requirements |
| Privacy | R-PRIV-* | 6 | Zero-knowledge, k-anonymity, audit |
| Revocation | R-REV-* | 4 | Credential lifecycle, graveyard |
| Leasing | R-LEASE-* | 5 | Delegation tokens, offline sudo |
| Recovery | R-REC-* | 3 | Shamir secret sharing, sovereign identity |
| Operations | R-OPS-* | 4 | Admin actions, bootstrapping |
| Rate Limiting | R-RATE-* | 3 | DoS protection, API throttling |
| Error Handling | R-ERR-* | 4 | Fail-closed, security-first errors |
| Monitoring | R-MON-* | 3 | Audit logs, metrics, alerts |
| Data | R-DATA-* | 4 | Database integrity, migrations |
| API | R-API-* | 5 | Endpoint contracts, versioning |
| App Security | R-APP-* | 1 | Client-side security gates |
| Bridge | R-BRIDGE-* | 2 | FFI interface constraints |

**Total Rules**: 66


---

## CRYPTOGRAPHIC RULES (R-CRYPTO-*)

### R-CRYPTO-001: Zkryptium Library Mandate

- **Rule**: MUST use `zkryptium` (Rust crate) for BBS+ operations. MUST NOT use legacy MATTR libraries.
- **Enforcement**: `multipass_app/rust/Cargo.toml:dependencies`, `multipass_app/rust/src/bbs.rs`
- **Violation**: Reject build if non-zkryptium BBS library detected.
- **Rationale**: Transition to "Rust Core" architecture requires native Rust implementations compatible with Flutter Rust Bridge. `zkryptium` provides necessary BBS+ primitives.
- **Chains**: Chain 2 (Entitlements), Chain 6 (Audit), Chain 9 (Leasing)
- **Code Example**:
```rust
// multipass_app/rust/src/bbs.rs
use zkryptium::bbsplus::ciphersuites::Bls12381Sha256;
use zkryptium::schemes::algorithms::BBSplus;
// APPROVED
```

### R-CRYPTO-002: Issuer Secret Key Protection

- **Rule**: Issuer SK MUST be TPM-backed in production. MUST NOT exist in plaintext on disk.
- **Enforcement**: `backend/src/bin/oidc_service.rs:124-150` (key loading), startup validation
- **Violation**: Server refuses to start if `UNSAFE_DEV_MODE=false` and SK not TPM-backed.
- **Rationale**: Issuer SK compromise allows forging unlimited credentials. TPM provides hardware isolation.
- **Chains**: Chain 1 (Lifecycle - credential issuance), Chain 2 (Entitlements)
- **Code Example**:
```rust
// backend/src/bin/oidc_service.rs:124-150
fn load_issuer_key() -> Result<BbsSecretKey, String> {
    if std::env::var("UNSAFE_DEV_MODE").unwrap_or("false".to_string()) == "false" {
        // Production mode: Load from TPM
        let tpm_path = std::env::var("TPM_PATH")
            .map_err(|_| "TPM_PATH not set in production mode")?;
        load_key_from_tpm(&tpm_path)
    } else {
        // Dev mode: Allow plaintext (with warning)
        eprintln!("⚠️  WARNING: Using plaintext issuer key (DEV MODE ONLY)");
        load_key_from_env()
    }
}
```

### R-CRYPTO-003: Message Count Consistency

- **Rule**: `MESSAGE_COUNT` environment variable MUST match actual credential attributes. All BBS+ operations MUST use same message count.
- **Enforcement**: `backend/src/lib.rs:109-164` (signing), `backend/src/lib.rs:269-350` (proof creation)
- **Violation**: BBS+ verification fails. Credential issuance rejected.
- **Rationale**: BBS+ public key generators `{g1, h1, h2, ..., h_n}` must match message count. Mismatch breaks selective disclosure.
- **Chains**: Chain 2 (Entitlements - selective disclosure)
- **Code Example**:
```rust
// backend/src/lib.rs:109-164
pub fn bbs_sign(
    sk: &BbsSecretKey,
    pk: &BbsPublicKey,
    messages: &[Vec<u8>],
) -> Result<Vec<u8>, String> {
    let msg_count = std::env::var("MESSAGE_COUNT")
        .unwrap_or("3".to_string())
        .parse::<usize>()
        .unwrap();

    if messages.len() != msg_count {
        return Err(format!("Message count mismatch: expected {}, got {}", msg_count, messages.len()));
    }
    // ... signing logic
}
```

### R-CRYPTO-004: Hardware Entropy Requirement

- **Rule**: Production MUST use `/dev/hwrng` for entropy. Software fallback allowed ONLY in dev mode with warning.
- **Enforcement**: `backend/src/periwinkle.rs:33-66` (EntropyHarvester initialization)
- **Violation**: Warning logged in dev mode. Error in production if `HWRNG_PATH` missing.
- **Rationale**: AAL3 assurance requires 1856 bits of hardware entropy. Software RNG is predictable.
- **Chains**: Chain 5 (Freshness - level 4 entropy), Chain 3 (Device Binding)
- **Code Example**:
```rust
// backend/src/periwinkle.rs:33-66
match File::open("/dev/hwrng") {
    Ok(mut rng_file) => {
        rng_file.read_exact(&mut puf).expect("Failed to read PUF root from hardware");
        eprintln!("[PERIWINKLE] ✅ Hardware RNG initialized from /dev/hwrng");
    }
    Err(_) => {
        eprintln!("[PERIWINKLE] ⚠️  WARNING: /dev/hwrng not available - using software fallback (DEV MODE ONLY)");
        // In production, this should be a fatal error
        if std::env::var("UNSAFE_DEV_MODE").unwrap_or("false".to_string()) == "false" {
            panic!("Production requires hardware RNG at /dev/hwrng");
        }
    }
}
```

### R-CRYPTO-005: Linkage Tag Collision Resistance

- **Rule**: Linkage tags MUST be SHA-256(blinding_factor || anchor_id). MUST NOT use weak hash functions.
- **Enforcement**: `backend/src/lib.rs:62-68` (compute_linkage_tag)
- **Violation**: Build error if non-SHA256 hash used.
- **Rationale**: Linkage tags enable privacy-preserving revocation. Collision allows impersonation.
- **Chains**: Chain 1 (Lifecycle - revocation), Chain 6 (Audit - privacy-preserving logs)
- **Code Example**:
```rust
// backend/src/lib.rs:62-68
pub fn compute_linkage_tag(blinding: &Scalar, anchor_id: &str) -> Vec<u8> {
    let mut hasher = Sha256::new();
    hasher.update(blinding.to_bytes_be());
    hasher.update(anchor_id.as_bytes());
    hasher.finalize().to_vec()
}
```

### R-CRYPTO-006: Proof Verification Safety

- **Rule**: MUST use `verify_proof_safe()` wrapper. MUST NOT call raw BBS library functions directly in endpoints.
- **Enforcement**: All `/api/oidc/verify`, `/api/vp/verify` endpoints
- **Violation**: Code review failure. Endpoint rejected.
- **Rationale**: Safe wrapper validates input lengths, prevents panics, handles errors securely.
- **Chains**: Chain 2 (Entitlements - ZKP verification)
- **Code Example**:
```rust
// backend/src/lib.rs:372-555
pub fn verify_proof_safe(
    pk_bytes: &[u8],
    proof_bytes: &[u8],
    revealed_msgs: &[(usize, Vec<u8>)],
    nonce_bytes: &[u8],
) -> Result<bool, String> {
    // Input validation
    if pk_bytes.len() != 96 { return Err("Invalid PK length".to_string()); }
    if proof_bytes.is_empty() { return Err("Empty proof".to_string()); }
    // ... safe parsing and verification
}
```

### R-CRYPTO-007: Delegation Token Signature

- **Rule**: Delegation tokens MUST be signed with anchor's private key. MUST include expiration timestamp.
- **Enforcement**: `backend/src/lib.rs:577-686` (create_delegation_token), `backend/src/bin/oidc_service.rs:957-1104`
- **Violation**: Unsigned or expired tokens rejected with 401.
- **Rationale**: Offline delegation requires cryptographic proof of anchor authorization.
- **Chains**: Chain 9 (Leasing - offline sudo)
- **Code Example**:
```rust
// backend/src/lib.rs:577-686
pub struct DelegationToken {
    pub anchor_id: Vec<u8>,       // 16 bytes UUID
    pub mobile_pubkey: Vec<u8>,   // 65 bytes P-256 SPKI
    pub tier: u8,                 // 1 byte
    pub expiration: u64,          // 8 bytes timestamp
    pub max_passages: u32,        // 4 bytes
    pub signature: Vec<u8>,       // 48 bytes BBS+
}
// Total: 145 bytes
```

### R-CRYPTO-008: Shamir Threshold Security

- **Rule**: Recovery shares MUST use k-of-n threshold with k ≥ 3, n ≤ 7. MUST NOT allow k < 3.
- **Enforcement**: `backend/src/lib.rs:690-747` (shamir_split)
- **Violation**: Function returns error if k < 3.
- **Rationale**: k < 3 provides insufficient security. n > 7 increases surface area for loss/compromise.
- **Chains**: Chain 5 (Recovery - sovereign identity)
- **Code Example**:
```rust
// backend/src/lib.rs:690-747
pub fn shamir_split(secret: &[u8], k: u8, n: u8) -> Result<Vec<Vec<u8>>, String> {
    if k < 3 {
        return Err("Threshold k must be at least 3 for security".to_string());
    }
    if n > 7 {
        return Err("Total shares n should not exceed 7 (usability)".to_string());
    }
    if k > n {
        return Err("Threshold k cannot exceed total shares n".to_string());
    }
    // ... Shamir secret sharing implementation
}
```

---

## PROTOCOL RULES (R-PROTO-*)

### R-PROTO-001: Nonce Single-Use Enforcement

- **Rule**: Each nonce MUST be used exactly once. MUST reject reused nonces.
- **Enforcement**: `backend/src/bin/oidc_service.rs:341-361` (get_nonce), `backend/src/bin/oidc_service.rs:417-434` (verify nonce)
- **Violation**: 401 Unauthorized with error "Nonce already used or invalid"
- **Rationale**: Prevents replay attacks. Nonce reuse allows attacker to replay valid proof.
- **Chains**: Chain 2 (Entitlements - anti-replay), All verification endpoints
- **Code Example**:
```rust
// backend/src/bin/oidc_service.rs:417-434
let nonce_valid = state.db.verify_nonce(&proof_req.nonce, now).await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e))?;

if !nonce_valid {
    return Err((StatusCode::UNAUTHORIZED, "Nonce already used or invalid".to_string()));
}
```

### R-PROTO-002: Timestamp Freshness Window

- **Rule**: Timestamps MUST be within 300 seconds (5 minutes) of server time. Reject stale requests.
- **Enforcement**: `backend/src/bin/oidc_service.rs:490-510` (all verification endpoints)
- **Violation**: 401 Unauthorized with error "Timestamp out of acceptable window"
- **Rationale**: Prevents replay attacks with old valid proofs. 5min balances security vs clock skew.
- **Chains**: Chain 5 (Freshness - temporal binding)
- **Code Example**:
```rust
// backend/src/bin/oidc_service.rs:490-510
let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs();
let timestamp_diff = (now as i64 - proof_req.timestamp as i64).abs();

if timestamp_diff > 300 {
    return Err((StatusCode::UNAUTHORIZED, "Timestamp out of acceptable window (±300s)".to_string()));
}
```

### R-PROTO-003: Assurance Level Cascade

- **Rule**: Assurance levels MUST be cumulative: L1 ⊂ L2 ⊂ L3 ⊂ L4. Higher level includes all lower checks.
- **Enforcement**: `backend/src/bin/oidc_service.rs:409-637` (verify_proof_handler)
- **Violation**: Logic error. Higher assurance level without lower checks rejected.
- **Rationale**: Security properties stack. L4 without L2 revocation check is invalid.
- **Chains**: All chains (defines verification rigor)
- **Code Example**:
```rust
// backend/src/bin/oidc_service.rs:409-637
// L1: Signature verification (always required)
let sig_valid = verify_proof_safe(...)?;

// L2: Revocation check (L2+)
if assurance_level >= 2 {
    let revoked = state.db.is_tag_revoked(&linkage_tag).await?;
    if revoked { return Err("Credential revoked"); }
}

// L3: Device attestation (L3+)
if assurance_level >= 3 {
    verify_device_attestation(&proof_req.attestation_chain)?;
}

// L4: Freshness binding (L4)
if assurance_level >= 4 {
    verify_level4_entropy(&proof_req.entropy_claim)?;
}
```

### R-PROTO-004: OIDC Discovery Immutability

- **Rule**: `/.well-known/openid-configuration` MUST be static and cached. MUST NOT change per request.
- **Enforcement**: `backend/src/bin/oidc_service.rs:311-337` (discovery endpoint)
- **Violation**: Warning in logs. Potential OIDC client compatibility issues.
- **Rationale**: OIDC discovery endpoint is foundational. Dynamic changes break client caching.
- **Chains**: Chain 4 (Discovery - OIDC metadata)
- **Code Example**:
```rust
// backend/src/bin/oidc_service.rs:311-337
async fn discovery(State(state): State<AppState>) -> Json<serde_json::Value> {
    // Static response (should be cached at CDN level)
    Json(json!({
        "issuer": std::env::var("SPOOKY_ISSUER").unwrap(),
        "authorization_endpoint": format!("{}/authorize", state.issuer),
        "token_endpoint": format!("{}/api/oidc/token", state.issuer),
        // ... other static fields
    }))
}
```

### R-PROTO-005: Credential Metadata Consistency

- **Rule**: Credential metadata MUST match issued credential structure. Attribute names and order MUST be consistent.
- **Enforcement**: `backend/src/bin/oidc_service.rs:844-887` (issue credential)
- **Violation**: Credential verification fails. Client rejects malformed credential.
- **Rationale**: BBS+ selective disclosure depends on message index ordering.
- **Chains**: Chain 1 (Lifecycle - issuance), Chain 2 (Entitlements)
- **Code Example**:
```rust
// backend/src/bin/oidc_service.rs:844-887
let messages = vec![
    user_data.anchor_id.as_bytes().to_vec(),  // Index 0
    user_data.email.as_bytes().to_vec(),      // Index 1
    user_data.age.to_string().as_bytes().to_vec(), // Index 2
];
// Metadata MUST specify: ["anchor_id", "email", "age"] in same order
```

### R-PROTO-006: Admin Token Verification

- **Rule**: All `/api/admin/*` endpoints MUST verify `X-Admin-Token` header against `SPOOKY_ADMIN_TOKEN` env var.
- **Enforcement**: All admin endpoints (`backend/src/bin/oidc_service.rs:254-260`)
- **Violation**: 403 Forbidden
- **Rationale**: Admin endpoints perform privileged operations (revocation, key rotation).
- **Chains**: Chain 1 (Lifecycle - admin revocation)
- **Code Example**:
```rust
// Typical admin endpoint pattern
async fn admin_revoke(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<RevokeRequest>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    let admin_token = headers.get("X-Admin-Token")
        .and_then(|v| v.to_str().ok())
        .ok_or((StatusCode::FORBIDDEN, "Missing admin token".to_string()))?;

    let expected = std::env::var("SPOOKY_ADMIN_TOKEN")
        .map_err(|_| (StatusCode::INTERNAL_SERVER_ERROR, "Admin token not configured".to_string()))?;

    if admin_token != expected {
        return Err((StatusCode::FORBIDDEN, "Invalid admin token".to_string()));
    }
    // ... proceed with admin action
}
```

### R-PROTO-007: CORS Restrictions

- **Rule**: CORS MUST be configured to allow only trusted origins in production. Dev mode may use permissive CORS.
- **Enforcement**: `backend/src/bin/oidc_service.rs:230-234` (CORS middleware)
- **Violation**: Browser blocks cross-origin requests from untrusted domains.
- **Rationale**: Prevents malicious websites from making authenticated requests to API.
- **Chains**: All API endpoints
- **Code Example**:
```rust
// backend/src/bin/oidc_service.rs:230-234
let cors = if std::env::var("UNSAFE_DEV_MODE").unwrap_or("false".to_string()) == "true" {
    CorsLayer::permissive() // Dev mode
} else {
    CorsLayer::new()
        .allow_origin(["https://dashboard.getspooky.io".parse().unwrap()])
        .allow_methods([Method::GET, Method::POST])
};
```

### R-PROTO-008: JWT Admin Token Authentication (Phase 8.3)

- **Rule**: All `/api/admin/metrics` and `/api/admin/recent_auth` endpoints MUST verify JWT token via `Authorization: Bearer <token>` header. Legacy `/api/admin/login` returns JWT tokens instead of mock tokens.
- **Enforcement**: `oidc_service.rs:1664-1686` (verify_admin_token), `oidc_service.rs:1597-1700` (metrics endpoints)
- **Violation**: 401 Unauthorized with error "Token expired or invalid" or "Missing Authorization header"
- **Rationale**: JWT tokens provide stateless authentication with expiration, replacing mock tokens. Admin endpoints require cryptographic proof of authentication.
- **Chains**: Chain 1 (Lifecycle - admin actions), Phase 8.3 (Admin Dashboard)
- **Code Example**:
```rust
// backend/src/bin/oidc_service.rs:1664-1686
fn verify_admin_token(headers: &HeaderMap, jwt_secret: &str) -> Result<AdminClaims, String> {
    let auth_header = headers
        .get("Authorization")
        .and_then(|h| h.to_str().ok())
        .ok_or("Missing Authorization header")?;
    
    if !auth_header.starts_with("Bearer ") {
        return Err("Invalid Authorization header format".to_string());
    }
    
    let token = &auth_header[7..];
    let key = DecodingKey::from_secret(jwt_secret.as_bytes());
    let validation = Validation::new(Algorithm::HS256);
    
    decode::<AdminClaims>(token, &key, &validation)
        .map(|token_data| token_data.claims)
        .map_err(|e| format!("Token validation failed: {}", e))
}
```

**JWT Token Structure**:
```json
{
  "sub": "admin:JCOP-133983",
  "role": "admin",
  "iss": "http://localhost:7777",
  "exp": 1768634575,
  "iat": 1768630975
}
```

**Token Lifetime**: 1 hour (3600 seconds)  
**Algorithm**: HS256 (HMAC-SHA256)  
**Secret Management**: `SPOOKY_JWT_SECRET` env var (required in production)

---

## HARDWARE RULES (R-HW-*)

### R-HW-001: Attestation Extension Requirement

- **Rule**: Production MUST reject device keys without Android KeyStore extension OID 1.3.6.1.4.1.11129.2.1.17 or iOS Secure Enclave equivalent.
- **Enforcement**: `backend/src/attestation.rs:23-31`
- **Violation**: 403 Forbidden with error "Device not backed by Hardware KeyStore"
- **Rationale**: Software-backed keys can be extracted. Hardware isolation prevents key exfiltration.
- **Chains**: Chain 3 (Device Binding - attestation)
- **Code Example**:
```rust
// backend/src/attestation.rs:23-31
let has_attestation = leaf.extensions().iter().any(|ext| {
    ext.oid.to_string() == ANDROID_ATTESTATION_OID
});

if !has_attestation {
    return Err("Production Security Violation: Device not backed by Hardware KeyStore (StrongBox/SE required)".to_string());
}
```

### R-HW-002: Trusted Root CA Validation

- **Rule**: Attestation chain MUST terminate in Google or Apple root CA. Custom roots rejected.
- **Enforcement**: `backend/src/attestation.rs:38-52`
- **Violation**: 403 Forbidden with error "Untrusted Root CA"
- **Rationale**: Only OEM roots guarantee hardware attestation authenticity.
- **Chains**: Chain 3 (Device Binding)
- **Code Example**:
```rust
// backend/src/attestation.rs:42-52
let issuer = root.issuer().to_string();
if issuer.contains("Google") || issuer.contains("Apple") {
    Ok(leaf.tbs_certificate.subject_pki.raw.to_vec())
} else {
    Err(format!("Untrusted Root CA: {}", issuer))
}
```

### R-HW-003: JavaCard Master Seed Protection

- **Rule**: JavaCard master seed (32 bytes) MUST NEVER be exported. Only derived keys may leave card.
- **Enforcement**: `anchor/SpookyIDApplet.java:APDU_DERIVE (0x20)`
- **Violation**: JavaCard refuses command. Returns error 0x6A86.
- **Rationale**: Master seed compromise allows forging all derived credentials.
- **Chains**: Chain 3 (Device Binding - root of trust)
- **Code Example**:
```java
// anchor/SpookyIDApplet.java (pseudocode)
case APDU_DERIVE:
    // Derive child key from master seed
    byte[] derived = deriveKey(masterSeed, derivationPath);
    apdu.sendBytes(derived); // OK - derived key exported
    // masterSeed NEVER accessible via APDU
```

### R-HW-004: PIN Rate Limiting

- **Rule**: JavaCard MUST enforce 3 failed PIN attempts before lockout. Unlock requires PUK or factory reset.
- **Enforcement**: `anchor/SpookyIDApplet.java:APDU_VERIFY_PIN (0x50)`
- **Violation**: Card locks after 3 failures. Returns 0x6983.
- **Rationale**: Prevents brute-force PIN guessing.
- **Chains**: Chain 3 (Device Binding - physical security)

### R-HW-005: TPM Binding for Issuer Key

- **Rule**: Production issuer secret key MUST be bound to server TPM. Key usage requires TPM unsealing.
- **Enforcement**: Server startup key loading (`backend/src/bin/oidc_service.rs:124-150`)
- **Violation**: Server refuses to start if `UNSAFE_DEV_MODE=false` and TPM unavailable.
- **Rationale**: Prevents issuer key theft via server compromise. TPM provides hardware isolation.
- **Chains**: Chain 1 (Lifecycle - credential issuance)

### R-HW-006: StrongBox-Only Storage (Phase 7)

- **Rule**: All Credential Storage encryption MUST use AES-256 GCM keys backed by Android StrongBox (or TEE if unavailable, with warning). Software-only keys for storage prohibited in Production.
- **Enforcement**: `multipass_app/android/app/src/main/kotlin/com/spookyid/multipass/KeystoreManager.kt`
- **Violation**: App refuses to save credentials if key generation fails to bind to hardware.
- **Rationale**: "Physical Chaos" architecture. Even if filesystem is dumped, keys are locked in HSM.
- **Chains**: Chain 1 (Lifecycle), Chain 7 (Credential Management)

---

## APP SECURITY RULES (R-APP-*)

### R-APP-005: Fail-Closed Device Integrity (Phase 10)

- **Rule**: Application MUST perform integrity check on startup (Root check, Attestation Check). If check fails, App MUST enter "Security Violation" state/screen and refuse all operations.
- **Enforcement**: `lib/core/security_guard.dart`, `lib/main.dart`
- **Violation**: "Red Screen of Death" displayed.
- **Rationale**: Compromised OS cannot be trusted to handle Sovereign Identity.
- **Chains**: Chain 7 (Attestation)


## PRIVACY RULES (R-PRIV-*)

### R-PRIV-001: Zero-Knowledge Backend

- **Rule**: Backend MUST NEVER receive or store user PII in plaintext. Only commitments and linkage tags allowed.
- **Enforcement**: All database schemas (`backend/migrations/`), API request validation
- **Violation**: Code review failure. Database migration rejected.
- **Rationale**: Zero-knowledge property guarantees backend cannot correlate identity across sessions.
- **Chains**: Chain 2 (Entitlements - selective disclosure), Chain 6 (Audit)
- **Code Example**:
```sql
-- backend/migrations/001_create_anchors.sql
CREATE TABLE anchors (
    device_did VARCHAR(255) PRIMARY KEY,
    commitment_hash BYTEA NOT NULL,  -- Commitment, not plaintext ID
    attestation_spki BYTEA NOT NULL,
    registered_at TIMESTAMP DEFAULT NOW()
);
-- NO columns for name, email, SSN, etc.
```

### R-PRIV-002: K-Anonymity Threshold

- **Rule**: Aggregated statistics MUST include ≥15 unique identities. Reject queries below threshold.
- **Enforcement**: `backend/src/miner.rs` (privacy miner)
- **Violation**: Query returns error "Insufficient data for k-anonymity"
- **Rationale**: K-anonymity prevents individual re-identification in aggregate data.
- **Chains**: Chain 6 (Audit - privacy-preserving analytics)
- **Code Example**:
```rust
// backend/src/miner.rs
const K_ANONYMITY_THRESHOLD: usize = 15;

pub async fn get_aggregate_stats(db: &Db, query: &str) -> Result<Stats, String> {
    let unique_count = db.count_unique_identities(query).await?;
    if unique_count < K_ANONYMITY_THRESHOLD {
        return Err("Insufficient data for k-anonymity (need ≥15 unique IDs)".to_string());
    }
    // ... return aggregated stats with ε-differential privacy noise
}
```

### R-PRIV-003: Differential Privacy Noise

- **Rule**: Aggregate statistics MUST add Laplace noise with ε=1.0. MUST NOT return raw counts.
- **Enforcement**: `backend/src/miner.rs` (Laplace mechanism)
- **Violation**: Query rejected. Audit log entry created.
- **Rationale**: ε-differential privacy prevents membership inference attacks.
- **Chains**: Chain 6 (Audit - privacy-preserving analytics)

### R-PRIV-004: Audit Log Anonymization

- **Rule**: Audit logs MUST use `H(linkage_tag || audit_salt)` instead of linkage tag. Salt rotated monthly.
- **Enforcement**: `backend/src/bin/oidc_service.rs:603-613`
- **Violation**: Raw linkage tags in logs rejected by audit review.
- **Rationale**: Even linkage tags can enable correlation across audit queries.
- **Chains**: Chain 6 (Audit - privacy-preserving logs)
- **Code Example**:
```rust
// backend/src/bin/oidc_service.rs:603-613
let audit_salt = std::env::var("AUDIT_SALT").unwrap_or_default();
let mut hasher = Sha256::new();
hasher.update(&linkage_tag);
hasher.update(audit_salt.as_bytes());
let audit_id = hasher.finalize();

db.log_audit_event("credential_verification", &audit_id).await?;
// linkage_tag NEVER logged directly
```

### R-PRIV-005: Selective Disclosure Validation

- **Rule**: Proof MUST reveal only explicitly requested attributes. Verifier MUST reject proofs revealing unrequested data.
- **Enforcement**: `backend/src/bin/oidc_service.rs:409-637` (verify_proof_handler)
- **Violation**: 400 Bad Request with error "Proof reveals unrequested attributes"
- **Rationale**: Prevents over-disclosure attacks where malicious verifier requests all attributes.
- **Chains**: Chain 2 (Entitlements - selective disclosure)
- **Code Example**:
```rust
// backend/src/bin/oidc_service.rs:520-540
let requested_indices: HashSet<usize> = proof_req.requested_attributes.iter().cloned().collect();
let revealed_indices: HashSet<usize> = revealed_msgs.iter().map(|(i, _)| *i).collect();

if revealed_indices != requested_indices {
    return Err((StatusCode::BAD_REQUEST, "Proof reveals unrequested attributes".to_string()));
}
```

### R-PRIV-006: Linkage Tag Unlinkability

- **Rule**: Linkage tags MUST be unique per credential instance. Same user with multiple credentials MUST have different tags.
- **Enforcement**: `backend/src/lib.rs:62-68` (compute_linkage_tag with random blinding)
- **Violation**: Linkage tag collision rejected during credential issuance.
- **Rationale**: Prevents cross-session correlation via linkage tag.
- **Chains**: Chain 1 (Lifecycle), Chain 6 (Audit)

---

## REVOCATION RULES (R-REV-*)

### R-REV-001: Graveyard Append-Only

- **Rule**: Revocations table MUST be append-only. MUST NOT allow DELETE or UPDATE operations.
- **Enforcement**: Database schema (`backend/migrations/002_create_revocations.sql`)
- **Violation**: Database migration rejected. Audit alert triggered.
- **Rationale**: Revocation history is permanent. Deletion allows resurrection of revoked credentials.
- **Chains**: Chain 1 (Lifecycle - revocation)
- **Code Example**:
```sql
-- backend/migrations/002_create_revocations.sql
CREATE TABLE revocations (
    linkage_tag BYTEA PRIMARY KEY,
    revoked_at TIMESTAMP DEFAULT NOW(),
    reason TEXT NOT NULL
);
-- NO DELETE grants. Only INSERT allowed.
REVOKE DELETE ON revocations FROM backend_user;
```

### R-REV-002: Revocation Check Before Verification

- **Rule**: L2+ assurance MUST check revocation status before accepting proof. L1 may skip (signature-only).
- **Enforcement**: `backend/src/bin/oidc_service.rs:584-597`
- **Violation**: Revoked credential accepted (security breach). Audit alert.
- **Rationale**: L2 assurance guarantees credential not revoked. L1 is signature-only (no revocation guarantee).
- **Chains**: Chain 2 (Entitlements - L2+ verification)
- **Code Example**:
```rust
// backend/src/bin/oidc_service.rs:584-597
if assurance_level >= 2 {
    match state.db.is_tag_revoked(&linkage_tag).await {
        Ok(true) => return Err((StatusCode::FORBIDDEN, "Credential revoked".to_string())),
        Ok(false) => { /* Continue */ }
        Err(e) => {
            // Fail-closed: Reject on DB error
            return Err((StatusCode::INTERNAL_SERVER_ERROR, format!("Revocation check failed: {}", e)));
        }
    }
}
```

### R-REV-003: Admin Revocation Authorization

- **Rule**: Manual revocation via `/api/admin/revoke` MUST require valid admin token AND audit log entry.
- **Enforcement**: `backend/src/bin/oidc_service.rs:888-913` (admin_revoke endpoint)
- **Violation**: 403 Forbidden. Audit log records unauthorized attempt.
- **Rationale**: Revocation is irreversible. Requires strong authorization and audit trail.
- **Chains**: Chain 1 (Lifecycle - admin actions)
- **Code Example**:
```rust
// backend/src/bin/oidc_service.rs:888-913
async fn admin_revoke(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<RevokeRequest>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    // 1. Verify admin token (R-PROTO-006)
    verify_admin_token(&headers)?;

    // 2. Revoke credential
    state.db.revoke_tag(&req.linkage_tag, &req.reason).await?;

    // 3. Audit log (MANDATORY)
    state.db.log_audit_event("admin_revocation", &req.linkage_tag).await?;

    Ok(Json(json!({"status": "revoked"})))
}
```

### R-REV-004: Recovery-Triggered Revocation

- **Rule**: Successful recovery via Shamir shares MUST auto-revoke old credential. Old and new credentials MUST NOT coexist.
- **Enforcement**: `backend/src/bin/oidc_service.rs:1107-1156` (recover endpoint)
- **Violation**: Recovery rejected if old credential still valid.
- **Rationale**: Device loss means old credential compromised. Auto-revocation prevents dual identity.
- **Chains**: Chain 5 (Recovery - sovereign identity)
- **Code Example**:
```rust
// backend/src/bin/oidc_service.rs:1107-1156
async fn recover(
    State(state): State<AppState>,
    Json(req): Json<RecoveryRequest>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    // 1. Reconstruct master key from k-of-n shares
    let master_key = shamir_reconstruct(&req.shares)?;

    // 2. Derive old linkage tag
    let old_tag = compute_linkage_tag(&master_key, &req.anchor_id);

    // 3. AUTO-REVOKE old credential
    state.db.revoke_tag(&old_tag, "Device recovery - old credential invalidated").await?;

    // 4. Issue new credential
    let new_credential = issue_credential(&state, &req.new_device_pubkey).await?;

    Ok(Json(json!({"new_credential": new_credential})))
}
```

---

## LEASING RULES (R-LEASE-*)

### R-LEASE-001: Delegation Token Expiration

- **Rule**: Delegation tokens MUST have expiration timestamp. Expired tokens MUST be rejected.
- **Enforcement**: `backend/src/bin/oidc_service.rs:957-1104` (verify_delegated endpoint)
- **Violation**: 401 Unauthorized with error "Delegation token expired"
- **Rationale**: Offline delegation has no server-side revocation. Expiration limits compromise window.
- **Chains**: Chain 9 (Leasing - offline sudo)
- **Code Example**:
```rust
// backend/src/bin/oidc_service.rs:980-995
let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs();
if delegation_token.expiration < now {
    return Err((StatusCode::UNAUTHORIZED, "Delegation token expired".to_string()));
}
```

### R-LEASE-002: Maximum Passages Limit

- **Rule**: Delegation tokens MUST enforce max_passages limit. Each usage decrements counter.
- **Enforcement**: Client-side tracking (multipass app), server validates in offline mode
- **Violation**: Token rejected after max_passages reached.
- **Rationale**: Limits damage from stolen delegation token.
- **Chains**: Chain 9 (Leasing)
- **Code Example**:
```rust
// backend/src/lib.rs:577-686
pub struct DelegationToken {
    pub anchor_id: Vec<u8>,
    pub mobile_pubkey: Vec<u8>,
    pub tier: u8,
    pub expiration: u64,
    pub max_passages: u32,  // Enforced by client and verifier
    pub signature: Vec<u8>,
}
```

### R-LEASE-003: Biometric Authorization Required

- **Rule**: Delegation usage MUST require biometric approval on phone. Phone TEE validates biometric before signing.
- **Enforcement**: Client-side (multipass app), TEE validates biometric before releasing key
- **Violation**: Phone refuses to sign without biometric. Delegation fails.
- **Rationale**: Offline delegation could bypass anchor PIN. Biometric provides second factor.
- **Chains**: Chain 9 (Leasing - biometric binding)

### R-LEASE-004: Anchor Revocation Cascade

- **Rule**: Revoking root anchor MUST invalidate ALL delegation tokens issued by that anchor.
- **Enforcement**: `backend/src/bin/oidc_service.rs:1016-1027`
- **Violation**: Revoked anchor's delegations accepted (security breach).
- **Rationale**: Anchor compromise means all delegations compromised.
- **Chains**: Chain 1 (Lifecycle - revocation), Chain 9 (Leasing)
- **Code Example**:
```rust
// backend/src/bin/oidc_service.rs:1016-1027
async fn verify_delegated(
    State(state): State<AppState>,
    Json(req): Json<DelegatedRequest>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    // 1. Verify delegation token signature
    verify_delegation_signature(&req.delegation_token)?;

    // 2. Check if root anchor revoked (CASCADE CHECK)
    let anchor_tag = compute_anchor_linkage_tag(&req.delegation_token.anchor_id);
    if state.db.is_tag_revoked(&anchor_tag).await? {
        return Err((StatusCode::FORBIDDEN, "Root anchor revoked - all delegations invalid".to_string()));
    }

    // 3. Proceed with delegated verification
    // ...
}
```

### R-LEASE-005: Delegation Tier Enforcement

- **Rule**: Delegation tier MUST NOT exceed anchor tier. Tier downgrades allowed, upgrades rejected.
- **Enforcement**: `backend/src/lib.rs:577-686` (create_delegation_token)
- **Violation**: Delegation token creation rejected.
- **Rationale**: Prevents privilege escalation via delegation.
- **Chains**: Chain 9 (Leasing)
- **Code Example**:
```rust
// backend/src/lib.rs:620-635
pub fn create_delegation_token(
    anchor_tier: u8,
    delegation_tier: u8,
    // ... other params
) -> Result<DelegationToken, String> {
    if delegation_tier > anchor_tier {
        return Err("Delegation tier cannot exceed anchor tier".to_string());
    }
    // ... create token
}
```

---

## RECOVERY RULES (R-REC-*)

### R-REC-001: Share Distribution Safety

- **Rule**: Shamir shares MUST be distributed via distinct channels (email, SMS, print, USB). MUST NOT send all shares via single channel.
- **Enforcement**: Client-side UI, user education (not server-enforced)
- **Violation**: User warned during share distribution.
- **Rationale**: Single channel compromise should not enable full recovery.
- **Chains**: Chain 5 (Recovery - sovereign identity)

### R-REC-002: Recovery Requires K-of-N

- **Rule**: Recovery MUST require exactly k valid shares. k-1 shares MUST be insufficient.
- **Enforcement**: `backend/src/lib.rs:690-747` (shamir_reconstruct)
- **Violation**: Reconstruction fails. Returns error.
- **Rationale**: Threshold cryptography guarantees k-1 shares reveal no information.
- **Chains**: Chain 5 (Recovery)
- **Code Example**:
```rust
// backend/src/lib.rs:720-747
pub fn shamir_reconstruct(shares: &[Vec<u8>]) -> Result<Vec<u8>, String> {
    if shares.len() < MIN_THRESHOLD {
        return Err(format!("Insufficient shares: need at least {}", MIN_THRESHOLD));
    }
    // Lagrange interpolation to reconstruct secret
    // ...
}
```

### R-REC-003: Old Credential Auto-Revocation

- **Rule**: (Duplicate of R-REV-004 - see above)
- Recovery MUST auto-revoke old credential before issuing new one.
- **Enforcement**: `backend/src/bin/oidc_service.rs:1107-1156`
- **Chains**: Chain 5 (Recovery), Chain 1 (Lifecycle)

---

## OPERATIONAL RULES (R-OPS-*)

### R-OPS-001: Bootstrap Idempotency

- **Rule**: `/api/admin/bootstrap` MUST be idempotent. Multiple calls with same root anchor MUST succeed without duplication.
- **Enforcement**: `backend/src/bin/oidc_service.rs` (bootstrap_root endpoint)
- **Violation**: 409 Conflict if root already exists (not an error, just notification).
- **Rationale**: Deployment scripts may retry bootstrap. Idempotency prevents duplicate roots.
- **Chains**: N/A (operational)

### R-OPS-002: Key Rotation Atomicity

- **Rule**: `/api/admin/rotate_keys` MUST be atomic. Either all keys rotated or none. MUST NOT leave partial state.
- **Enforcement**: Database transaction wrapping key rotation
- **Violation**: Transaction rollback. Error returned.
- **Rationale**: Partial key rotation breaks all existing credentials.
- **Chains**: Chain 1 (Lifecycle), Chain 2 (Entitlements)

### R-OPS-003: Invite One-Time Use

- **Rule**: Invite codes MUST be single-use. Redemption MUST mark invite as redeemed atomically.
- **Enforcement**: `backend/src/bin/oidc_service.rs` (redeem_invite), database constraint
- **Violation**: 409 Conflict with error "Invite already redeemed"
- **Rationale**: Prevents invite code sharing.
- **Chains**: N/A (operational)
- **Code Example**:
```sql
-- backend/migrations/003_create_invites.sql
CREATE TABLE invites (
    code VARCHAR(32) PRIMARY KEY,
    batch_id VARCHAR(64) NOT NULL,
    redeemed_at TIMESTAMP NULL,
    redeemed_by VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT one_time_use CHECK (redeemed_at IS NULL OR redeemed_by IS NOT NULL)
);
```

### R-OPS-004: Health Check Independence

- **Rule**: `/health` endpoint MUST NOT depend on database or external services. MUST return 200 even if DB down.
- **Enforcement**: `backend/src/bin/oidc_service.rs:235` (health_check)
- **Violation**: Health check fails. Load balancer removes instance from pool.
- **Rationale**: Health check determines instance liveness. DB issues should not mark instance unhealthy.
- **Chains**: N/A (operational)
- **Code Example**:
```rust
// backend/src/bin/oidc_service.rs:300-305
async fn health_check() -> impl IntoResponse {
    // Simple liveness check - no DB dependency
    (StatusCode::OK, "OK")
}
```

---

## RATE LIMITING RULES (R-RATE-*)

### R-RATE-001: Admin Login Rate Limit

- **Rule**: `/api/admin/login` MUST enforce 5 requests per minute burst, 1 request per 12 seconds sustained.
- **Enforcement**: `backend/src/bin/oidc_service.rs:268` (Governor middleware)
- **Violation**: 429 Too Many Requests
- **Rationale**: Admin login is high-value target. Rate limiting prevents brute force.
- **Chains**: N/A (operational security)
- **Code Example**:
```rust
// backend/src/bin/oidc_service.rs:268-275
let governor_conf = Box::new(
    GovernorConfigBuilder::default()
        .per_second(1) // 1 req per second sustained
        .burst_size(5) // 5 req burst
        .finish()
        .unwrap()
);
let governor_limiter = governor_conf.limiter().clone();
let governor_layer = GovernorLayer { config: Box::leak(governor_conf) };
```

### R-RATE-002: Global API Rate Limit

- **Rule**: All public API endpoints SHOULD enforce 100 req/min per IP. Internal endpoints exempt.
- **Enforcement**: Reverse proxy (nginx/CloudFlare) level
- **Violation**: 429 Too Many Requests
- **Rationale**: Prevents DoS attacks on public endpoints.
- **Chains**: N/A (operational security)

### R-RATE-003: Nonce Generation Rate Limit

- **Rule**: `/api/oidc/nonce` MUST enforce 10 req/min per IP.
- **Enforcement**: Application-level rate limiter
- **Violation**: 429 Too Many Requests
- **Rationale**: Nonce generation is stateful (DB insert). Prevents resource exhaustion.
- **Chains**: Chain 2 (Entitlements - anti-replay)

---

## ERROR HANDLING RULES (R-ERR-*)

### R-ERR-001: Fail-Closed on Database Errors

- **Rule**: Database errors during security checks (revocation, nonce) MUST reject request. MUST NOT assume safe.
- **Enforcement**: All verification endpoints
- **Violation**: Request accepted despite DB error (security breach).
- **Rationale**: Fail-open allows bypassing revocation checks.
- **Chains**: All chains
- **Code Example**:
```rust
// backend/src/bin/oidc_service.rs:584-597
match state.db.is_tag_revoked(&linkage_tag).await {
    Ok(true) => return Err((StatusCode::FORBIDDEN, "Credential revoked".to_string())),
    Ok(false) => { /* Continue */ }
    Err(e) => {
        // FAIL-CLOSED: Reject on DB error
        eprintln!("[ERROR] Revocation check failed: {}", e);
        return Err((StatusCode::INTERNAL_SERVER_ERROR, "Revocation check failed".to_string()));
    }
}
```

### R-ERR-002: No Sensitive Info in Error Messages

- **Rule**: Error messages MUST NOT reveal sensitive information (stack traces, DB schema, key material).
- **Enforcement**: All error handling code
- **Violation**: Information disclosure vulnerability.
- **Rationale**: Error messages visible to attackers. Detailed errors aid reconnaissance.
- **Chains**: All endpoints
- **Code Example**:
```rust
// BAD: Reveals DB schema
return Err(format!("Database error: {}", db_error));

// GOOD: Generic error
return Err("Internal server error".to_string());
```

### R-ERR-003: Audit Log on Security Failures

- **Rule**: Failed authentication, authorization, or verification MUST log audit event with anonymized identity.
- **Enforcement**: All security-critical endpoints
- **Violation**: Missing audit trail for security incidents.
- **Rationale**: Audit logs enable forensic analysis and intrusion detection.
- **Chains**: Chain 6 (Audit)

### R-ERR-004: Timeout on Long-Running Operations

- **Rule**: All HTTP requests MUST timeout after 30 seconds. Long operations MUST use async polling pattern.
- **Enforcement**: `backend/src/bin/oidc_service.rs:226` (TimeoutLayer middleware)
- **Violation**: 408 Request Timeout
- **Rationale**: Prevents resource exhaustion from slow clients.
- **Chains**: N/A (operational)
- **Code Example**:
```rust
// backend/src/bin/oidc_service.rs:226
let timeout_layer = TimeoutLayer::new(Duration::from_secs(30));
```

---

## MONITORING RULES (R-MON-*)

### R-MON-001: Metrics Export

- **Rule**: Server MUST export Prometheus metrics at `/metrics` endpoint. Metrics MUST include request latency, error rates, revocation count.
- **Enforcement**: Metrics middleware (future implementation)
- **Violation**: Missing observability. Incident response delayed.
- **Rationale**: Production monitoring requires structured metrics.
- **Chains**: N/A (operational)

### R-MON-002: Structured Logging

- **Rule**: All log entries MUST be structured JSON. MUST include timestamp, level, component, trace_id.
- **Enforcement**: Logging framework configuration
- **Violation**: Unstructured logs difficult to parse.
- **Rationale**: Structured logs enable automated analysis and alerting.
- **Chains**: N/A (operational)

### R-MON-003: Alert on Anomalies

- **Rule**: System MUST alert on: spike in revocations, high error rate (>5%), failed attestations (>10%).
- **Enforcement**: Monitoring system (e.g., Grafana alerts)
- **Violation**: Attacks or failures go unnoticed.
- **Rationale**: Early detection enables rapid incident response.
- **Chains**: N/A (operational)

---

## DATA RULES (R-DATA-*)

### R-DATA-001: Migration Reversibility

- **Rule**: All database migrations MUST be reversible (have `down` migration). Exceptions require approval.
- **Enforcement**: Migration files in `backend/migrations/`
- **Violation**: Migration rejected during code review.
- **Rationale**: Enables safe rollback during failed deployments.
- **Chains**: N/A (operational)

### R-DATA-002: No Plaintext PII

- **Rule**: (Duplicate of R-PRIV-001) Database MUST NOT store plaintext PII.
- See R-PRIV-001 for details.

### R-DATA-003: Parameterized Queries Only

- **Rule**: MUST use sqlx parameterized queries. MUST NOT concatenate user input into SQL strings.
- **Enforcement**: All database access code
- **Violation**: SQL injection vulnerability. Code review failure.
- **Rationale**: Prevents SQL injection attacks.
- **Chains**: All database-backed endpoints
- **Code Example**:
```rust
// GOOD: Parameterized query
sqlx::query("SELECT * FROM anchors WHERE device_did = $1")
    .bind(device_id)
    .fetch_one(&pool)
    .await

// BAD: String concatenation (SQL INJECTION!)
sqlx::query(&format!("SELECT * FROM anchors WHERE device_did = '{}'", device_id))
```

### R-DATA-004: Backup Encryption

- **Rule**: Database backups MUST be encrypted at rest using AES-256-GCM. Backup keys stored in separate HSM.
- **Enforcement**: Backup infrastructure configuration
- **Violation**: Plaintext backups rejected. Compliance failure.
- **Rationale**: Database contains sensitive commitments and linkage tags.
- **Chains**: N/A (operational security)

---

## API RULES (R-API-*)

### R-API-001: Versioned Endpoints

- **Rule**: All API endpoints SHOULD include version prefix (e.g., `/api/v1/...`). Breaking changes MUST increment version.
- **Enforcement**: Route definitions
- **Violation**: Client compatibility breaks.
- **Rationale**: Enables backward compatibility during API evolution.
- **Chains**: N/A (operational)

### R-API-002: Content-Type Validation

- **Rule**: POST/PUT endpoints MUST validate `Content-Type: application/json` header. Reject other types.
- **Enforcement**: Axum framework automatically validates
- **Violation**: 415 Unsupported Media Type
- **Rationale**: Prevents MIME confusion attacks.
- **Chains**: All POST/PUT endpoints

### R-API-003: HTTPS Only in Production

- **Rule**: Production MUST enforce HTTPS. HTTP requests MUST redirect to HTTPS.
- **Enforcement**: Reverse proxy (nginx/CloudFlare)
- **Violation**: Plaintext traffic intercepted. MitM attack possible.
- **Rationale**: Prevents credential interception.
- **Chains**: All endpoints

### R-API-004: Request Size Limits

- **Rule**: Request body MUST NOT exceed 1MB. Large payloads MUST use multipart upload.
- **Enforcement**: Axum `DefaultBodyLimit` middleware
- **Violation**: 413 Payload Too Large
- **Rationale**: Prevents memory exhaustion from large requests.
- **Chains**: N/A (operational)

### R-API-005: JWKS Caching

- **Rule**: `/.well-known/jwks.json` MUST have `Cache-Control: max-age=3600` header.
- **Enforcement**: `backend/src/bin/oidc_service.rs:237` (jwks endpoint)
- **Violation**: Excessive JWKS requests. Performance degradation.
- **Rationale**: JWKS changes infrequently. Caching reduces load.
- **Chains**: Chain 4 (Discovery)

---

## ENDPOINT-TO-RULES MAPPING

Complete mapping of all API endpoints to applicable rules.

| Endpoint | Method | Chains | Rules | Assurance |
|----------|--------|--------|-------|-----------|
| `/health` | GET | - | R-OPS-004 | N/A |
| `/.well-known/openid-configuration` | GET | Chain 4 | R-PROTO-004, R-API-001 | N/A |
| `/.well-known/jwks.json` | GET | Chain 4 | R-API-005 | N/A |
| `/.well-known/openid-credential-issuer` | GET | Chain 4 | R-PROTO-004 | N/A |
| `/api/oidc/nonce` | GET | Chain 2 | R-PROTO-001, R-RATE-003 | N/A |
| `/api/oidc/credential` | GET | Chain 1 | R-PROTO-005 | N/A |
| `/api/oidc/token` | POST | Chain 1 | R-CRYPTO-001, R-CRYPTO-002, R-CRYPTO-003 | N/A |
| `/api/oidc/verify` | POST | Chain 2 | R-PROTO-001, R-PROTO-002, R-PROTO-003, R-CRYPTO-006, R-REV-002, R-PRIV-005 | L1-L4 |
| `/api/oidc/verify_delegated` | POST | Chain 9 | R-LEASE-001, R-LEASE-002, R-LEASE-004 | L2+ |
| `/api/oidc/recover` | POST | Chain 7 | R-REC-002, R-REC-003, R-REV-004 | N/A |
| `/api/oidc/logout` | POST | - | - | N/A |
| `/api/oidc/userinfo` | GET | - | R-PRIV-001 | N/A |
| `/api/oidc/register` | POST | - | - | N/A |
| `/api/vci/offer` | POST | Chain 1 | R-PROTO-005 | N/A |
| `/api/vp/request` | POST | Chain 2 | R-PRIV-005 | N/A |
| `/api/vp/verify` | POST | Chain 2 | R-PROTO-001, R-PROTO-002, R-CRYPTO-006, R-REV-002 | L1-L4 |
| `/api/mobile/register` | POST | Chain 3 | R-HW-001, R-HW-002 | N/A |
| `/api/anchor/register` | POST | Chain 3 | R-HW-003 | N/A |
| `/api/anchor/heartbeat` | POST | - | - | N/A |
| `/api/admin/stats` | GET | Chain 6 | R-PROTO-006, R-PRIV-002, R-PRIV-003 | N/A |
| `/api/admin/revoke` | POST | Chain 1 | R-PROTO-006, R-REV-001, R-REV-003 | N/A |
| `/api/admin/bootstrap` | POST | - | R-PROTO-006, R-OPS-001 | N/A |
| `/api/admin/login` | POST | - | R-PROTO-006, R-RATE-001, R-CRYPTO-006 | L2 |
| `/api/admin/rotate_keys` | POST | Chain 1 | R-PROTO-006, R-OPS-002 | N/A |
| `/api/invite/validate` | POST | - | - | N/A |
| `/api/invite/redeem` | POST | - | R-OPS-003 | N/A |
| `/api/invite/create` | POST | - | R-PROTO-006 | N/A |
| `/api/auth/init` | POST | Chain 9 | R-LEASE-003 | N/A |
| `/api/auth/poll` | GET | Chain 9 | - | N/A |
| `/api/auth/approve` | POST | Chain 9 | R-LEASE-003 | N/A |

---

## FEATURE-TO-RULES MAPPING

Mapping of system features to governing rules.

| Feature | Description | Rules | Chains |
|---------|-------------|-------|--------|
| Credential Issuance | BBS+ credential creation | R-CRYPTO-001, R-CRYPTO-002, R-CRYPTO-003, R-PROTO-005 | Chain 1, 2 |
| ZKP Verification | Selective disclosure proof verification | R-CRYPTO-006, R-PROTO-001, R-PROTO-002, R-PROTO-003, R-PRIV-005 | Chain 2 |
| Revocation Check | Graveyard lookup | R-REV-001, R-REV-002, R-ERR-001 | Chain 1, 2 |
| Device Attestation | Hardware key verification | R-HW-001, R-HW-002 | Chain 3 |
| Entropy Harvesting | AAL3 entropy generation | R-CRYPTO-004 | Chain 5 |
| Delegation Tokens | Offline sudo | R-LEASE-001, R-LEASE-002, R-LEASE-003, R-LEASE-004, R-LEASE-005 | Chain 9 |
| Recovery | Shamir secret sharing | R-REC-001, R-REC-002, R-REC-003, R-CRYPTO-008 | Chain 7 |
| Audit Logs | Privacy-preserving logging | R-PRIV-004, R-MON-002, R-ERR-003 | Chain 6 |
| Admin Login | ZKP-based authentication | R-PROTO-006, R-RATE-001, R-CRYPTO-006 | - |
| K-Anonymity | Aggregate statistics | R-PRIV-002, R-PRIV-003 | Chain 6 |
| Invite System | Onboarding codes | R-OPS-003 | - |
| Key Rotation | Issuer key update | R-OPS-002 | Chain 1 |
| Nonce Management | Anti-replay | R-PROTO-001, R-RATE-003 | Chain 2 |
| JavaCard Anchor | Hardware root of trust | R-HW-003, R-HW-004 | Chain 3 |

---

## RULE-TO-CHAIN MAPPING

How rules integrate with the 9 trust chains documented in CHAINS.md.

| Chain | Chain Name | Primary Rules |
|-------|------------|---------------|
| Chain 1 | Lifecycle Management | R-REV-001, R-REV-002, R-REV-003, R-REV-004, R-CRYPTO-002, R-PROTO-005, R-OPS-002 |
| Chain 2 | Entitlements & ZKP | R-CRYPTO-001, R-CRYPTO-003, R-CRYPTO-006, R-PROTO-001, R-PROTO-002, R-PROTO-003, R-PRIV-005 |
| Chain 3 | Device Binding | R-HW-001, R-HW-002, R-HW-003, R-HW-004, R-CRYPTO-004 |
| Chain 4 | Discovery | R-PROTO-004, R-API-005 |
| Chain 5 | Freshness | R-PROTO-002, R-CRYPTO-004 |
| Chain 6 | Audit | R-PRIV-001, R-PRIV-002, R-PRIV-003, R-PRIV-004, R-MON-001, R-MON-002, R-MON-003, R-ERR-003 |
| Chain 7 | Recovery | R-REC-001, R-REC-002, R-REC-003, R-CRYPTO-008, R-REV-004 |
| Chain 9 | Leasing | R-LEASE-001, R-LEASE-002, R-LEASE-003, R-LEASE-004, R-LEASE-005, R-CRYPTO-007 |

**Note**: Chain 8 (Presentation Exchange) not yet implemented - rules TBD.

---

## CODE LOCATION INDEX

Where each rule is enforced in the codebase.

### Cryptographic Rules

| Rule | Primary Location | Secondary Locations |
|------|------------------|---------------------|
| R-CRYPTO-001 | `backend/Cargo.toml:dependencies` | All crypto imports |
| R-CRYPTO-002 | `backend/src/bin/oidc_service.rs:124-150` | Startup validation |
| R-CRYPTO-003 | `backend/src/lib.rs:109-164`, `backend/src/lib.rs:269-350` | All BBS+ functions |
| R-CRYPTO-004 | `backend/src/periwinkle.rs:33-66` | Entropy functions |
| R-CRYPTO-005 | `backend/src/lib.rs:62-68` | Linkage tag computation |
| R-CRYPTO-006 | `backend/src/lib.rs:372-555` | All verification endpoints |
| R-CRYPTO-007 | `backend/src/lib.rs:577-686` | Delegation endpoints |
| R-CRYPTO-008 | `backend/src/lib.rs:690-747` | Recovery endpoint |

### Protocol Rules

| Rule | Primary Location | Secondary Locations |
|------|------------------|---------------------|
| R-PROTO-001 | `backend/src/bin/oidc_service.rs:341-361`, `417-434` | All verification endpoints |
| R-PROTO-002 | `backend/src/bin/oidc_service.rs:490-510` | All verification endpoints |
| R-PROTO-003 | `backend/src/bin/oidc_service.rs:409-637` | Verification handler |
| R-PROTO-004 | `backend/src/bin/oidc_service.rs:311-337` | Discovery endpoint |
| R-PROTO-005 | `backend/src/bin/oidc_service.rs:844-887` | Issuance endpoint |
| R-PROTO-006 | All `/api/admin/*` endpoints | Admin middleware |
| R-PROTO-007 | `backend/src/bin/oidc_service.rs:230-234` | CORS middleware |

### Hardware Rules

| Rule | Primary Location | Secondary Locations |
|------|------------------|---------------------|
| R-HW-001 | `backend/src/attestation.rs:23-31` | Mobile registration |
| R-HW-002 | `backend/src/attestation.rs:38-52` | Attestation verification |
| R-HW-003 | `anchor/SpookyIDApplet.java` | JavaCard applet |
| R-HW-004 | `anchor/SpookyIDApplet.java:APDU_VERIFY_PIN` | PIN verification |
| R-HW-005 | `backend/src/bin/oidc_service.rs:124-150` | Key loading |

### Privacy Rules

| Rule | Primary Location | Secondary Locations |
|------|------------------|---------------------|
| R-PRIV-001 | `backend/migrations/` | All schemas |
| R-PRIV-002 | `backend/src/miner.rs` | Stats endpoints |
| R-PRIV-003 | `backend/src/miner.rs` | Aggregate functions |
| R-PRIV-004 | `backend/src/bin/oidc_service.rs:603-613` | Audit logging |
| R-PRIV-005 | `backend/src/bin/oidc_service.rs:520-540` | Verification endpoints |
| R-PRIV-006 | `backend/src/lib.rs:62-68` | Credential issuance |

### Revocation Rules

| Rule | Primary Location | Secondary Locations |
|------|------------------|---------------------|
| R-REV-001 | `backend/migrations/002_create_revocations.sql` | Database schema |
| R-REV-002 | `backend/src/bin/oidc_service.rs:584-597` | All L2+ verification |
| R-REV-003 | `backend/src/bin/oidc_service.rs:888-913` | Admin revoke endpoint |
| R-REV-004 | `backend/src/bin/oidc_service.rs:1107-1156` | Recovery endpoint |

### Leasing Rules

| Rule | Primary Location | Secondary Locations |
|------|------------------|---------------------|
| R-LEASE-001 | `backend/src/bin/oidc_service.rs:980-995` | Delegated verification |
| R-LEASE-002 | `backend/src/lib.rs:577-686` | Token structure |
| R-LEASE-003 | `multipass/src/lib.rs` | Client-side biometric |
| R-LEASE-004 | `backend/src/bin/oidc_service.rs:1016-1027` | Cascade check |
| R-LEASE-005 | `backend/src/lib.rs:620-635` | Token creation |

### Recovery Rules

| Rule | Primary Location | Secondary Locations |
|------|------------------|---------------------|
| R-REC-001 | `multipass/src/lib.rs` | Client UI |
| R-REC-002 | `backend/src/lib.rs:720-747` | Reconstruction |
| R-REC-003 | `backend/src/bin/oidc_service.rs:1107-1156` | Recovery endpoint |

### Operational Rules

| Rule | Primary Location | Secondary Locations |
|------|------------------|---------------------|
| R-OPS-001 | `backend/src/bin/oidc_service.rs` | Bootstrap endpoint |
| R-OPS-002 | `backend/src/bin/oidc_service.rs` | Key rotation endpoint |
| R-OPS-003 | `backend/src/bin/oidc_service.rs` | Invite redemption |
| R-OPS-004 | `backend/src/bin/oidc_service.rs:300-305` | Health endpoint |

### Rate Limiting Rules

| Rule | Primary Location | Secondary Locations |
|------|------------------|---------------------|
| R-RATE-001 | `backend/src/bin/oidc_service.rs:268-275` | Governor middleware |
| R-RATE-002 | Reverse proxy config | nginx/CloudFlare |
| R-RATE-003 | Application middleware | Nonce endpoint |

### Error Handling Rules

| Rule | Primary Location | Secondary Locations |
|------|------------------|---------------------|
| R-ERR-001 | All verification endpoints | DB error handling |
| R-ERR-002 | All error handlers | Response formatting |
| R-ERR-003 | All security endpoints | Audit logging |
| R-ERR-004 | `backend/src/bin/oidc_service.rs:226` | Timeout middleware |

### Monitoring Rules

| Rule | Primary Location | Secondary Locations |
|------|------------------|---------------------|
| R-MON-001 | Future: `/metrics` endpoint | Prometheus exporter |
| R-MON-002 | Logging configuration | All log calls |
| R-MON-003 | Monitoring system | Grafana alerts |

### Data Rules

| Rule | Primary Location | Secondary Locations |
|------|------------------|---------------------|
| R-DATA-001 | `backend/migrations/` | All migrations |
| R-DATA-002 | Database schemas | All tables |
| R-DATA-003 | All database code | sqlx queries |
| R-DATA-004 | Backup infrastructure | DBA procedures |

### API Rules

| Rule | Primary Location | Secondary Locations |
|------|------------------|---------------------|
| R-API-001 | Route definitions | All endpoints |
| R-API-002 | Axum middleware | POST/PUT handlers |
| R-API-003 | Reverse proxy | TLS termination |
| R-API-004 | Axum middleware | Body limit |
| R-API-005 | `backend/src/bin/oidc_service.rs:237` | JWKS endpoint |

---

## MAINTENANCE PROCEDURES

### Adding a New Rule

When adding new functionality that requires security/business constraints:

1. **Identify Category**: Choose appropriate R-* prefix
2. **Assign Number**: Use next available number in category
3. **Document Rule**: Follow template exactly
4. **Map to Code**: Add enforcement location(s)
5. **Update Mappings**: Add to endpoint/feature/chain tables
6. **Update SPEC.md**: Reference rule in affected API docs
7. **Update CHAINS.md**: If rule affects trust chain flow
8. **Code Review**: New rules require security review

**Template**:
```markdown
### R-CATEGORY-NNN: Rule Name

- **Rule**: MUST/MUST NOT statement
- **Enforcement**: Code location(s)
- **Violation**: What happens
- **Rationale**: Why this rule exists
- **Chains**: Which chains affected
- **Code Example**: Implementation snippet
```

### Modifying an Existing Rule

1. **Check Dependencies**: Search for rule ID in SPEC.md, CHAINS.md, code comments
2. **Update Rule Definition**: Modify constraint, enforcement, or rationale
3. **Update Code**: Ensure enforcement locations match new definition
4. **Update Tests**: Add/modify tests to verify new constraint
5. **Update Documentation**: SPEC.md, CHAINS.md references
6. **Migration Path**: If breaking change, document upgrade path
7. **Security Review**: Modified rules require re-review

### Deprecating a Rule

1. **Mark as Deprecated**: Add `**DEPRECATED**` tag to rule
2. **Specify Replacement**: If applicable, point to new rule
3. **Grace Period**: Keep deprecated rule for 2 releases
4. **Code Cleanup**: Remove enforcement code after grace period
5. **Archive Rule**: Move to `DEPRECATED_RULES.md` (create if needed)

**Example**:
```markdown
### R-CRYPTO-999: Old Crypto Method [DEPRECATED]

**DEPRECATED**: Replaced by R-CRYPTO-001. Will be removed in v2.0.0.

- **Rule**: [Original rule definition]
- **Replacement**: Use R-CRYPTO-001 instead
- **Deprecation Date**: 2026-01-16
- **Removal Date**: 2026-04-01 (v2.0.0)
```

### Verifying Rule Enforcement

**Script**: `scripts/verify_rules.sh`
```bash
#!/bin/bash
# Verify all rules are enforced in code

echo "=== Checking Rule Enforcement ==="

# Extract rule IDs from RULES.md
grep -oP 'R-[A-Z]+-[0-9]+' multipass/Directives/RULES.md | sort -u > /tmp/documented_rules.txt

# Extract rule references from code
grep -rh 'Rule R-' backend/src/ anchor/ multipass/src/ | \
    sed 's/.*Rule \(R-[A-Z]*-[0-9]*\).*/\1/' | \
    sort -u > /tmp/code_rules.txt

echo "Rules documented but not referenced in code:"
comm -23 /tmp/documented_rules.txt /tmp/code_rules.txt

echo ""
echo "Rules referenced in code but not documented:"
comm -13 /tmp/documented_rules.txt /tmp/code_rules.txt

echo ""
echo "=== Checking Endpoint Mappings ==="
# Verify all endpoints in code are in RULES.md mapping table
grep -oP '\.route\("\K[^"]+' backend/src/bin/oidc_service.rs | sort > /tmp/code_endpoints.txt
grep -oP '^\| /[^ ]+' multipass/Directives/RULES.md | sed 's/| //;s/ .*//' | sort > /tmp/doc_endpoints.txt

echo "Endpoints in code but not in RULES.md mapping:"
comm -23 /tmp/code_endpoints.txt /tmp/doc_endpoints.txt

echo ""
echo "=== END VERIFICATION ==="
```

### Rule Review Schedule

**Monthly Review**:
- Verify all rules still accurate
- Check for new enforcement locations
- Update code examples if implementation changed
- Cross-reference with SPEC.md and CHAINS.md

**Quarterly Audit**:
- Security review of cryptographic rules (R-CRYPTO-*)
- Compliance check for privacy rules (R-PRIV-*)
- Performance review of rate limits (R-RATE-*)
- Run `verify_rules.sh` script

**Annual Deep Audit**:
- External security audit of all rules
- Penetration testing against rule violations
- Compliance certification (SOC 2, ISO 27001)
- Update rationales based on threat landscape

---

## RULE STATISTICS

**Total Rules**: 61
**Categories**: 13
**Endpoints Covered**: 29
**Features Mapped**: 14
**Chains Integrated**: 8 (of 9)
**Code Locations**: 50+

**Coverage by Category**:
- Cryptographic: 8 rules (13%)
- Protocol: 7 rules (11%)
- Privacy: 6 rules (10%)
- Leasing: 5 rules (8%)
- API: 5 rules (8%)
- Hardware: 5 rules (8%)
- Revocation: 4 rules (7%)
- Operations: 4 rules (7%)
- Error Handling: 4 rules (7%)
- Data: 4 rules (7%)
- Recovery: 3 rules (5%)
- Rate Limiting: 3 rules (5%)
- Monitoring: 3 rules (5%)

**Enforcement Density**:
- `backend/src/bin/oidc_service.rs`: 35+ rules enforced
- `backend/src/lib.rs`: 15+ rules enforced
- `backend/src/attestation.rs`: 2 rules enforced
- `backend/src/periwinkle.rs`: 1 rule enforced
- `anchor/SpookyIDApplet.java`: 2 rules enforced
- Database migrations: 4 rules enforced

---

## VERSION HISTORY

- **v1.0.0** (2026-01-16): Initial comprehensive rule catalog
  - 61 rules across 13 categories
  - Complete endpoint and feature mappings
  - Code location index
  - Integration with CHAINS.md and SPEC.md

---

## FINAL NOTES

### This Document is Canonical

RULES.md is the single source of truth for all security constraints, business rules, and operational policies. When code conflicts with documented rules, code is wrong.

### Documentation as Code

Treat this document with same rigor as source code:
- Version control all changes
- Code review all modifications
- Keep synchronized with implementation
- Run automated verification (`verify_rules.sh`)

### Security First

Every rule exists for a reason. Bypassing rules "just for testing" creates vulnerabilities. If a rule blocks legitimate use case:
1. Understand why rule exists (read Rationale)
2. Propose rule modification (with security justification)
3. Get security review approval
4. Update rule AND implementation together

### When in Doubt

- If unclear which rules apply: Check endpoint mapping table
- If rule seems outdated: Verify with `verify_rules.sh` and propose update
- If rule conflicts with SPEC.md: SPEC.md wins for API contracts, RULES.md wins for constraints
- If rule conflicts with CHAINS.md: Escalate - both should be consistent

---

**END OF RULES.MD**

---

## BRIDGE RULES (R-BRIDGE-*)

### R-BRIDGE-001: Byte-Oriented Interface

- **Rule**: All Critical FFI functions MUST exchange data as raw bytes (`Vec<u8>`) rather than complex language-specific structs. JSON/CBOR serialization MUST happen at the edges (Dart/Rust), not in the bridge.
- **Enforcement**: `native/hub/src/lib.rs` (function signatures)
- **Violation**: Build failure (if enforcing types) or Runtime deserialization errors.
- **Rationale**: Prevents "impedance mismatch" bugs between Dart and Rust memory models. Simplifies debugging.
- **Chains**: All chains utilizing Native Bridge.
- **Code Example**:
```rust
// Correct
pub fn encode(json_bytes: Vec<u8>) -> Vec<u8>;

// Incorrect
pub fn encode(input: MyComplexStruct) -> MyOtherStruct; 
```

### R-BRIDGE-002: Fail-Closed Panics

- **Rule**: Native functions MUST panic (unwind) on unrecoverable logic errors (e.g., Invalid UTF-8 geometry, malformed keys) rather than returning partial/default data.
- **Enforcement**: `native/hub/src/lib.rs` (`expect()`, `unwrap()`)
- **Violation**: Undefined behavior in UI.
- **Rationale**: A panic safely aborts the operation and notifies the Dart layer (via FfiException), preventing the system from proceeding with corrupted state.
*"Rules are not restrictions. Rules are the architecture of trust."*

# R-FLUTTER-001: Flutter AI & Best Practices Mandate

## Core Philosophy
1.  **Solid Principles**: Apply SOLID principles throughout the codebase.
2.  **Concise & Declarative**: Write modern, technical Dart. Favor composition over inheritance.
3.  **Immutability**: Prefer immutable data structures. Widgets must be immutable.

## Architecture & Structure
1.  **Logical Layers**:
    *   Presentation: Widgets, screens.
    *   Domain: Business logic.
    *   Data: Models, API clients.
    *   Core: Shared utilities, extensions.
2.  **State Management**:
    *   Default to built-in ValueNotifier, ChangeNotifier, ListenableBuilder.
    *   Use MVVM for complex logic.
    *   Avoid third-party state libs unless requested.
3.  **Navigation**: Use go_router for deep linking and declarative routing.

## Coding Standards
1.  **Null Safety**: Code must be soundly null-safe. Avoid ! force unpacking.
2.  **Async/Await**: Use Future, Stream, and proper error handling.
3.  **Linting**: Follow package:flutter_lints and Effective Dart guidelines.
4.  **Testing**: Follow Arrange-Act-Assert. Aim for high coverage (Unit, Widget, Integration).

## Visuals & Theming
1.  **Material 3**: Embrace ThemeData, ColorScheme.fromSeed, and light/dark modes.
2.  **Typography**: Use a clear typographic scale. Implement google_fonts if needed.
3.  **Responsiveness**: Use LayoutBuilder, MediaQuery, and flexible widgets (Expanded, Flexible).
4.  **Accessibility**: Ensure valid contrast ratios, dynamic text scaling, and semantic labels.

## Documentation
1.  **Dartdoc**: Document all public APIs using ///.
2.  **Context**: Explain *why*, not just *what*.

