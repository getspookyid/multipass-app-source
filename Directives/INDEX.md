# SpookyID Documentation Index

**Version**: 1.0.0
**Purpose**: Central navigation hub for all SpookyID documentation
**Last Updated**: 2026-01-17

---

## Quick Start (5-Minute Context Restore)

**New AI Agent? Start here:**

1. **Read This First**: [BOOTSTRAP.md](BOOTSTRAP.md) - Emergency context restoration protocol
2. **Check Current State**: [progress.md](progress.md) - What phase are we in? What's blocking?
3. **Understand Architecture**: [CHAINS.md](CHAINS.md) - The 9-Chain Sovereign Mesh
4. **Verify System Ready**: Run `python execution/bootstrap_context.py`

---

## Documentation Map

### Layer 1: Directives (What to Do)

#### Core Architecture Documents

| Document | Purpose | When to Read |
|----------|---------|--------------|
| **[BOOTSTRAP.md](BOOTSTRAP.md)** | 5-minute context restoration for AI agents | **Every session start** (cold context) |
| **[CHAINS.md](CHAINS.md)** | 9-Chain Sovereign Mesh trust architecture | When working on crypto/trust features |
| **[AGENTS.md](AGENTS.md)** | Agent taxonomy & silent execution policy | When understanding system architecture |
| **[RULES.md](RULES.md)** | 66 security/business constraints (R-*) | Before modifying any code |
| **[progress.md](progress.md)** | Current mission, phase status, blockers | **Every session** to understand priorities |

#### Reference Documents

| Document | Purpose | When to Read |
|----------|---------|--------------|
| **[SPEC.md](../SpookyID_stack/SPEC.md)** | Canonical system architecture (544 lines) | When working on backend/API |
| **[rules_link.md](rules_link.md)** | Link to master Antigravity rules | When following Antigravity patterns |

### Layer 2: Orchestration (Decision-Making)

**Context7 MCP Integration**:
- Configuration: [.claude/settings.json](../.claude/settings.json)
- Real-time docs for BBS+, Axum, Flutter
- Prevents API hallucination

