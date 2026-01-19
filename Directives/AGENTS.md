# AGENTS - AI Coding Agent Directives

**Purpose**: Instruct AI coding agents how to deploy and interact with the SpookyID codebase.
**Version**: 1.0.0
**Last Updated**: 2026-01-16

---

## HARD NON-NEGOTIABLES (MUST FOLLOW)

### 1. Multi-Phase Implementation REQUIRED

**ALL non-trivial changes MUST use multi-phase planning**:

```
Phase 1: Research & Understanding
- Read relevant sections of CHAINS.md and RULES.md
- Identify affected agents and trust chains
- Document current behavior

Phase 2: Design
- Create implementation plan
- Identify all affected files and endpoints
- Document expected behavior changes
- Get user approval before coding

Phase 3: Implementation
- Follow approved plan
- Update code

Phase 4: Documentation Updates (MANDATORY)
- Update SPEC.md with new endpoints/features
- Update RULES.md with new rules or modified constraints
- Update CHAINS.md if trust chains affected
- Update this AGENTS.md if new agents created

Phase 5: Verification
- Run tests
- Verify documentation accuracy
- Cross-check all references
```

**NO EXCEPTIONS**: Every change, no matter how small, requires documentation updates.

### 2. SPEC.md is the Bible

**`SPEC.md` is the canonical source of truth for:**
- All API endpoints (paths, methods, request/response formats)
- All features (what they do, how they work)
- System architecture
- Integration points

**BEFORE coding**: Check SPEC.md for existing endpoints
**AFTER coding**: Update SPEC.md with new/modified endpoints

**Template for SPEC.md updates**:
```markdown
### POST /api/new/endpoint

**Purpose**: Brief description

**Request**:
```json
{
  "param": "type"
}
```

**Response**:
```json
{
  "result": "value"
}
```

**Assurance Level**: L1/L2/L3/L4
**Chains**: Chain 1, Chain 2
**Rules**: R-PROTO-001, R-REV-002
```

### 3. RULES.md is the Constraint Bible

**`RULES.md` documents ALL**:
- Security constraints (R-CRYPTO-*, R-PROTO-*, R-HW-*)
- Privacy requirements (R-PRIV-*)
- Business rules (R-OPS-*, R-LEASE-*)
- Error handling (R-ERR-*)
- Monitoring (R-MON-*)

**BEFORE modifying security code**: Check RULES.md for constraints
**AFTER adding new behavior**: Add corresponding rule to RULES.md

**Rule Template**:
```markdown
### R-CATEGORY-NNN: Rule Name

- **Rule**: What MUST/MUST NOT happen
- **Enforcement**: Where enforced (code location)
- **Violation**: What happens on violation
- **Rationale**: Why this rule exists
```

### 4. Regular Documentation Accuracy Checks

**At the END of EVERY coding session**:

1. **Check SPEC.md Accuracy**:
   ```bash
   # Verify all endpoints in code match SPEC.md
   grep -r "router.route" backend/src/
   # Cross-reference with SPEC.md
   ```

2. **Check RULES.md Accuracy**:
   ```bash
   # Verify all rules referenced in code exist in RULES.md
   grep -r "Rule R-" backend/src/
   # Cross-reference with RULES.md
   ```

3. **Check CHAINS.md Integration**:
   ```bash
   # Verify chain integrations match documented flows
   grep -r "Chain [0-9]" backend/src/
   # Cross-reference with CHAINS.md
   ```

4. **Update This File (AGENTS.md)**:
   - New agents? Add to Agent Taxonomy section
   - New code patterns? Add to Code Patterns section
   - New critical locations? Add to Critical Code Locations

### 5. Documentation Update Checklist

**After EVERY code change, update these files**:

- [ ] **SPEC.md**: New/modified endpoints, features, architecture
- [ ] **RULES.md**: New/modified rules, constraints, error conditions
- [ ] **CHAINS.md**: New/modified trust chain flows, integrations
- [ ] **AGENTS.md**: New/modified agents, code locations, patterns
- [ ] **README files**: Component-specific changes (backend/README.md, dashboard/README.md, etc.)

