# BOOTSTRAP - SpookyID Context Restoration Protocol

**Version**: 1.0.0
**Purpose**: Enable AI agents to restore full context in < 5 minutes after context window reset
**Compatible With**: Antigravity architecture, Claude Code Desktop, context7 MCP
**Last Updated**: 2026-01-17

---

## Emergency Context Restore (Start Here)

If you're an AI agent with a fresh context window, **follow this exact sequence**:

### Step 1: Prerequisites Check (30 seconds)

```bash
# Verify development environment
cargo --version    # Rust 1.70+
node --version     # Node.js 18+
docker --version   # Docker 20+
```

**If missing**: Stop and request user install missing tools.

### Step 2: Read Master Directives (3 minutes)

**Mandatory reading order** (CRITICAL - do not skip):

1. **CHAINS.md** (C:\spookyos\SpookyID\multipass\directives\CHAINS.md)
   - The 9-Chain Sovereign Mesh specification
   - Understand Chain 1 (Lifecycle), Chain 2 (Entitlements/BBS+), Chain 7 (Attestation)

2. **RULES.md** (C:\spookyos\SpookyID\multipass\directives\RULES.md)
   - 66 security/business constraints
   - Focus on: R-CRYPTO-001, R-PROTO-001, R-HW-001, R-PRIV-001, R-REV-002

3. **SPEC.md** (C:\spookyos\SpookyID\SpookyID_stack\SPEC.md)
   - Canonical system architecture (544 lines)
   - API endpoints, crypto primitives, deployment config

4. **Master AGENTS.md** (/c/spookyos/SpookyID/build/antigravity/directives/AGENTS.md)
   - 3-layer architecture (Directive → Orchestration → Execution)
   - Silent execution policy, self-annealing error recovery

### Step 3: Verify System State (90 seconds)

```bash
# Navigate to project root
cd C:\spookyos\SpookyID\SpookyID_stack

# Check current git status
git status

# Verify backend builds
cd backend
cargo check --all

# Verify dashboard dependencies
cd ../dashboard
npm list --depth=0 2>/dev/null | head -20
```

**Expected state**: Backend compiles, dashboard dependencies installed.

---

## Phase Initialization Protocol

Following Antigravity architecture `/build/antigravity/directives/rules.md`:

### Before Starting Any Task

1. **Identify Affected Chains**: Which of the 9 chains does this task touch?
   - Chain 1: Lifecycle (revocation, credentials)
   - Chain 2: Entitlements (BBS+, selective disclosure)
   - Chain 3: Contextual (linkage tags, pseudonyms)
   - Chain 7: Attestation (hardware verification)
   - Chain 9: Leasing (delegation tokens, offline sudo)

2. **Read Applicable Rules**: Check RULES.md for constraints
   - Crypto work → R-CRYPTO-* rules (8 rules)
   - API endpoints → R-PROTO-* rules (8 rules)
   - Hardware → R-HW-* rules (6 rules)
   - Privacy → R-PRIV-* rules (6 rules)

3. **Check Progress**: Read progress.md for current phase status
   - What's in progress?
   - What's blocked?
   - What was recently completed?

4. **Verify Spec Alignment**: Ensure task is documented in SPEC.md
   - New endpoint? Add to SPEC.md FIRST
   - Modifying behavior? Update SPEC.md SIMULTANEOUSLY

---

## Three-Layer Architecture (Antigravity)

```
┌─────────────────────────────────────────────────┐
│ Layer 1: DIRECTIVES (What to do)               │
│  ├─ Human-written SOPs in Markdown             │
│  ├─ Master: /build/antigravity/directives/     │
│  ├─ Local: multipass/directives/               │
│  └─ Examples: AGENTS.md, CHAINS.md, rules.md   │
└─────────────────────────────────────────────────┘
             ↓ Read directives
┌─────────────────────────────────────────────────┐
│ Layer 2: ORCHESTRATION (Decision-making - YOU) │
│  ├─ Context7 MCP for real-time docs            │
│  ├─ Read Layer 1 → Call Layer 3 tools          │
│  ├─ Self-anneal on errors (fix, test, learn)   │
│  └─ Silent execution (zero-prompt policy)       │
└─────────────────────────────────────────────────┘
             ↓ Execute tools
┌─────────────────────────────────────────────────┐
│ Layer 3: EXECUTION (Doing the work)            │
│  ├─ scripts/ → Bash deployment automation      │
│  ├─ execution/ → Python testing/validation     │
│  ├─ .env → Environment variables               │
│  └─ Deterministic, testable, fast              │
└─────────────────────────────────────────────────┘
```

