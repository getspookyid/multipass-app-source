# Resources Folder

**Purpose**: Temporary pool of reference materials for AI agents during planning and research phases.

## Usage

This folder contains ephemeral reading materials that AI coding agents should check when requested by the user.

### For Users

**Add materials here when**:
- Planning a new feature and have reference specs
- Researching security patterns
- Evaluating third-party integrations
- Conducting performance analysis
- Making architectural decisions

**Examples**:
```bash
# Add BBS+ optimization paper
cp ~/Downloads/bbs-signatures-2024.pdf resources/

# Add mDL integration spec
cp ~/Downloads/ISO-18013-5.pdf resources/

# Add security audit findings
cp ~/Downloads/audit-2026-Q1.md resources/
```

### For AI Agents

**When user says** "check resources" or "see resources folder":

1. List contents:
   ```bash
   ls multipass/Directives/resources/
   ```

2. Read relevant files based on task context

3. Apply insights to planning phase

4. Reference specific documents in your implementation plan

**Important**:
- ❌ Do NOT assume files persist between conversations
- ❌ Do NOT treat resources as canonical documentation
- ❌ Do NOT update SPEC.md/RULES.md based solely on resources
- ✅ DO use for research during Phase 1 (Research & Understanding)
- ✅ DO cite specific resources in design decisions
- ✅ DO ask user if resources have relevant content for task

## Lifecycle

- **Added**: By user as needed for specific tasks
- **Used**: By AI agents during planning/research
- **Removed**: By user when no longer relevant
- **Duration**: Temporary (user discretion)

## Not Included

This folder does NOT contain:
- Core documentation (see parent directory)
- Source code
- Configuration files
- Credentials or secrets
- Production data

## Example Workflow

```
User: "I want to optimize BBS+ proof generation. Check resources for any papers on this."

Agent:
  1. ls multipass/Directives/resources/
  2. Found: bbs-signatures-optimization-2024.pdf
  3. Read PDF
  4. Apply findings to Phase 2 (Design)
  5. Create implementation plan citing the paper
  6. Get user approval before Phase 3 (Implementation)
```

---

**Current Contents**: (User maintains this list)

- (Empty - add your research materials as needed)