**Verification Command** (run before committing):
```bash
# Check for TODO/FIXME that should be documented
git diff | grep -E "TODO|FIXME|XXX"

# Check for new endpoints not in SPEC.md
git diff backend/src/ | grep "route("
```

---

## Quick Start for AI Agents

You are working on **SpookyID**, a hardware-anchored zero-knowledge identity system. When modifying code:

1. **Read `CHAINS.md`** first to understand how identity is secured while remaining anonymous
2. **Read `RULES.md`** before making security-critical changes
3. **Check `SPEC.md`** for existing endpoints before adding new ones
4. Follow the agent taxonomy below to understand system components
5. Always verify cryptographic code against existing patterns in `backend/src/lib.rs`
6. **ALWAYS follow the Multi-Phase Implementation process above**
7. **ALWAYS update documentation after code changes**

---

## System Architecture (4 Layers)

```
Layer 4: Admin/Dashboard
  ├── Next.js Dashboard (dashboard/)
  ├── Admin Auth via BBS+ ZKP
  └── Rate Limiting

Layer 3: Backend Service (Rust/Axum)
  ├── OIDC Credential Issuance (backend/src/bin/oidc_service.rs:844-887)
  ├── ZKP Verification (backend/src/bin/oidc_service.rs:409-637)
  ├── Revocation Manager (backend/src/db/repositories.rs:119-136)
  └── Chain 6 Audit Logging (backend/src/bin/oidc_service.rs:603-613)

Layer 2: Cryptographic Core
  ├── BBS+ Signatures (backend/src/lib.rs:109-555)
  ├── Periwinkle Entropy (backend/src/periwinkle.rs) - AAL3 1856 bits
  ├── Device Attestation (backend/src/attestation.rs)
  ├── Delegation Tokens (backend/src/lib.rs:577-686) - Chain 9
  └── Shamir Recovery (backend/src/lib.rs:690-747) - Chain 7

Layer 1: Hardware/Client
  ├── JavaCard Anchor (anchor/SpookyIDApplet.java)
  ├── Multipass Mobile (multipass/src/lib.rs) - UniFFI bridge
  ├── Privacy Miner (backend/src/miner.rs) - k-anonymity
  └── PostgreSQL (backend/src/db/)
```

---

## Agent Taxonomy

### Protocol Agents (OIDC/Credential Lifecycle)

**AGENT_ISSUER_VCI** - Issues BBS+ credentials
- Location: `backend/src/bin/oidc_service.rs:844-887`
- Key Function: Signs credentials with issuer SK
- **Critical**: Issuer SK MUST be TPM-backed in production

**AGENT_VERIFIER_VP** - Verifies zero-knowledge proofs
- Location: `backend/src/bin/oidc_service.rs:409-637`
- Assurance Levels: L1 (sig) → L2 (revocation) → L3 (attestation) → L4 (freshness)
- **Read CHAINS.md** to understand multi-chain verification

**AGENT_REVOCATION** - Manages "graveyard" of revoked credentials
- Location: `backend/src/db/repositories.rs:119-136`
- Integrated into: Chain 1 (Lifecycle), Chain 2 (verification), Chain 7 (recovery), Chain 9 (leasing)

---

### Cryptographic Agents

**AGENT_CRYPTO_BBS** - BBS+ signatures on BLS12-381
- Location: `backend/src/lib.rs:109-555`
- Library: MATTR BBS v0.4.1 (official - DO NOT modify)
- Functions: `bbs_sign()`, `verify_signature_safe()`, `bbs_pair_proof()`, `verify_proof_safe()`
- **Critical**: All crypto changes require security review