**Key Principle**: No prompting between layers. Directives specify tools → you execute immediately.

---

## Critical File Locations (Absolute Paths)

### Master Directives (Source of Truth)

| File | Location | Purpose |
|------|----------|---------|
| **Master AGENTS.md** | /c/spookyos/SpookyID/build/antigravity/directives/AGENTS.md | 3-layer architecture, silent execution |
| **Master rules.md** | /c/spookyos/SpookyID/build/antigravity/directives/rules.md | Phase initialization, SOPs |
| **Master CHAINS.md** | /c/spookyos/SpookyID/build/antigravity/directives/CHAINS.md | 9-Chain Sovereign Mesh (if exists) |
| **progress.md** | /c/spookyos/SpookyID/build/antigravity/directives/progress.md | Phase status tracking |

### Local Workspace Directives

| File | Location | Purpose |
|------|----------|---------|
| **AGENTS.md** | C:\spookyos\SpookyID\multipass\directives\AGENTS.md | Local agent taxonomy (544 lines) |
| **CHAINS.md** | C:\spookyos\SpookyID\multipass\directives\CHAINS.md | 9-Chain spec (needs completion) |
| **RULES.md** | C:\spookyos\SpookyID\multipass\directives\RULES.md | 66 rules catalog (1589 lines) |
| **progress.md** | C:\spookyos\SpookyID\multipass\directives\progress.md | Current phase (NEW) |

### Core Documentation

| File | Location | Lines | Critical Info |
|------|----------|-------|---------------|
| **SPEC.md** | C:\spookyos\SpookyID\SpookyID_stack\SPEC.md | 544 | Complete system spec (THE BIBLE) |
| **API.md** | C:\spookyos\SpookyID\SpookyID_stack\docs\API.md | - | API endpoint reference |
| **DEPLOYMENT.md** | C:\spookyos\SpookyID\SpookyID_stack\docs\DEPLOYMENT.md | - | Production TLS setup |
| **Whitepaper** | C:\spookyos\SpookyID\SpookyID_stack\docs\Multipass_Whitepaper.md | - | Technical whitepaper |

### Code Locations (Critical Agents)

| Agent | Location | Purpose |
|-------|----------|---------|
| **AGENT_ISSUER_VCI** | backend/src/bin/oidc_service.rs:844-887 | Issues BBS+ credentials |
| **AGENT_VERIFIER_VP** | backend/src/bin/oidc_service.rs:409-637 | Verifies ZK proofs (L1-L4) |
| **AGENT_CRYPTO_BBS** | backend/src/lib.rs:109-555 | BBS+ signatures (MATTR v0.4.1) |
| **AGENT_REVOCATION** | backend/src/db/repositories.rs:119-136 | Manages "graveyard" |
| **AGENT_ENTROPY_PERIWINKLE** | backend/src/periwinkle.rs | 1856-bit AAL3 entropy |

---

## 5-Minute Context Restore Checklist

**Can you answer these 10 questions?** (If no, reread directives)

### Architecture Questions
1. What are the 9 trust chains? (Chain 1-9 names)
2. What's the 3-layer Antigravity architecture? (Directive → Orchestration → Execution)
3. Where is SPEC.md? (The Bible for all changes)
4. What does "fail-closed" mean? (Reject on DB error, not accept)

### Security Questions
5. What is R-CRYPTO-001? (MUST use MATTR BBS v0.4.1 unmodified)
6. What is R-PROTO-001? (Nonce single-use enforcement - anti-replay)
7. What is R-HW-001? (Hardware KeyStore OID required in production)
8. What is R-PRIV-001? (Backend NEVER stores plaintext PII)

