# SpookyID Execution Layer - Automation Framework

**Version**: 1.0.0
**Purpose**: Deterministic validation and automation scripts for SpookyID project
**Layer**: 3 (Execution - Antigravity architecture)
**Last Updated**: 2026-01-17

---

## Overview

This directory contains Python automation scripts that implement **Layer 3 (Execution)** of the Antigravity architecture. These scripts provide:

- **Documentation verification** - Ensure code and docs stay in sync
- **Rule enforcement checking** - Verify all R-* rules are properly defined
- **Context restoration** - Help AI agents resume work after context reset
- **Session checkpointing** - Save/restore work state across sessions

**Philosophy**: These scripts are deterministic, testable, and version-controlled. They replace manual verification steps with automated, repeatable processes.

---

## Scripts

### 1. verify_documentation.py

**Purpose**: Check that SPEC.md matches actual endpoints in code, RULES.md references exist, and CHAINS.md integrations are documented.

**Usage**:
```bash
python verify_documentation.py
```

**Output**:
- ✓ All endpoints documented (or list of missing endpoints)
- ✓ All rule references are defined (or list of undefined rules)
- ✓ All chain references are documented (or list of undocumented chains)
- Exit code 0 = success, 1 = issues found

**Use Cases**:
- Pre-commit hooks (ensure docs updated before committing code)
- CI/CD pipelines (fail build if docs out of sync)
- Manual verification after code changes

---

### 2. check_rules.py

**Purpose**: Extract all "Rule R-*" comments from code and verify each rule exists in RULES.md.

**Usage**:
```bash
python check_rules.py           # Basic check
python check_rules.py --verbose # Show file locations
```

**Output**:
- List of all rules referenced in code
- ✓ Rules that are properly defined
- ✗ Rules that are missing from RULES.md
- Exit code 0 = all rules defined, 1 = missing rules

**Use Cases**:
- Ensure new code follows rule documentation standards
- Find orphaned rule references
- Verify RULES.md completeness

---

### 3. bootstrap_context.py

**Purpose**: Verify system is ready to work - check prerequisites, files exist, environment variables set, binaries built.

**Usage**:
```bash
python bootstrap_context.py       # Verification only
python bootstrap_context.py --fix # Attempt to fix issues
```

**Output**:
- ✓ Prerequisites (cargo, node, docker, python3)
- ✓ Critical files (BOOTSTRAP.md, CHAINS.md, SPEC.md, etc.)
- ✓ Environment variables (DATABASE_URL, SPOOKY_ISSUER, etc.)
- ✓ Built binaries (oidc_service)
- ✓ Documentation sync status
- Exit code 0 = ready to work, 1 = issues found

**Use Cases**:
- **AI agent cold start** - First script to run after context reset
- **New developer onboarding** - Verify environment setup
- **Deployment verification** - Check production readiness

---

### 4. generate_checkpoint.py

**Purpose**: Save current session state for handoff to next AI agent session.

**Usage**:
```bash
python generate_checkpoint.py
python generate_checkpoint.py --message "Working on Chain 9 leasing"
```

**Output**:
- Creates `checkpoints/checkpoint_YYYYMMDD_HHMMSS.md`
- Captures current phase, blockers, recent completions
- Provides restoration protocol
- Returns path to checkpoint file

**Checkpoint Contents**:
- Session context (user message, timestamp)
- Current work state (active phase, blockers)
- Restoration protocol (how to resume)
- Next actions (suggested tasks)
- Critical reminders (sovereignty, privacy, fail-closed)

**Use Cases**:
- **Context window approaching limit** - Save state before reset
- **Session handoff** - One AI agent hands work to another
- **Daily checkpoints** - Track progress over multi-day work
- **Emergency save** - Preserve state before risky operation

---

### 5. restore_checkpoint.py

**Purpose**: Load most recent checkpoint and display what was being worked on.

**Usage**:
```bash
python restore_checkpoint.py                             # Load most recent
python restore_checkpoint.py --list                      # List all checkpoints
python restore_checkpoint.py --checkpoint checkpoint_20260117_143022.md
```

**Output**:
- Displays checkpoint contents with syntax highlighting
- Shows session context, active phase, blockers
- Suggests next actions
- Exit code 0 = success