**AGENT_ENTROPY_PERIWINKLE** - Hardware entropy harvesting
- Location: `backend/src/periwinkle.rs`
- Provides: 1856 bits (232 bytes) AAL3-compliant entropy
- Sources: `/dev/hwrng`, CPU jitter, memory latency, timestamp
- **Critical**: Production REQUIRES `/dev/hwrng` - see Rule R-CRYPTO-004

**AGENT_ATTESTATION** - Device hardware verification
- Location: `backend/src/attestation.rs`
- Verifies: Android KeyStore OID 1.3.6.1.4.1.11129.2.1.17, iOS Secure Enclave
- **Critical**: Rejects software-backed keys in production

**AGENT_DELEGATION** - Offline sudo via phone TEE
- Location: `backend/src/lib.rs:577-686`, `backend/src/bin/oidc_service.rs:957-1104`
- Token: 145 bytes (anchor_id, mobile_key, tier, expiration, max_passages)
- **Read CHAINS.md Chain 9** for biometric + push notification flow

**AGENT_RECOVERY_SHAMIR** - Sovereign identity recovery
- Location: `backend/src/lib.rs:690-747`
- Algorithm: Shamir Secret Sharing (k-of-n threshold)
- **Read CHAINS.md Chain 7** for auto-revocation flow

---

### Infrastructure Agents

**AGENT_RATE_LIMITER** - DoS protection
- Location: `backend/src/bin/oidc_service.rs:268`
- Rate: 5 req/min burst, 1 req/12s sustained (admin login)

**AGENT_ADMIN_AUTH** - ZKP-based admin authentication
- Uses BBS+ to authenticate without password exposure
- **Read CHAINS.md** to understand zero-knowledge property

**AGENT_AUDIT** - Privacy-preserving audit logs
- Location: `backend/src/bin/oidc_service.rs:603-613`
- Mechanism: `H(linkage_tag || audit_salt)` - **Read CHAINS.md Chain 6**

---

### Data Layer Agents

**AGENT_DB_POOL** - PostgreSQL connection pooling
- Location: `backend/src/db/mod.rs`
- Max connections: 20

**AGENT_REPO_ANCHORS** - Device registry
- Location: `backend/src/db/repositories.rs:74-113`
- Stores: device_did, commitment_hash, attestation SPKI

**AGENT_REPO_INVITES** - Onboarding code management
- Location: `backend/src/db/repositories.rs:13-68`
- One-time use enforcement

**AGENT_MINER_PRIVACY** - K-anonymity aggregation
- Location: `backend/src/miner.rs`
- K-anonymity: ≥15 unique identities
- ε-Differential Privacy: Laplace noise (ε=1.0)

---

### Client/Mobile Agents

**AGENT_MULTIPASS_FFI** - Rust → Flutter bridge
- Location: `multipass/src/lib.rs`
- UniFFI bindings for Kotlin/Swift

**AGENT_ADMIN_DASHBOARD** - Mobile admin dashboard (Phase 8.3)
- Location: `lib/presentation/screens/admin_dashboard_screen.dart`
- Service: `lib/data/services/admin_dashboard_service.dart`
- Features: JWT authentication, live metrics, auto-refresh (10s)
- Endpoints: `/api/admin/metrics`, `/api/admin/recent_auth`
- **Critical**: Requires valid JWT from `/api/admin/login`

**AGENT_DASHBOARD** - Admin web interface
- Location: `dashboard/`
- Stack: Next.js 14, React 18, Tailwind CSS

---

### Hardware Agents

**AGENT_ANCHOR_JAVACARD** - Hardware root of trust
- Location: `anchor/SpookyIDApplet.java`
- APDU commands: 0x10 (pair), 0x20 (derive), 0x30 (sign), 0x50 (PIN)
- **Critical**: Master seed NEVER exported (32 bytes TRNG)

**AGENT_PROVISION** - Factory provisioning
- Location: `anchor/provision_card.py`
- Steps: Install CAP → Init seed → Set PIN → Register backend

---

## Common Development Tasks

### Adding a New Credential Attribute

