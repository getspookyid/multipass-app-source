# Standard Operating Procedures (SOP)

**Master SOP Location**: `/c/spookyos/SpookyID/build/antigravity/directives/rules.md`

---

## What's in the Master rules.md

The master rules.md contains:

### 1. Phase Initialization Protocol
- What to read before starting any task
- When to reference which documents (SPEC.md, CHAINS.md, AGENTS.md)
- Context restoration checklist

### 2. Forbidden Operations
- Never update git config
- Never run destructive git commands (force push, hard reset) without explicit permission
- Never skip hooks (--no-verify)
- Never commit changes unless explicitly asked

### 3. Verification Gates
- Documentation accuracy checks
- Rule enforcement verification
- Chain integration validation

### 4. Self-Annealing Error Recovery
- Read error → Fix script → Test → Update directive
- Autonomous error correction loop
- Stop only if fix requires paid tokens/credits

### 5. The Armory (Mandatory Tooling)
- **Context7 MCP**: Real-time, version-specific documentation (prevents API hallucination)
- **Pinecone/RAG**: Long-term memory retrieval of 9-Chain Sovereign Mesh
- **Rust Crypto Core**: All identity math executed in hub crate for memory safety

---

## DO NOT DUPLICATE

**IMPORTANT**: Do NOT copy rules.md to local workspace. Always read from master location.

**Rationale**: Antigravity architecture uses single master rules.md to prevent version drift. Multiple copies = inconsistency = security vulnerabilities.

---

## How to Access

```bash
# Read master rules.md
cat /c/spookyos/SpookyID/build/antigravity/directives/rules.md

# Or in Windows
type C:\spookyos\SpookyID\build\antigravity\directives\rules.md
```

---

## Quick Reference Links

| Document | Purpose | Location |
|----------|---------|----------|
| **rules.md** | Phase initialization, SOPs | /c/spookyos/SpookyID/build/antigravity/directives/rules.md |
| **AGENTS.md (master)** | 3-layer architecture, silent execution | /c/spookyos/SpookyID/build/antigravity/directives/AGENTS.md |
| **CHAINS.md (master)** | 9-Chain Sovereign Mesh (if exists) | /c/spookyos/SpookyID/build/antigravity/directives/CHAINS.md |
| **progress.md** | Phase tracking | /c/spookyos/SpookyID/build/antigravity/directives/progress.md |

---

**END OF rules_link.md**

*Always defer to master. Single source of truth.*