### Workflow Questions
9. What's the multi-phase workflow? (Research → Design → Implement → Document → Verify)
10. When do you update docs? (ALWAYS - SPEC.md, RULES.md, CHAINS.md, AGENTS.md simultaneously with code)

**If you can't answer all 10**: You don't have enough context. Read CHAINS.md, RULES.md, SPEC.md now.

---

## Context7 MCP Integration

### What is Context7?

Context7 is an MCP server providing **real-time, version-specific documentation** to prevent hallucinated APIs.

**Use context7 when**:
- Building crypto code → Get current BBS+, BLS12-381 library docs
- Implementing OIDC → Get latest OpenID spec
- Mobile NFC work → Get flutter_nfc_kit current API
- Axum HTTP server → Get latest middleware patterns

### Configuration

**File**: `C:\spookyos\SpookyID\multipass\.claude\settings.json`

```json
{
  "mcpServers": {
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp",
      "headers": {
        "CONTEXT7_API_KEY": "${CONTEXT7_API_KEY}"
      }
    }
  }
}
```

**Environment variable required**: `CONTEXT7_API_KEY` (add to .env)

### Usage Pattern

```
Agent: "Building BBS+ credential issuance endpoint. use context7 to get latest bbs library API"

Context7 fetches:
  - github.com/mattrglobal/bbs (v0.4.1 docs)
  - BLS12-381 pairing library docs
  - Rust crate.io latest examples

Result: Inserted into context → You write version-correct code
```

---

## Layer 3: Execution Scripts

### scripts/ Folder (Bash Automation)

| Script | Location | Purpose |
|--------|----------|---------|
| **bootstrap.sh** | SpookyID_stack/scripts/bootstrap.sh | Full system build (Rust + Node) |
| **test.sh** | SpookyID_stack/scripts/test.sh | Chain verification suite |
| **deploy.sh** | (Reference: eloquent-wilbur workspace) | Production deployment |

**Usage**:
```bash
cd C:\spookyos\SpookyID\SpookyID_stack

# Full bootstrap
./scripts/bootstrap.sh

# Run tests
./scripts/test.sh
```

### Existing Python Scripts

| Script | Location | Purpose |
|--------|----------|---------|
| **bootstrap_root.py** | scripts/bootstrap_root.py | Root certificate ceremony |
| **issue_admin_credential.py** | scripts/issue_admin_credential.py | Admin credential generation |
| **test_linkage_id.py** | scripts/test_linkage_id.py | Chain 1 (Lifecycle) test |
| **test_zk_login.py** | scripts/test_zk_login.py | Chain 2 (BBS+ ZK) test |

---

## Silent Execution Policy

**From Master AGENTS.md**:

> **Silent Execution (Zero-Prompt Policy)**
> "I am now pre-authorized to execute scripts in the execution/ directory. I will no longer pause for confirmation or handshakes unless an action is explicitly identified as 'Destructive' or 'High-Cost'."

**What this means**:

1. **Directives specify tools** → Execute immediately (no asking "should I?")
2. **Read-only operations** → Always allowed (Read, Grep, Glob)
3. **Build/test scripts** → Pre-authorized (cargo build, npm test, ./scripts/test.sh)
4. **Destructive operations** → ASK FIRST (database deletion, git force push, production deployment)

**Examples**:

```
✅ ALLOWED (execute immediately):
- cargo build --release
- npm test
- python3 scripts/test_linkage_id.py
- grep -r "Rule R-" backend/src/
- Read SPEC.md

❌ ASK FIRST (destructive):
- docker-compose down -v  (deletes volumes)
- git push --force
- DELETE FROM revocations (production DB)
- rm -rf backend/target/
```

---

## Self-Annealing Error Recovery

**From Master rules.md**:

> "Self-Annealing Loop: If a tool or script fails, proceed directly to the self-annealing loop: Read the error, fix the script, re-test it autonomously. Only stop to check with you if the fix requires paid tokens or credits."