1. **Read CHAINS.md Chain 2** to understand BBS+ selective disclosure
2. Modify message count: `MESSAGE_COUNT` env var
3. Update issuer public key generators (add new `hi` for attribute)
4. Update proof verification to handle new message index
5. Test selective disclosure (reveal/hide combinations)

### Modifying Revocation Logic

1. **Read CHAINS.md Chain 1** for lifecycle flow
2. Check integration points: Chain 2 (verification), Chain 7 (recovery), Chain 9 (leasing)
3. Update `backend/src/db/repositories.rs:119-136`
4. **Read RULES.md R-REV-001 to R-REV-004** for constraints

### Implementing New Assurance Level

1. **Read CHAINS.md** to understand existing L1-L4 cascade
2. Update `backend/src/bin/oidc_service.rs:409-637` verification handler
3. Add new chain if needed (coordinate with existing chains)
4. Update **RULES.md** with new rule definitions

### Extending Delegation (Chain 9)

1. **Read CHAINS.md Chain 9** - understand biometric + push flow
2. Modify `DelegationToken` struct in `backend/src/lib.rs:577-686`
3. Update token size calculation (currently 145 bytes)
4. Check anchor revocation cascade (`oidc_service.rs:1016-1027`)
5. **Read RULES.md R-LEASE-001 to R-LEASE-004** for constraints

---

## Critical Code Locations

### Cryptographic Primitives
- BBS+ Sign: `backend/src/lib.rs:109-164`
- BBS+ Verify: `backend/src/lib.rs:177-258`
- BBS+ Proof: `backend/src/lib.rs:269-350`
- Proof Verify: `backend/src/lib.rs:372-555`
- Linkage Tag: `backend/src/lib.rs:62-68`

### Chain Implementations
- Chain 1 (Lifecycle): `repositories.rs:119-136`, `oidc_service.rs:888-913`
- Chain 2 (Entitlements): `lib.rs:109-555`, `oidc_service.rs:409-637`
- Chain 3 (Device Binding): `attestation.rs`, `oidc_service.rs:683-721`
- Chain 4 (Discovery): `oidc_service.rs:311-337`
- Chain 5 (Freshness): `periwinkle.rs`, `oidc_service.rs:537-550`
- Chain 6 (Audit): `oidc_service.rs:603-613`
- Chain 7 (Recovery): `lib.rs:690-747`, `oidc_service.rs:1107-1156`
- Chain 9 (Leasing): `lib.rs:577-686`, `oidc_service.rs:957-1104`

### Security-Critical
- Nonce verification (anti-replay): `oidc_service.rs:341-361`, `oidc_service.rs:417-434`
- Timestamp freshness: `oidc_service.rs:490-510`
- Revocation check: `oidc_service.rs:584-597`
- Admin token check: All `/api/admin/*` endpoints
- **JWT token generation**: `oidc_service.rs:1640-1662` (Phase 8.3)
- **JWT token validation**: `oidc_service.rs:1664-1686` (Phase 8.3)
- **Admin metrics endpoint**: `oidc_service.rs:1597-1663` (Phase 8.3)
- **Recent auth endpoint**: `oidc_service.rs:1665-1700` (Phase 8.3)
- **Enhanced admin login**: `oidc_service.rs:1879-1934` (Phase 8.3)

---

## Development Guidelines

### MUST READ Before Coding

1. **CHAINS.md** - Understand the 9 trust chains and how they integrate
2. **RULES.md** - Security and business rules (50+ rules across 13 categories)
3. Existing implementation patterns in `backend/src/lib.rs`

### Security Principles

- **Fail-Closed**: On error, REJECT request (security over availability)
- **Zero-Knowledge**: Backend NEVER sees user PII (only commitments)
- **Hardware-Backed**: Production REQUIRES TPM/TEE (no software fallbacks)
- **Append-Only**: Revocations, audit logs NEVER deleted
- **Anti-Replay**: Nonce + timestamp within 300s window

