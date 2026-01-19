# SpookyID Multipass - Mobile Authenticator Specification

**Version**: 0.8.0 (Sovereign Phase 2 - Hardened)
**Architecture**: Flutter Shell + Rust Core (Flutter Rust Bridge)
**Security Level**: NIST AAL3 (Hardware Anchored + Fail-Closed)

---

## 1. System Overview

Multipass is the "Zero-Trust Relay" for the SpookyID ecosystem. It is a mobile application that bridges the physical world (User, Hardware) with the digital world (OIDC Broker, Verifiers).

### Key Features
*   **Hardware Anchoring**: Keys generated in Android KeyStore (StrongBox/TEE) via `StrongboxModule.kt`.
*   **Zero-Knowledge**: BBS+ signatures generated in Rust Core (`lib.rs`).
*   **Proven Crypto**: Core logic extracted from proven `SpookyID_stack`.
*   **OIDC Compliance**: Acts as an OIDC Authenticator for the SpookyID Broker.

---

## 2. Architecture

### 2.1 The "Crypto Island" Design

The application follows a strict separation of concerns:

```
┌─────────────────────────────────┐
│        Flutter UI Layer         │  (Unprivileged)
│  (Screens, Blocs, Datasources)  │
├─────────────────────────────────┤
│       FRB Bridge (Wire)         │  (Serialization)
├─────────────────────────────────┤
│         Rust Core               │  (Trusted Execution)
│  (lib.rs, BBS+, OIDC Logic)     │
├─────────────────────────────────┤
│      StrongBox / Legacy KeyStore│  (Hardware Root of Trust)
│  (Keys never leave SE)          │
└─────────────────────────────────┘
```

### 2.2 Build Environment & Setup

**Prerequisites**:
- Flutter SDK: `C:\flutter\bin` (3.x+)
- Android NDK: `29.0.14206865` (set in `android/app/build.gradle.kts`)
- Gradle: 8.14 (wrapper included)

**Primary Build Method**: Direct Gradle (fastest)
```bash
cd android && .\gradlew.bat assembleDebug
```
**Output**: `android/app/build/outputs/apk/debug/app-debug.apk`

**Known Issues**:
1. **NFC Loop Bug**: Removed `TECH_DISCOVERED` intent filter (AndroidManifest.xml:31-36) to prevent Activity restart on tap
2. **Missing strings.xml**: Created `res/values/strings.xml` with `app_name` and `mdl_desc`
3. **Unicode in build.py**: Replaced emoji with ASCII (`🚀` → `[*]`)
4. **Missing imports**: Added `package:flutter/material.dart` to `lib/main.dart`

**UI Theme**: Jinx (LoL) - Electric Blue `#00D9FF`, Hot Pink `#FF1493` defined in `lib/core/theme.dart`

### 2.3 Component Stack
*   **UI**: Flutter (Material 3)
*   **Bridge**: `flutter_rust_bridge` (Generated Bindings)
*   **Crypto**: Rust (`bls12_381`, `bbs_official`, `sha2`)
*   **Hardware Access**: Kotlin MethodChannels -> Android KeyStore

### 2.3 mDoc Data Structure (ISO 18013-5)
**Location**: `multipass_app/rust/src/mdoc.rs`

*   **Format**: CBOR (Concise Binary Object Representation)
*   **Signing**: COSE_Sign1 (ES256)
*   **Structure**:
    ```json
    {
      "docType": "org.iso.18013.5.1.mDL",
      "domainTag": "SpookyID.mdoc.org.iso.18013.5.1.mDL.v1",
      "data": { ...attributes... }
    }
    ```
*   **Exports**:
    *   `create_mdoc_response`: Generates mDoc CBOR response
    *   **Status**: Rust core implemented & verified (Phase 6).


---

## 3. Cryptographic Implementation

### 3.1 StrongBox Key Generation
**Location**: `multipass_app/android/app/src/main/kotlin/com/spookyid/multipass/KeystoreManager.kt`

*   **Algorithm**: EC (secp256r1)
*   **Storage**: Android KeyStore
*   **Protection**: `setIsStrongBoxBacked(true)` (try-catch fallback where unavailable, logged)
*   **Purpose**: Device Attestation & Transport Security (mTLS/DPoP)