**Use Cases**:
- **AI agent context restore** - Second script to run after bootstrap_context.py
- **Review previous session** - See what was done last time
- **Choose specific checkpoint** - Restore from particular save point

---

## Typical AI Agent Workflow

### Cold Start (Context Reset)

```bash
# Step 1: Verify system ready
cd C:\spookyos\SpookyID\multipass\directives\execution
python bootstrap_context.py

# Step 2: Restore session state
python restore_checkpoint.py

# Step 3: Read critical directives
cat ../BOOTSTRAP.md
cat ../progress.md
cat ../CHAINS.md

# Step 4: Verify documentation in sync
python verify_documentation.py
python check_rules.py

# Step 5: Continue work...
```

### Before Ending Session

```bash
# Save checkpoint for next session
python generate_checkpoint.py --message "Completed Phase 4, starting Phase 5"
```

---

## Integration with Pre-Commit Hooks

To run these scripts automatically before committing:

### Option 1: Git Hooks

Create `.git/hooks/pre-commit`:
```bash
#!/bin/bash

echo "Running documentation verification..."
cd multipass/directives/execution
python verify_documentation.py

if [ $? -ne 0 ]; then
    echo "Documentation is out of sync. Update docs before committing."
    exit 1
fi

python check_rules.py
if [ $? -ne 0 ]; then
    echo "Rule references are incomplete. Update RULES.md before committing."
    exit 1
fi

echo "✓ Pre-commit checks passed"
```

### Option 2: Pre-Commit Framework

Add to `.pre-commit-config.yaml`:
```yaml
repos:
  - repo: local
    hooks:
      - id: verify-docs
        name: Verify Documentation
        entry: python multipass/directives/execution/verify_documentation.py
        language: python
        pass_filenames: false

      - id: check-rules
        name: Check Rule References
        entry: python multipass/directives/execution/check_rules.py
        language: python
        pass_filenames: false
```

---

## Dependencies

**Required**:
- Python 3.7+
- pathlib (standard library)
- re (standard library)

**No external dependencies** - all scripts use Python standard library only.

---

## Exit Codes

All scripts follow Unix conventions:
- **0**: Success (no issues found)
- **1**: Issues found or errors encountered

This allows integration with CI/CD pipelines and pre-commit hooks.

---

## Antigravity Architecture Compliance

These scripts implement **Layer 3 (Execution)** principles:

✅ **Deterministic**: Same input → Same output
✅ **Testable**: Can be run independently
✅ **Fast**: Execute in < 30 seconds
✅ **Reliable**: No external API dependencies
✅ **Version-controlled**: Part of git repository

**No prompting** - Scripts execute silently and return results. Layer 2 (Orchestration - AI agent) decides what to do with results.

---

## Troubleshooting

### Script can't find project root

**Symptom**: `Error: Could not find SpookyID project root`

**Fix**: Run scripts from one of these locations:
- `C:\spookyos\SpookyID\SpookyID_stack\` (backend root)
- `C:\spookyos\SpookyID\multipass\directives\execution\` (script location)

Or provide absolute paths.

### Documentation verification finds many issues

**Symptom**: `Found 33 endpoints not documented`

**Fix**: This is expected after initial setup. Run:
```bash
# Generate list of missing endpoints
python verify_documentation.py > doc_issues.txt

# Update SPEC.md manually or use findings to prioritize documentation work
```

### Environment variables not detected

**Symptom**: `⚠ Not set: DATABASE_URL`

**Fix**: Create `.env` file in project root or set environment variables:
```bash
export DATABASE_URL=postgresql://postgres:password@localhost:5432/spookyid
export SPOOKY_ISSUER=http://localhost:7777
```

---

## Contributing

When adding new automation scripts:

1. Follow naming convention: `verb_noun.py` (e.g., `check_rules.py`, `verify_documentation.py`)
2. Include docstring with Purpose, Layer, Usage
3. Use Colors class for terminal output
4. Return proper exit codes (0 = success, 1 = failure)
5. Support `--help` flag
6. Update this README with new script documentation

---

## Version History

### 1.0.0 (2026-01-17)
- Initial release
- 5 core automation scripts
- Antigravity Layer 3 compliant
- Zero external dependencies

---

**Maintainer**: SpookyOS Project
**License**: Same as SpookyID project
**Contact**: See main project README
