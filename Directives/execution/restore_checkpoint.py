#!/usr/bin/env python3
"""
restore_checkpoint.py - SpookyID Session Checkpoint Restorer

Purpose: Load most recent checkpoint and display what was being worked on,
         then suggest next actions based on checkpoint state.

Layer: 3 (Execution - Deterministic state restoration)
Compatible with: Antigravity architecture

Usage: python restore_checkpoint.py
       python restore_checkpoint.py --checkpoint checkpoint_20260117_143022.md
       python restore_checkpoint.py --list
"""

import sys
from pathlib import Path
from datetime import datetime

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


def list_checkpoints(checkpoints_dir: Path) -> list:
    """List all available checkpoints, sorted by date (newest first)."""
    if not checkpoints_dir.exists():
        return []

    checkpoints = sorted(
        checkpoints_dir.glob("checkpoint_*.md"),
        key=lambda p: p.stat().st_mtime,
        reverse=True
    )

    return checkpoints


def get_checkpoint_summary(checkpoint_file: Path) -> dict:
    """Extract summary information from checkpoint file."""
    content = checkpoint_file.read_text(encoding='utf-8')

    summary = {
        "timestamp": "Unknown",
        "user_message": "None",
        "current_phase": "Unknown"
    }

    # Extract timestamp
    import re
    timestamp_match = re.search(r'\*\*Generated\*\*:\s*(.+)', content)
    if timestamp_match:
        summary["timestamp"] = timestamp_match.group(1).strip()

    # Extract user message
    message_match = re.search(r'\*\*User Message\*\*:\s*(.+)', content)
    if message_match:
        summary["user_message"] = message_match.group(1).strip()

    # Extract current phase
    phase_match = re.search(r'### Active Phase\s*\n\n(.+)', content)
    if phase_match:
        summary["current_phase"] = phase_match.group(1).strip()

    return summary


def display_checkpoint(checkpoint_file: Path):
    """Display checkpoint contents with syntax highlighting."""
    content = checkpoint_file.read_text(encoding='utf-8')

    print(f"{Colors.BLUE}{'=' * 60}{Colors.NC}")
    print(f"{Colors.BLUE}  Checkpoint: {checkpoint_file.name}{Colors.NC}")
    print(f"{Colors.BLUE}{'=' * 60}{Colors.NC}\n")

    # Parse and display with colors
    lines = content.split('\n')

    for line in lines:
        if line.startswith('# '):
            print(f"{Colors.BLUE}{line}{Colors.NC}")
        elif line.startswith('## '):
            print(f"{Colors.YELLOW}{line}{Colors.NC}")
        elif line.startswith('### '):
            print(f"{Colors.YELLOW}{line}{Colors.NC}")
        elif line.startswith('**'):
            print(f"{Colors.GREEN}{line}{Colors.NC}")
        elif '✅' in line:
            print(f"{Colors.GREEN}{line}{Colors.NC}")
        elif line.startswith('```'):
            print(f"{Colors.BLUE}{line}{Colors.NC}")
        else:
            print(line)

    print()


def main():
    """Main checkpoint restoration logic."""
    # Parse arguments
    list_mode = "--list" in sys.argv
    checkpoint_name = None

    if "--checkpoint" in sys.argv:
        idx = sys.argv.index("--checkpoint")
        if idx + 1 < len(sys.argv):
            checkpoint_name = sys.argv[idx + 1]

    directives_dir = find_directives_dir()
    checkpoints_dir = directives_dir / "checkpoints"

    if not checkpoints_dir.exists():
        print(f"{Colors.RED}Error: No checkpoints directory found at {checkpoints_dir}{Colors.NC}")
        print(f"\nCreate a checkpoint with: python generate_checkpoint.py")
        return 1

    checkpoints = list_checkpoints(checkpoints_dir)

    if not checkpoints:
        print(f"{Colors.YELLOW}No checkpoints found{Colors.NC}")
        print(f"\nCreate a checkpoint with: python generate_checkpoint.py")
        return 1

    # List mode
    if list_mode:
        print(f"{Colors.BLUE}{'=' * 60}{Colors.NC}")
        print(f"{Colors.BLUE}  Available Checkpoints{Colors.NC}")
        print(f"{Colors.BLUE}{'=' * 60}{Colors.NC}\n")

        for i, checkpoint in enumerate(checkpoints, 1):
            summary = get_checkpoint_summary(checkpoint)
            print(f"{i}. {Colors.GREEN}{checkpoint.name}{Colors.NC}")
            print(f"   Generated: {summary['timestamp']}")
            print(f"   Message: {summary['user_message']}")
            print(f"   Phase: {summary['current_phase'][:60]}...")
            print()

        print(f"To restore a checkpoint:")
        print(f"  python restore_checkpoint.py --checkpoint {checkpoints[0].name}")
        return 0

    # Restore specific checkpoint
    if checkpoint_name:
        checkpoint_file = checkpoints_dir / checkpoint_name
        if not checkpoint_file.exists():
            print(f"{Colors.RED}Error: Checkpoint not found: {checkpoint_name}{Colors.NC}")
            print(f"\nUse --list to see available checkpoints")
            return 1
    else:
        # Use most recent checkpoint
        checkpoint_file = checkpoints[0]
        print(f"{Colors.GREEN}Loading most recent checkpoint: {checkpoint_file.name}{Colors.NC}\n")

    # Display checkpoint
    display_checkpoint(checkpoint_file)

    # Summary
    print(f"{Colors.GREEN}[OK] Checkpoint restored{Colors.NC}")
    print(f"\nNext steps:")
    print(f"  1. Read the 'Next Actions' section above")
    print(f"  2. Run: python bootstrap_context.py")
    print(f"  3. Check progress.md for current priorities")

    return 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] in ["--help", "-h"]:
        print(__doc__)
        sys.exit(0)

    sys.exit(main())