### 3.2 BBS+ Signatures
**Location**: `multipass_app/rust/src/bbs.rs`

*   **Curve**: BLS12-381
*   **Primitives**:
    *   `sign`: Generates signature `(A, e, s)`
    *   `create_proof`: Generates ZK-Proof of Knowledge
    *   `verify_proof_safe`: Validates proof (for local debugging)

    *   **Status**: Currently using **Mock Implementation** (`multipass_app/rust/src/bbs.rs`) for Android build stability. Real bindings pending re-integration (Phase 9).

---

## 4. Protocols

### 4.1 Hardware Attestation Handshake
**Goal**: Prove to the Broker that the app is running on genuine hardware.

1.  **Generate Key**: App requests new key pair from `StrongboxManager`.
2.  **Get Chain**: App retrieves X.509 Certificate Chain from KeyStore.
    *   Leaf Cert contains `1.3.6.1.4.1.11129.2.1.17` extension.
3.  **Transmit**: App POSTs chain to `/api/anchor/register` (Atomic Tap).
4.  **Verification**: Broker validates chain against Google/Apple Root CA.
    *   **Blindness**: Registration uses `HA(JCOP_Pub)` as Identity. PII is never sent.

### 4.2 OIDC Handshake (Planned Phase 3)
1.  **Poll**: App checks for pending nonce at `/api/oidc/nonce`.
2.  **Proof**: App generates BBS+ proof using `lib.rs`.
    *   Hides PII (e.g., Name).
    *   Reveals predicates (e.g., "Age > 18").
3.  **Submit**: App POSTs proof to `/api/admin/login`.

---

## 5. Security Constraints (RULES.md Compliance)

*   **R-CRYPTO-001**: No software keys for Identity. All Identity keys must be BLS12-381 (Soft) anchored to StrongBox (Hard).
*   **R-PRIV-002**: Zero Persistence. No PII stored in local database.
*   **R-APP-005**: Fail-Closed. If StrongBox is unavailable (and not in Dev Mode), app refuses to launch.

---

## 6. Roadmap Status

| Phase | Purpose | Status |
|-------|---------|--------|
| **1** | **Sovereign Foundation** | ✅ Complete |
| 1.1 | Flutter & UniFFI Scaffold | ✅ Complete |
| 1.2 | StrongBox KeyGen | ✅ Complete |
| 1.3 | Attestation Handshake | ✅ Complete |
| **2** | **mDL & ISO 18013-5** | ✅ Complete |
| **3** | **Slingshot (ZKP)** | 📋 Planned |
| **4** | **Trustless Recovery** | ✅ Complete |
| **5** | **Ecosystem Launch** | 📋 Planned |
| **7** | **Credential Management** | ✅ Complete |
| **8** | **Admin Authentication** | ✅ Complete |
| **9** | **Leasing (Offline Sudo)** | ✅ Complete |
| **10** | **System Hardening** | ✅ Complete |

---

## 7. Credential Management (Phase 7 - Complete)

### 7.1 Storage
**Location**: `lib/data/datasources/credential_storage.dart`  
**Encryption**: AES-256 via `flutter_secure_storage`  
**Format**: JSON array of credentials  
**Key**: Device-specific (hardware-backed when available)

**Data Model**: `lib/data/models/credential.dart`
```dart
class Credential {
  String id;              // UUID
  String issuer;            // e.g., "SpookyID Host"
  String type;             // "admin" | "identity"
  Map<String, String> attributes; // name, birthdate, etc.
  String signature;        // Base64 BBS+ signature
  String publicKey;        // Base64 issuer PK
  DateTime issuedAt;
}
```

### 7.2 Import Flow
**UI**: `lib/presentation/screens/import_screen.dart`  
**Methods**: 
1. **JSON Paste**: User pastes `admin_credential.json` content
2. **QR Scan**: (Placeholder - not yet implemented)

**Validation**: Parses JSON, creates `Credential` object, saves to encrypted storage

**Navigation**:
- Settings → Import Credential → Paste JSON → Wallet (reloads)

### 7.3 Wallet Display
**UI**: `lib/presentation/screens/wallet_screen.dart`  
**Data Source**: `CredentialStorage().getAll()`  
**Display**: Shows credential count in status card  
**Actions**: Settings icon navigates to import screen