**Pattern** (when script fails):

```
1. Script fails → Read error message
2. Identify root cause (missing dependency? Wrong path? Syntax error?)
3. Fix script (edit directly)
4. Re-run script
5. If passes → Update directive with learnings
6. If fails again → Repeat 1-5 (max 3 iterations)
7. If still fails after 3 tries → Ask user for help
```

**Example**:

```bash
# Run script
./scripts/bootstrap.sh
# ERROR: cargo: command not found

# Fix: Detect Rust not installed
echo "⚠️ Rust missing. Installing..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Re-run
./scripts/bootstrap.sh
# ✅ Success

# Update BOOTSTRAP.md with prerequisite
# (Add Rust installation to Prerequisites section)
```

---

## Essential Rules Quick Reference

### Top 10 MUST-KNOW Rules

| Rule | Constraint | Violation Consequence |
|------|------------|----------------------|
| **R-CRYPTO-001** | MUST use MATTR BBS v0.4.1 unmodified | Build rejected, security audit fails |
| **R-CRYPTO-002** | Issuer SK MUST be TPM-backed (prod) | Server refuses to start |
| **R-PROTO-001** | Nonce MUST be single-use | 401 Unauthorized (anti-replay) |
| **R-PROTO-002** | Timestamp within 300s of server time | 401 Unauthorized (anti-replay) |
| **R-HW-001** | Production REQUIRES hardware KeyStore | 403 Forbidden (software keys rejected) |
| **R-PRIV-001** | Backend NEVER stores plaintext PII | Code review failure, GDPR violation |
| **R-REV-001** | Revocations table append-only | DB migration rejected, audit alert |
| **R-REV-002** | L2+ MUST check revocation status | Security breach if revoked cred accepted |
| **R-ERR-001** | Fail-closed on DB errors | Request rejected (not accepted) |
| **R-DATA-003** | MUST use parameterized SQL queries | SQL injection vulnerability |

**Full catalog**: See RULES.md (66 rules across 13 categories)

---

## Multi-Phase Workflow (MANDATORY)

**From AGENTS.md Lines 11-41** (HARD NON-NEGOTIABLE):

```
Phase 1: Research & Understanding
  - Read CHAINS.md (identify affected chains)
  - Read RULES.md (security constraints)
  - Document current behavior

Phase 2: Design
  - Create implementation plan
  - Identify all affected files
  - Document expected changes
  - GET USER APPROVAL BEFORE CODING

Phase 3: Implementation
  - Follow approved plan
  - Update code

Phase 4: Documentation Updates (MANDATORY)
  - Update SPEC.md (new/modified endpoints)
  - Update RULES.md (new constraints)
  - Update CHAINS.md (if chains affected)
  - Update AGENTS.md (if agents changed)

Phase 5: Verification
  - Run tests (cargo test, npm test, scripts/test.sh)
  - Verify documentation accuracy
  - Cross-check references
```

**NO EXCEPTIONS**: Every change requires documentation updates.

---

## Emergency "I'm Lost" Recovery

If you're confused or stuck:

### Step 1: Checkpoint Current State
```bash
# What files have I read?
ls -lt multipass/directives/ | head -10

# What was I working on?
git status
git log -1
```

### Step 2: Re-anchor to Directives
```bash
# Read the mission
cat multipass/directives/progress.md

# Read current phase
cat /c/spookyos/SpookyID/build/antigravity/directives/progress.md
```

### Step 3: Ask Clarifying Questions

**Use AskUserQuestion tool** for:
- "Which chain should this feature use?"
- "Is this a Lifecycle (Chain 1) or Entitlements (Chain 2) task?"
- "Should I create a new endpoint or modify existing?"

**Don't guess**. The 9-Chain architecture is precise. Wrong chain = security vulnerability.

### Step 4: Return to SPEC.md

**SPEC.md is the Bible**. If unsure about anything:
1. Search SPEC.md for related keywords
2. Check existing endpoint patterns
3. Follow established conventions

---