**Silent Execution Policy**:
- Read directive → Execute tools → No prompting between layers
- See [AGENTS.md - Silent Execution Policy](AGENTS.md#silent-execution-policy-antigravity-layer-2)

### Layer 3: Execution (Doing the Work)

#### Automation Scripts ([execution/](execution/))

| Script | Purpose | Usage |
|--------|---------|-------|
| **[verify_documentation.py](execution/verify_documentation.py)** | Check SPEC.md ↔ code sync | `python verify_documentation.py` |
| **[check_rules.py](execution/check_rules.py)** | Verify rule references | `python check_rules.py` |
| **[bootstrap_context.py](execution/bootstrap_context.py)** | Verify system ready | `python bootstrap_context.py` |
| **[generate_checkpoint.py](execution/generate_checkpoint.py)** | Save session state | `python generate_checkpoint.py --message "..."` |
| **[restore_checkpoint.py](execution/restore_checkpoint.py)** | Load session state | `python restore_checkpoint.py` |

See [execution/README.md](execution/README.md) for full details.

#### Shell Scripts ([../SpookyID_stack/scripts/](../SpookyID_stack/scripts/))

| Script | Purpose | Usage |
|--------|---------|-------|
| **[bootstrap.sh](../SpookyID_stack/scripts/bootstrap.sh)** | Full system build | `./scripts/bootstrap.sh` |
| **[test.sh](../SpookyID_stack/scripts/test.sh)** | 9-Chain verification suite | `./scripts/test.sh` |
| **[doc_audit.sh](../SpookyID_stack/scripts/doc_audit.sh)** | Documentation accuracy check | `./scripts/doc_audit.sh` |

---

## Documentation by Task

### "I need to understand the system"

1. **Start**: [BOOTSTRAP.md](BOOTSTRAP.md) - 5-minute overview
2. **Architecture**: [SPEC.md](../SpookyID_stack/SPEC.md) - System design
3. **Trust Model**: [CHAINS.md](CHAINS.md) - 9 cryptographic chains
4. **Agents**: [AGENTS.md](AGENTS.md) - Component responsibilities

### "I need to implement a feature"

1. **Check Phase**: [progress.md](progress.md) - Is this on the roadmap?
2. **Which Chain?**: [CHAINS.md - Decision Tree](CHAINS.md#decision-tree-for-ai-agents)
3. **Which Rules Apply?**: [RULES.md](RULES.md) - Search for R-CRYPTO, R-PROTO, etc.
4. **API Reference**: [SPEC.md](../SpookyID_stack/SPEC.md) - Endpoints and data models

### "I need to verify everything works"

1. **Prerequisites**: `python execution/bootstrap_context.py`
2. **Build System**: `cd ../SpookyID_stack && ./scripts/bootstrap.sh`
3. **Run Tests**: `./scripts/test.sh`
4. **Check Docs**: `python execution/verify_documentation.py`
5. **Check Rules**: `python execution/check_rules.py`

### "My context window reset"

1. **Emergency Restore**: [BOOTSTRAP.md](BOOTSTRAP.md)
2. **Load Checkpoint**: `python execution/restore_checkpoint.py`
3. **Check Progress**: [progress.md](progress.md)
4. **Verify System**: `python execution/bootstrap_context.py`

### "I'm handing off to another agent"

1. **Save Checkpoint**: `python execution/generate_checkpoint.py --message "Completed Phase 4"`
2. **Update Progress**: Edit [progress.md](progress.md) - Mark tasks complete
3. **Commit Changes**: Follow Git Safety Protocol in [AGENTS.md](AGENTS.md)

---

## Critical File Paths (Absolute)

**Directives** (this folder):
- `C:\spookyos\SpookyID\multipass\directives\BOOTSTRAP.md`
- `C:\spookyos\SpookyID\multipass\directives\CHAINS.md`
- `C:\spookyos\SpookyID\multipass\directives\RULES.md`
- `C:\spookyos\SpookyID\multipass\directives\AGENTS.md`
- `C:\spookyos\SpookyID\multipass\directives\progress.md`

**Backend Code**:
- `C:\spookyos\SpookyID\SpookyID_stack\backend\src\bin\oidc_service.rs` - Main OIDC server
- `C:\spookyos\SpookyID\SpookyID_stack\backend\src\lib.rs` - BBS+ crypto core
- `C:\spookyos\SpookyID\SpookyID_stack\backend\src\attestation.rs` - Device verification
- `C:\spookyos\SpookyID\SpookyID_stack\backend\src\periwinkle.rs` - Entropy harvesting

**Mobile App**:
- `C:\spookyos\SpookyID\multipass\` - Flutter app root
- `C:\spookyos\SpookyID\multipass\src\lib.rs` - Rust core (UniFFI)

**Resources** (Critical Assets):
- `C:\spookyos\SpookyID\Resources\bbs-signatures-master` - **NON-NEGOTIABLE** BBS+ library
- `C:\spookyos\SpookyID\Resources\pocket-id-main` - OIDC reference implementation
- `C:\spookyos\SpookyID\Resources\eudi-srv-pid-issuer-main.zip` - mDL reference

---

## The 9 Chains (Quick Reference)

| Chain | Purpose | When to Use |
|-------|---------|-------------|
| **1: Lifecycle** | Birth, death, resurrection | Account creation, revocation |
| **2: Entitlements** | Selective disclosure (BBS+) | Proving attributes without revealing identity |
| **3: Contextual** | Unlinkable pseudonyms | Per-site identity (prevent tracking) |
| **4: Delegation** | Temporary authority transfer | Online delegation tokens |
| **5: Recovery** | Sovereign resurrection (Shamir) | Account recovery without custodian |
| **6: Audit** | Privacy-preserving logs | Compliance logging (GDPR-safe) |
| **7: Attestation** | Hardware verification | StrongBox/TEE key validation |
| **8: Federation** | Trust between issuers | Multi-IDP scenarios (not MVP) |
| **9: Leasing** | Offline sudo access | Biometric delegation for 1-click login |

See [CHAINS.md](CHAINS.md) for detailed chain definitions and interaction rules.

---

## Top 10 Rules (Quick Reference)

| Rule | Category | What It Means |
|------|----------|---------------|
| **R-CRYPTO-001** | Cryptography | Use BBS+ for selective disclosure |
| **R-PROTO-001** | Protocol | Follow OIDC standards strictly |
| **R-HW-001** | Hardware | Require StrongBox/TEE for keys |
| **R-PRIV-001** | Privacy | Never log plaintext PII |
| **R-REV-002** | Revocation | Verify anchor active before issuing |
| **R-ERR-001** | Error Handling | Fail-closed on all errors |
| **R-CRYPTO-006** | Zero Knowledge | Use ZK proofs for verification |
| **R-LEASE-001** | Leasing | Sign lease tokens with anchor key |
| **R-LEASE-004** | Leasing | Cascade revocation to leases |
| **R-CRYPTO-008** | Recovery | Use Shamir secret sharing (t=2, n=3) |

See [RULES.md](RULES.md) for all 66 rules.

---

## Current Mission (From progress.md)

**Goal**: Public APK release demonstrating unhackable 1-click login via phone Secure Enclave/StrongBox

**User Story**:
> Users install APK from GitHub → Create account with SpookyID (public IDP) using phone's secure hardware → Seamlessly log into demo sites (Reddit-like, Spotify-like) with 1-click → Demonstrate you make account once, you're unhackable.

**Current Phase**: Phase 2 (Multipass - Mobile Library) - 75% complete
**Next Phase**: Phase 3 (Demo Relying Parties) - Not started

See [progress.md](progress.md) for detailed status.

---

## Essential Commands

### Context Restoration (AI Agent Cold Start)
```bash
# Step 1: Verify system
cd C:\spookyos\SpookyID\multipass\directives\execution
python bootstrap_context.py

# Step 2: Restore session
python restore_checkpoint.py

# Step 3: Read critical docs
cat ../BOOTSTRAP.md
cat ../progress.md
cat ../CHAINS.md
```

### Development Workflow
```bash
# Build everything
cd C:\spookyos\SpookyID\SpookyID_stack
./scripts/bootstrap.sh

# Run tests
./scripts/test.sh

# Check documentation sync
cd ../multipass/directives/execution
python verify_documentation.py
python check_rules.py
```

### Before Committing
```bash
# Verify docs in sync
python execution/verify_documentation.py

# Check rule references
python execution/check_rules.py

# Audit documentation
cd ../../SpookyID_stack
./scripts/doc_audit.sh
```

---

## Troubleshooting

### "I can't find a file"

**Solution**: Use absolute paths from "Critical File Paths" section above.

### "I don't know which document to read"

**Solution**: Follow "Documentation by Task" decision tree above.

### "I forgot what I was working on"

**Solution**:
1. `python execution/restore_checkpoint.py`
2. Read [progress.md](progress.md)

### "Documentation seems out of sync"

**Solution**:
```bash
python execution/verify_documentation.py
# Fix issues it reports
```

### "I need to understand a cryptographic concept"

**Solution**:
1. Read [CHAINS.md](CHAINS.md) for high-level trust architecture
2. Use context7 MCP for library-specific docs (BBS+, etc.)
3. See Resources folder for reference implementations

---

## Version History

### 1.0.0 (2026-01-17)
- Initial index created
- All Layer 1/2/3 documentation indexed
- Task-based navigation added
- Absolute file paths documented

---

**Maintainer**: SpookyOS Project
**Last Updated**: 2026-01-17

*"The map is not the territory, but a good map gets you there faster."*