**Status**: Phase 7.1-7.3 complete. Phase 7.4 (Settings screen) pending.

---

## 8. Admin Authentication (Phase 8 - BBS+ ZKP Login)

### 8.1 Root of Trust: JCOP Card
**Hardware Anchor**: JCOP-13398320 (NXP JCOP 4 P71)  
**Ceremony**: `issue_admin_credential.py` generates `admin_credential.json`  
**Signature**: BBS+ signature using JCOP card's secret key

**Security Model**:
- JCOP card is the **sovereign authority**
- No admin can be provisioned without JCOP approval
- Admin credential contains BBS+ signature provably from JCOP
- Backend verifies pairing math to ensure credential authenticity

### 8.2 Admin Login Flow
**UI**: `lib/presentation/screens/admin_login_screen.dart`  
**Endpoint**: `/api/admin/login`

**Steps**:
1. User imports `admin_credential.json` (Phase 7)
2. Tap "ADMIN LOGIN" on wallet screen
3. App fetches nonce from `/api/oidc/nonce`
4. `CryptoBridge.generateAdminProof()` creates BBS+ ZKP
5. Proof submitted to `/api/admin/login`
6. Backend verifies:
   - Nonce freshness (PostgreSQL anti-replay)
   - BBS+ pairing equation (BLS12-381 math)
   - Linkage tag not revoked (PostgreSQL)
   - Issuer PK matches JCOP-signed credential
7. If all checks pass → `access_token` granted

**Revealed Attributes**:
- Index 0: Timestamp (for freshness check)
- Index 1: Role ("Admin")
- Index 2: Tier (hidden for privacy)

**Current State**: Mock proof generation (structure-correct, math-invalid)  
**Production**: Requires Phase 6 (UniFFI native bridge) for real BBS+ math

### 8.3 Backend Verification
**Location**: `backend/src/bin/oidc_service.rs:409-637`  
**Math**: BLS12-381 pairing verification
```rust
// Line 542-570: verify_proof_safe()
let lhs = pairing(&a_prime, &w_g2e);
let rhs = pairing(&rhs_sum, &g2);
Ok(lhs == rhs) // Proof valid if pairings match
```

**Database Checks**:
- `nonces` table: Anti-replay protection
- `revocations` table: Linkage tag bans
- Fail-closed: Any DB error → REJECT

### 8.3 Admin Dashboard (Phase 8.3 - Complete ✅)

**Purpose**: Real-time system monitoring and metrics for administrators

#### JWT Token Authentication

**Crypto**: HS256 algorithm with `SPOOKY_JWT_SECRET`  
**Token Lifetime**: 1 hour (3600 seconds)  
**Claims**:
```json
{
  "sub": "admin:JCOP-133983",
  "role": "admin",
  "iss": "http://localhost:7777",
  "exp": 1768634575,
  "iat": 1768630975
}
```

#### Endpoints

**POST /api/admin/login**  
Enhanced to return real JWT tokens (previously returned mock `"ADMIN_SESSION_TOKEN_123"`)

**Response** (Success):
```json
{
  "status": "verified",
  "message": "Welcome, Administrator. Zero-Knowledge Proof Accepted.",
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "root_anchor": "JCOP-13398320"
}
```

**GET /api/admin/metrics** 🆕  
Returns comprehensive system metrics

**Authentication**: `Authorization: Bearer <jwt_token>` (required)

**Response**:
```json
{
  "authentication": {
    "total_verifications": 1234,
    "recent_verifications_24h": 89,
    "failed_attempts_24h": 3
  },
  "devices": {
    "total_registered": 42,
    "active_sessions": 12
  },
  "security": {
    "root_anchor": "JCOP-13398320",
    "revoked_tags_count": 0
  },
  "system": {
    "uptime_seconds": 3600,
    "version": "1.0.0"
  }
}
```

**GET /api/admin/recent_auth** 🆕  
Returns last 20 authentication events

**Authentication**: `Authorization: Bearer <jwt_token>` (required)