### Code Patterns

**Error Handling**:
```rust
// Fail-closed on database errors
match state.db.is_tag_revoked(&tag).await {
    Ok(true) => return Err("Revoked"),
    Ok(false) => { /* Continue */ }
    Err(_) => return Err("DB error - rejecting for safety"),
}
```

**Cryptographic Operations**:
```rust
// Always use MATTR BBS library v0.4.1
use bbs_official::{verify_proof, create_proof};

// Never implement custom crypto
// Entropy from Periwinkle (never SystemTime::now())
let entropy = get_entropy();  // periwinkle.rs
```

**Database Operations**:
```rust
// Always use parameterized queries (prevent SQL injection)
sqlx::query("SELECT * FROM anchors WHERE device_did = $1")
    .bind(device_id)
    .fetch_one(&pool)
    .await
```

---

## Configuration Reference

### Environment Variables
```bash
# Backend
DATABASE_URL=postgresql://user:pass@localhost/spookyid
SPOOKY_ISSUER=https://api.getspooky.io
SPOOKY_ADMIN_TOKEN=<secret>
ISSUER_PUBLIC_KEY=<hex-g2-point>
MESSAGE_COUNT=3

# Security (CRITICAL)
UNSAFE_DEV_MODE=false  # MUST be false in production
TPM_PATH=/sys/class/tpm/tpm0/device/root_key
HWRNG_PATH=/dev/hwrng

# Privacy
K_ANONYMITY_THRESHOLD=15
DEFAULT_EPSILON=1.0
```

### Database Schema
```sql
-- Core tables (see backend/migrations/)
anchors       -- Device registry (device_did UNIQUE)
revocations   -- Graveyard (linkage_tag PRIMARY KEY)
nonces        -- Anti-replay (nonce PRIMARY KEY, 300s TTL)
invites       -- Onboarding (code PRIMARY KEY, one-time use)
```

---

## Testing Guidelines

### Unit Tests
```bash
cd backend
cargo test --lib
```

### Integration Tests
```bash
cargo test --test integration_tests
```

### Critical Test Scenarios
1. **Replay Attack**: Reuse nonce → REJECT
2. **Timestamp Out of Window**: timestamp < now-300s → REJECT
3. **Revoked Credential**: is_tag_revoked=true → REJECT
4. **Software Attestation**: Missing OID 1.3.6.1.4.1.11129.2.1.17 → REJECT (production)
5. **Anchor Revocation Cascade**: Revoke anchor → All leases invalid

---

## When to Read Which Document

| Task | Read This Document |
|------|-------------------|
| Understanding identity security/anonymity | **CHAINS.md** (Chain 2: Entitlements, Chain 6: Audit) |
| Understanding credential lifecycle | **CHAINS.md** (Chain 1: Lifecycle) |
| Understanding device loss recovery | **CHAINS.md** (Chain 7: Recovery) |
| Understanding offline delegation | **CHAINS.md** (Chain 9: Leasing) |
| Understanding security constraints | **RULES.md** (R-CRYPTO-*, R-PROTO-*, R-PRIV-*) |
| Understanding revocation rules | **RULES.md** (R-REV-001 to R-REV-004) |
| Understanding privacy guarantees | **RULES.md** (R-PRIV-001 to R-PRIV-005) |
| Modifying BBS+ crypto | **CHAINS.md** (Chain 2) + `backend/src/lib.rs` |
| Adding new assurance level | **CHAINS.md** (all chains) + **RULES.md** (R-PROTO-003) |
| Changing rate limits | **RULES.md** (R-RATE-001, R-RATE-002) |
| Hardware attestation logic | **CHAINS.md** (Chain 3) + `backend/src/attestation.rs` |

---

## Emergency Contacts / Documentation

