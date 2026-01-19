#!/usr/bin/env python3
"""
generate_checkpoint.py - SpookyID Session Checkpoint Generator

Purpose: Save current session state (what files were read, what tasks in progress)
         and create handoff document for next agent session.

Layer: 3 (Execution - Deterministic state capture)
Compatible with: Antigravity architecture

Usage: python generate_checkpoint.py [--message "Working on Chain 9 implementation"]
"""

import sys
import json
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Any

# Colors for terminal output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'


def find_directives_dir() -> Path:
    """Find the directives directory."""
    current = Path.cwd()

    # Try multipass directives location
    if (current / "directives" / "BOOTSTRAP.md").exists():
        return current / "directives"

    # Search upward
    for parent in current.parents:
        if (parent / "multipass" / "directives" / "BOOTSTRAP.md").exists():
            return parent / "multipass" / "directives"
        if (parent / "directives" / "BOOTSTRAP.md").exists():
            return parent / "directives"

    # Fallback
    print(f"{Colors.YELLOW}Warning: Could not find directives folder, using current directory{Colors.NC}")
    return current


def read_progress_md(directives_dir: Path) -> Dict[str, Any]:
    """Extract current state from progress.md."""
    progress_file = directives_dir / "progress.md"

    state = {
        "current_phase": "Unknown",
        "active_blockers": [],
        "recent_completions": []
    }

    if not progress_file.exists():
        return state

    content = progress_file.read_text(encoding='utf-8')

    # Extract current phase (look for "Phase X: ... IN PROGRESS")
    import re
    phase_match = re.search(r'### Phase \d+:.*?[WARN]️ IN PROGRESS \((\d+)%\)', content)
    if phase_match:
        state["current_phase"] = phase_match.group(0)

    # Extract blockers (look for "## Dependencies & Blockers" section)
    blockers_section = re.search(r'## Dependencies & Blockers.*?^##', content, re.MULTILINE | re.DOTALL)
    if blockers_section:
        blockers = re.findall(r'^\d+\.\s+\*\*(.+?)\*\*', blockers_section.group(0), re.MULTILINE)
        state["active_blockers"] = blockers[:5]  # Top 5

    # Extract recent completions
    completions_section = re.search(r'## Recent Completions.*?^##', content, re.MULTILINE | re.DOTALL)
    if completions_section:
        completions = re.findall(r'^- ✅ (.+)$', completions_section.group(0), re.MULTILINE)
        state["recent_completions"] = completions[:5]  # Top 5

    return state


def generate_checkpoint(directives_dir: Path, user_message: str = None) -> Path:
    """Generate checkpoint markdown file."""
    # Create checkpoints directory
    checkpoints_dir = directives_dir / "checkpoints"
    checkpoints_dir.mkdir(exist_ok=True)

    # Generate timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    checkpoint_file = checkpoints_dir / f"checkpoint_{timestamp}.md"

    # Read current state
    progress_state = read_progress_md(directives_dir)

    # Build checkpoint content
    content = f"""# SpookyID Session Checkpoint

**Generated**: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}
**Checkpoint ID**: {timestamp}

---

## Session Context

{f'**User Message**: {user_message}' if user_message else '**User Message**: (none provided)'}

---

## Current Work State

### Active Phase

{progress_state.get('current_phase', 'Unknown - check progress.md')}

### Recent Completions

"""

    if progress_state["recent_completions"]:
        for completion in progress_state["recent_completions"]:
            content += f"- ✅ {completion}\n"
    else:
        content += "- (none found in progress.md)\n"

    content += "\n### Active Blockers\n\n"

    if progress_state["active_blockers"]:
        for i, blocker in enumerate(progress_state["active_blockers"], 1):
            content += f"{i}. {blocker}\n"
    else:
        content += "- (none found in progress.md)\n"

    content += """
---

## Restoration Protocol

When resuming from this checkpoint:

1. **Read BOOTSTRAP.md** for 5-minute context restore
2. **Read progress.md** for current phase status
3. **Read CHAINS.md** for trust architecture
4. **Read this checkpoint** for session-specific context

### Quick Restore Commands

```bash
# Navigate to project
cd C:\\spookyos\\SpookyID

# Read critical files
cat multipass/directives/BOOTSTRAP.md
cat multipass/directives/progress.md
cat multipass/directives/checkpoints/checkpoint_{timestamp}.md

# Verify system state
cd multipass/directives/execution
python bootstrap_context.py
```

---

## Files Modified in This Session

(To be filled manually if needed - track with git status)

```bash
git status
git diff
```

---

## Next Actions

Based on current state:

"""

    if "Phase 2" in progress_state.get("current_phase", ""):
        content += "1. Complete Multipass OIDC client implementation\n"
        content += "2. Implement Chain 9 (Leasing) client-side integration\n"
        content += "3. Build account creation wizard UI\n"
    elif "Phase 3" in progress_state.get("current_phase", ""):
        content += "1. Start SpookySocial demo site development\n"
        content += "2. Implement OIDC relying party integration\n"
        content += "3. Create QR code login flow\n"
    else:
        content += "1. Check progress.md for current priorities\n"
        content += "2. Run bootstrap_context.py to verify system state\n"
        content += "3. Continue with active phase tasks\n"

    content += """
---

## Critical Reminders

- **User Sovereignty**: Never design features that give SpookyID custody
- **Privacy by Default**: Never log plaintext PII, never correlate across sites
- **Fail-Closed Security**: Reject on error, don't accept by default
- **BBS+ Library**: NON-NEGOTIABLE - located at Resources/bbs-signatures-master

---

**Checkpoint saved**. Use `restore_checkpoint.py` to load this state.
"""

    # Write checkpoint
    checkpoint_file.write_text(content, encoding='utf-8')

    return checkpoint_file


def main():
    """Main checkpoint generation logic."""
    # Parse user message
    user_message = None
    if "--message" in sys.argv:
        idx = sys.argv.index("--message")
        if idx + 1 < len(sys.argv):
            user_message = sys.argv[idx + 1]

    print(f"{Colors.BLUE}{'=' * 60}{Colors.NC}")
    print(f"{Colors.BLUE}  SpookyID Session Checkpoint Generator{Colors.NC}")
    print(f"{Colors.BLUE}{'=' * 60}{Colors.NC}\n")

    directives_dir = find_directives_dir()
    print(f"Directives location: {directives_dir}\n")

    print(f"{Colors.BLUE}Generating checkpoint...{Colors.NC}\n")

    checkpoint_file = generate_checkpoint(directives_dir, user_message)

    print(f"{Colors.GREEN}[OK] Checkpoint saved:{Colors.NC} {checkpoint_file}")
    print(f"\nTo restore this checkpoint:")
    print(f"  python restore_checkpoint.py --checkpoint {checkpoint_file.name}")
    print(f"  python restore_checkpoint.py  # (loads most recent)")

    return 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] in ["--help", "-h"]:
        print(__doc__)
        sys.exit(0)

    sys.exit(main())