**Response**:
```json
{
  "events": [
    {
      "timestamp": 1768630975,
      "linkage_tag": "a1b2c3d4e5f6g7h8...",
      "status": "success",
      "disclosed_attributes": 2
    }
  ]
}
```

#### Security Model

**Root of Trust**: JCOP-13398320 remains sovereign
- BBS+ proof required before JWT issuance
- JWT cannot be obtained without JCOP-signed credential
- Token validation on all `/api/admin/*` endpoints (except `/login`)
- Expired tokens rejected (401 Unauthorized)

**Implementation**: `backend/src/bin/oidc_service.rs`
- Lines 1640-1686: JWT generation and validation
- Lines 1597-1700: Metrics and recent auth endpoints
- Lines 1879-1934: Enhanced admin_login with real JWT

**Mobile UI**: 
- `lib/data/services/admin_dashboard_service.dart` - API service layer ✅
- `lib/presentation/screens/admin_dashboard_screen.dart` - Dashboard UI ✅
- Auto-refresh every 10 seconds
- Pull-to-refresh support
- Error handling with retry
- Glassmorphic metric cards
- Live authentication event feed

**Status**: ✅ **Complete** (Backend + Flutter UI)

---

## 11. Sovereign Recovery (Phase 11 - Shamir Secret Sharing)

### 11.1 Overview

**Purpose**: Enable trustless recovery of the master identity secret using Shamir's Secret Sharing (k-of-n threshold scheme)

**Security Model**: 
- User's master secret split into N shares
- Requires K shares to reconstruct (threshold cryptography)
- No single party can recover the secret alone
- Shares can be distributed to trusted contacts, cloud storage, hardware tokens

### 11.2 Cryptographic Implementation

**Algorithm**: Shamir's Secret Sharing over BLS12-381 scalar field  
**Location**: `native/hub/src/lib.rs:666-953`

**Core Functions**:

```rust
// Rust Core
pub fn split_secret(secret: &Scalar, n: u8, k: u8) -> Vec<(u8, Scalar)>
pub fn reconstruct_secret(shares: &[(u8, Scalar)]) -> Result<Scalar, String>
```

**UniFFI Exports** (Flutter-accessible):

```rust
#[uniffi::export]
pub fn split_secret_safe(
    secret: Vec<u8>,      // 32-byte scalar
    threshold: u8,        // K (minimum shares needed)
    total: u8,            // N (total shares to generate)
) -> Result<Vec<Vec<u8>>, VerifyError>

#[uniffi::export]
pub fn reconstruct_secret_safe(
    shares: Vec<Vec<u8>>  // K or more shares (33 bytes each: 1 byte index + 32 bytes scalar)
) -> Result<Vec<u8>, VerifyError>
```

### 11.3 Share Format

Each share is 33 bytes:
- Byte 0: Share index (1-255)
- Bytes 1-32: Scalar value (BLS12-381 field element)

**Example**:
```
Share 1: [0x01, 0xA1B2C3D4...]  // 33 bytes
Share 2: [0x02, 0xE5F6G7H8...]  // 33 bytes
Share 3: [0x03, 0x11223344...]  // 33 bytes
```

### 11.4 Security Properties

**Threshold Cryptography**: (K, N) scheme
- **K = 2, N = 3**: Any 2 of 3 shares can reconstruct
- **K = 3, N = 5**: Any 3 of 5 shares can reconstruct
- Possession of K-1 shares reveals ZERO information about the secret

**Lagrange Interpolation**: Uses Lagrange basis polynomials over finite field
```
secret = Σ(y_j * L_j(0))
where L_j(x) = Π((x - x_m) / (x_j - x_m)) for all m ≠ j
```

**Field Operations**: All arithmetic in BLS12-381 scalar field (255-bit prime order)

### 11.5 Recovery Flow

**Split Flow** (Initial Setup):
1. User imports or generates master secret (32 bytes)
2. User chooses threshold: K shares required, N total shares
3. App calls `split_secret_safe(secret, K, N)`
4. App displays N shares as:
   - QR codes (for backup to paper/photo)
   - Base64 strings (for copy/paste)
   - Files (for USB drive backup)
5. User distributes shares to trusted locations

**Reconstruct Flow** (Recovery):
1. User lost access to primary device
2. User imports K or more shares via:
   - QR scan
   - Manual text entry
   - File import