### Core Documentation (Permanent)
- **Architecture Spec**: `SPEC.md`
- **Whitepaper**: `docs/Multipass_Whitepaper.md`
- **Deployment**: `docs/DEPLOYMENT.md`
- **Admin Login API**: `backend/docs/admin_login_api.md`
- **Anchor APDU Spec**: `anchor/APDU_SPEC.md`
- **Dashboard README**: `dashboard/README.md`

### Resources Folder (Temporary Reading Materials)

**Location**: `multipass/Directives/resources/`

**Purpose**: Pool of reference materials for planning and research. Contents are NOT permanent and should be checked when requested by user.

**Typical Contents**:
- Research papers on BBS+ signatures
- ISO 18013-5 mDL specifications
- OIDC 4 VCI/VP specifications
- Security audit reports
- Architecture decision records (ADRs)
- Performance benchmarks
- Integration guides for specific platforms

**Usage Pattern**:
```
User: "Check resources folder for BBS+ signature optimization techniques"
Agent:
  1. List files in multipass/Directives/resources/
  2. Read relevant files
  3. Apply insights to planning
```

**Important Notes**:
- Resources folder contents are ephemeral (user manages lifecycle)
- Do NOT assume files persist between sessions
- Always list/check folder before referencing specific files
- If user mentions "resources", they mean this folder
- Use for planning phases, NOT as canonical documentation source

---

## Maintaining Documentation Accuracy

### Weekly Documentation Audit (Automated)

**Create a script** (`scripts/doc_audit.sh`):
```bash
#!/bin/bash
# Documentation accuracy verification

echo "=== Checking SPEC.md Accuracy ==="
# Extract all endpoints from code
grep -rh "\.route(" backend/src/bin/ | sed 's/.*"\([^"]*\)".*/\1/' | sort > /tmp/code_endpoints.txt

# Compare with SPEC.md
echo "Endpoints in code but not in SPEC.md:"
# Manual review needed

echo "=== Checking RULES.md References ==="
# Find all rule references in code
grep -rh "Rule R-" backend/src/ | sed 's/.*Rule \(R-[A-Z]*-[0-9]*\).*/\1/' | sort -u > /tmp/code_rules.txt

echo "Rules referenced in code:"
cat /tmp/code_rules.txt

echo "=== Checking CHAINS.md References ==="
# Find all chain references
grep -rh "Chain [0-9]" backend/src/ | sed 's/.*Chain \([0-9]\).*/\1/' | sort -u

echo "=== Checking for Undocumented Agents ==="
# Look for new modules
find backend/src/ -name "*.rs" -type f

echo "=== END AUDIT ==="
```

### On Code Commit: Pre-Commit Hook

**Create** `.git/hooks/pre-commit`:
```bash
#!/bin/bash
# Pre-commit documentation check

echo "Checking for documentation updates..."

# Check if code changed but docs didn't
CODE_CHANGED=$(git diff --cached --name-only | grep -E '\.rs$|\.java$|\.py$' | wc -l)
DOCS_CHANGED=$(git diff --cached --name-only | grep -E 'SPEC\.md|RULES\.md|CHAINS\.md|AGENTS\.md' | wc -l)

if [ $CODE_CHANGED -gt 0 ] && [ $DOCS_CHANGED -eq 0 ]; then
    echo "WARNING: Code changed but no documentation updated!"
    echo "Did you update SPEC.md, RULES.md, CHAINS.md, or AGENTS.md?"
    echo ""
    echo "Files changed:"
    git diff --cached --name-only | grep -E '\.rs$|\.java$|\.py$'
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check for TODO/FIXME that should be addressed
TODOS=$(git diff --cached | grep -E "^\+.*TODO|^\+.*FIXME" | wc -l)
if [ $TODOS -gt 0 ]; then
    echo "WARNING: New TODO/FIXME comments added:"
    git diff --cached | grep -E "^\+.*TODO|^\+.*FIXME"
    echo ""
fi

exit 0
```

### Agent-Specific Accuracy Checks

**When modifying an agent**, verify:

1. **Agent Location**: Still correct in this file?
2. **Agent Dependencies**: Updated if changed?
3. **Chain Integrations**: Documented in CHAINS.md?
4. **Rule Enforcement**: Documented in RULES.md?
5. **API Endpoints**: Documented in SPEC.md?

**Example Check**:
```bash
# If you modified AGENT_VERIFIER_VP:
echo "Checking AGENT_VERIFIER_VP..."

# Verify location
grep -n "AGENT_VERIFIER_VP" multipass/Directives/AGENTS.md
# Should show: oidc_service.rs:409-637

# Verify actual code location
grep -n "async fn verify_proof_handler" backend/src/bin/oidc_service.rs
# Compare line numbers

# If mismatch, update AGENTS.md
```

---

## Version History

- **v1.0.0** (2026-01-16): Initial agent directives for AI coding agents with HARD non-negotiables

---

## Final Reminders

**This is a zero-knowledge, hardware-anchored identity system. Security and privacy are non-negotiable.**

### Every Code Change MUST:

1. ✅ Follow multi-phase implementation plan
2. ✅ Update SPEC.md (endpoints, features)
3. ✅ Update RULES.md (new constraints, rules)
4. ✅ Update CHAINS.md (if chains affected)
5. ✅ Update AGENTS.md (if agents changed)
6. ✅ Run documentation accuracy checks
7. ✅ Add pre-commit hook verification

### When in Doubt:

1. Read **CHAINS.md** to understand trust chains
2. Read **RULES.md** to understand security constraints
3. Check **SPEC.md** for existing patterns
4. Ask for clarification before modifying cryptographic code
5. Test thoroughly with emphasis on security edge cases
6. **VERIFY DOCUMENTATION ACCURACY**

### Documentation is Code

Inaccurate documentation is worse than no documentation. It misleads developers and creates security vulnerabilities.

**Treat documentation updates with the same rigor as code changes.**

---

## Silent Execution Policy (Antigravity Layer 2)

### Phase Initialization Protocol

**Before starting any multi-phase task:**
1. Read `progress.md` to understand current phase status
2. Read `CHAINS.md` to identify affected trust chains
3. Read `BOOTSTRAP.md` for critical constraints
4. Clear probabilistic assumptions from prior context

**Documentation anchors** (in order of priority):
- `SPEC.md` - Canonical system architecture
- `CHAINS.md` - 9-Chain Sovereign Mesh trust model
- `RULES.md` - Business and security constraints
- `progress.md` - Current mission and phase tracking

### Autonomous Tool Execution

**Pre-authorized operations** (no confirmation required):
- Read/Grep/Glob operations on any file
- Bash commands in scripts/ folder (bootstrap.sh, test.sh)
- Edit operations on documentation (docs/, directives/)

**Require explicit user permission**:
- Destructive operations (migrations, database changes)
- High-cost operations (API calls with billing)
- Production deployments

### Self-Annealing Error Recovery

**When a script fails:**
1. Read error output
2. Identify root cause (missing dependency, syntax error, etc.)
3. Fix the script autonomously
4. Re-test the script
5. Update relevant documentation (SPEC.md, CHAINS.md, etc.)

**Stop and ask for permission if:**
- Fix requires paid API tokens
- Fix requires external service registration
- Root cause is ambiguous (multiple possibilities)

### Documentation Synchronization

**Keep these files in sync:**
- Code changes → Update SPEC.md endpoints
- New rules discovered → Add to RULES.md
- Trust chain modifications → Update CHAINS.md
- Phase completions → Update progress.md

**Verification**: Run `scripts/test.sh` after documentation updates to ensure consistency.

### Layer 3 Deterministic Execution

**Prefer scripts over inline operations:**
- File operations → scripts/bootstrap.sh
- Chain verification → scripts/test.sh
- Database migrations → backend/migrations/

**Rationale**: Scripts are testable, version-controlled, and reproducible across sessions.

---

**END OF AGENTS.MD**

*"The map is the territory. Keep the map accurate."*