## Verification Checklist (Before Commit)

**Before ANY git commit**, verify:

- [ ] Code compiles (`cargo build --release`, `npm run build`)
- [ ] Tests pass (`cargo test --all`, `npm test`)
- [ ] SPEC.md updated (new endpoints documented)
- [ ] RULES.md updated (new constraints added)
- [ ] CHAINS.md updated (if chains affected)
- [ ] AGENTS.md updated (if agents changed)
- [ ] No "TODO" or "FIXME" comments left unresolved
- [ ] No first-person language ("I am...") in directive files

**Automated check**:
```bash
# Check for undocumented changes
git diff backend/src/ | grep "\.route(" | wc -l
# If > 0, must update SPEC.md

# Check for new rules
git diff backend/src/ | grep "Rule R-" | wc -l
# If > 0, must verify RULES.md has those rules
```

---

## Reference Workspace Patterns

**Eloquent-Wilbur** (/c/spookyos/SpookyID/build/antigravity/antigravity/eloquent-wilbur/):

```
eloquent-wilbur/
├── directives/        # Layer 1 (SOPs)
├── execution/         # Layer 3 (Python tests)
├── SpookyID-Deploy/   # Production package
│   ├── scripts/       # deploy.sh, test.sh, backup.sh
│   ├── backend/       # Rust service
│   └── dashboards/    # Next.js + Vite UIs
└── PACKAGE_MANIFEST.md
```

**Follow this pattern** for new workspaces.

---

## Quick Command Reference

### Build Commands
```bash
# Backend (Rust)
cd backend
cargo build --release
cargo test --all

# Dashboard (Next.js)
cd dashboard
npm install
npm run build
npm run dev  # Dev server on port 3000

# Docker (full stack)
docker-compose up -d
docker-compose logs -f backend
```

### Test Commands
```bash
# Rust unit tests
cargo test --lib

# Python integration tests
python3 scripts/test_linkage_id.py
python3 scripts/test_zk_login.py

# Chain verification
./scripts/test.sh
```

### Documentation Checks
```bash
# Find all endpoints
grep -r "router.route" backend/src/ | sed 's/.*"\([^"]*\)".*/\1/' | sort

# Find all rules
grep -r "Rule R-" backend/src/ | sed 's/.*Rule \(R-[A-Z]*-[0-9]*\).*/\1/' | sort -u

# Find all chain references
grep -r "Chain [0-9]" backend/src/ | sed 's/.*Chain \([0-9]\).*/\1/' | sort -u
```

---

## Ports & URLs

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| **Backend OIDC** | 7777 | http://localhost:7777 | Main API server |
| **Dashboard** | 3000 | http://localhost:3000 | Admin UI |
| **Health Check** | 7777 | http://localhost:7777/health | Liveness probe |
| **OIDC Discovery** | 7777 | http://localhost:7777/.well-known/openid-configuration | Metadata |

**Production**:
- Backend: https://api.getspooky.io
- Dashboard: https://dashboard.getspooky.io

---

## Final Checklist: Am I Ready to Work?

Before starting ANY task, confirm:

- [x] I've read CHAINS.md (understand 9-Chain mesh)
- [x] I've read RULES.md (know R-CRYPTO-*, R-PROTO-*, R-HW-*, R-PRIV-* rules)
- [x] I've read SPEC.md (canonical system architecture)
- [x] I know the 3-layer architecture (Directive → Orchestration → Execution)
- [x] I know the multi-phase workflow (Research → Design → Implement → Document → Verify)
- [x] I know when to use context7 (for real-time library docs)
- [x] I know the silent execution policy (execute tools immediately unless destructive)
- [x] I know fail-closed principle (reject on error, not accept)
- [x] I can answer the 10 checkpoint questions above
- [x] I know where SPEC.md is and will update it with ALL changes

**If ANY checkbox is unchecked**: Go back and read the referenced directive.

---

**END OF BOOTSTRAP.MD**

*"Context is not optional. Context is the foundation of trust."*

**Next**: Read progress.md for current phase status, then begin work following multi-phase workflow.