3. App calls `reconstruct_secret_safe(shares)`
4. Secret reconstructed if >= K shares valid
5. App re-derives all credentials from recovered secret

### 11.6 Integration with Identity System

**Master Secret Usage**:
- Master secret is the root of the identity tree
- Derives per-site pseudonyms via `generate_linkage_tag(secret, site_id)`
- Can re-issue credentials from recovered secret
- Automatic revocation of old device credential (Chain 7)

**Auto-Revocation** (RULES.md R-REV-003):
- Upon successful recovery, backend revokes all linkage tags from old device
- New device gets fresh linkage tags from same master secret
- Old device cannot be used even if physically recovered

### 11.7 UI/UX (Pending Implementation)

**Screens Needed**:
- `lib/presentation/screens/recovery_split_screen.dart` - Generate shares
- `lib/presentation/screens/recovery_import_screen.dart` - Import shares for reconstruction

**Suggested Flow**:
1. **Split**: Settings → Backup Identity → Choose K/N → Display shares
2. **Reconstruct**: First Launch → "Lost Access?" → Scan/Enter Shares → Recover

**Status**:
- ✅ Rust cryptographic core complete
- ✅ UniFFI exports functional
- ⏳ Flutter UI pending
- ⏳ QR code generation/scanning integration pending

### 11.8 Best Practices

**Recommended Configurations**:
- **Basic**: 2-of-3 (2 shares needed, 3 generated)
- **Paranoid**: 3-of-5 (3 shares needed, 5 generated)
- **Enterprise**: 5-of-9 (5 shares needed, 9 generated)

**Distribution Strategy**:
- Share 1: Password manager (Bitwarden/1Password)
- Share 2: Trusted family member
- Share 3: Physical paper in safe
- Share 4: USB drive in bank deposit box 
- Share 5: Cloud storage (encrypted)

**Security Warning**: Never store all K shares in the same location!

---



---

## 12. Native Bridge Interface (FRB)

The Flutter-Rust Bridge (FRB) layer defines the strict contract between the Dart UI and the Rust Core. Any deviation results in build failures or undefined behavior.

### 12.1 Design Principles (The "Fail-Closed" Bridge)
1.  **Sync by Default**: All cryptographic operations must be synchronous (`#[frb(sync)]`) to prevent race conditions in the UI state machine, unless performing heavy I/O.
2.  **Byte-Oriented**: To avoid complex serialization bugs in the bridge, all critical data APIs must exchange raw bytes (`Vec<u8>`) rather than complex structs or Strings. JSON serialization happens in Dart.
3.  **Panic on Failure**: For critical crypto failures (e.g., bad key format), the Rust core MUST panic or return a `Result` that propagates to a Dart exception. Silent failures are prohibited.

### 12.2 mDoc API (ISO 18013-5)
**Location**: `native/hub/src/lib.rs` (Exported via `pub use`)

```rust
// Encodes generic JSON data into ISO 18013-5 CBOR format
#[frb(sync)]
pub fn encode_mdoc_bytes(
    doc_type: Vec<u8>,   // utf8 bytes
    data_json: Vec<u8>,  // utf8 bytes
) -> Vec<u8>;            // CBOR bytes (or panic)

// Signs the Mobile Security Object (MSO) with the Issuer Key
#[frb(sync)]
pub fn sign_mso_bytes(
    mso_bytes: Vec<u8>,
    issuer_private_key: Vec<u8>, // SEC1 encoded
) -> Vec<u8>;            // COSE_Sign1 bytes (or panic)
```

### 12.3 SSS API (Shamir Secret Sharing)
**Location**: `native/hub/src/lib.rs`

```rust
// Splits a master secret into N shares
#[frb(sync)]
pub fn split_secret_safe(
    secret: Vec<u8>,     // 32-byte scalar
    threshold: u8,       // K
    total: u8            // N
) -> Result<Vec<Vec<u8>>, String>; // List of 33-byte shares

// Reconstructs master secret from K shares
#[frb(sync)]
pub fn reconstruct_secret_safe(
    shares: Vec<Vec<u8>> // List of 33-byte shares
) -> Result<Vec<u8>, String>;      // 32-byte scalar
```
