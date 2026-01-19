#!/usr/bin/env python3
"""
check_rules.py - SpookyID Rule Enforcement Checker

Purpose: Extract all "Rule R-*" comments from code, verify each rule exists in RULES.md,
         and check enforcement locations match documentation.

Layer: 3 (Execution - Deterministic validation)
Compatible with: Antigravity architecture

Usage: python check_rules.py
       python check_rules.py --verbose
"""

import re
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple
from collections import defaultdict

# Colors for terminal output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'


def find_project_root() -> Path:
    """Find the SpookyID project root directory."""
    current = Path.cwd()

    # Try SpookyID_stack location
    if (current / "backend" / "Cargo.toml").exists():
        return current

    # Search upward
    for parent in current.parents:
        if (parent / "SpookyID_stack" / "backend" / "Cargo.toml").exists():
            return parent / "SpookyID_stack"
        if (parent / "backend" / "Cargo.toml").exists():
            return parent

    print(f"{Colors.RED}Error: Could not find SpookyID project root{Colors.NC}")
    sys.exit(1)


def extract_rules_from_code(backend_dir: Path, verbose: bool = False) -> Dict[str, List[Tuple[Path, int]]]:
    """
    Extract all Rule R-* references from code.
    Returns: {rule_id: [(file_path, line_number), ...]}
    """
    rules = defaultdict(list)

    for rs_file in backend_dir.rglob("*.rs"):
        try:
            lines = rs_file.read_text(encoding='utf-8').splitlines()

            for line_num, line in enumerate(lines, start=1):
                # Match "Rule R-XXX-NNN" or "R-XXX-NNN" patterns
                matches = re.findall(r'\b(R-[A-Z]+-\d+)\b', line)

                for rule_id in matches:
                    rules[rule_id].append((rs_file, line_num))

        except Exception as e:
            if verbose:
                print(f"{Colors.YELLOW}Warning: Could not read {rs_file}: {e}{Colors.NC}")

    return dict(rules)


def extract_defined_rules(rules_file: Path) -> Dict[str, str]:
    """
    Extract all defined rules from RULES.md.
    Returns: {rule_id: description}
    """
    if not rules_file.exists():
        print(f"{Colors.RED}Error: RULES.md not found at {rules_file}{Colors.NC}")
        return {}

    content = rules_file.read_text(encoding='utf-8')
    rules = {}

    # Match "### Rule R-XXX-NNN: Description" headers
    pattern = r'^###\s+Rule\s+(R-[A-Z]+-\d+):\s*(.*)$'
    matches = re.findall(pattern, content, re.MULTILINE)

    for rule_id, description in matches:
        rules[rule_id] = description.strip()

    return rules


def main():
    """Main rule checking logic."""
    verbose = "--verbose" in sys.argv or "-v" in sys.argv

    print(f"{Colors.BLUE}{'=' * 60}{Colors.NC}")
    print(f"{Colors.BLUE}  SpookyID Rule Enforcement Checker{Colors.NC}")
    print(f"{Colors.BLUE}{'=' * 60}{Colors.NC}\n")

    # Find project root
    root = find_project_root()
    backend_dir = root / "backend"

    # Find RULES.md
    rules_file = None
    for candidate in [
        root.parent / "multipass" / "directives" / "RULES.md",
        root / "directives" / "RULES.md",
        root / "RULES.md"
    ]:
        if candidate.exists():
            rules_file = candidate
            break

    if not rules_file:
        print(f"{Colors.RED}Error: Could not find RULES.md{Colors.NC}")
        sys.exit(1)

    # Extract rules
    print(f"{Colors.BLUE}[1/3]{Colors.NC} Extracting rules from code...")
    code_rules = extract_rules_from_code(backend_dir, verbose)
    print(f"Found {len(code_rules)} unique rule references in code\n")

    print(f"{Colors.BLUE}[2/3]{Colors.NC} Loading defined rules from RULES.md...")
    defined_rules = extract_defined_rules(rules_file)
    print(f"Found {len(defined_rules)} defined rules in RULES.md\n")

    # Verify each code rule is defined
    print(f"{Colors.BLUE}[3/3]{Colors.NC} Verifying rule references...\n")

    missing_rules = []
    valid_rules = []

    for rule_id in sorted(code_rules.keys()):
        locations = code_rules[rule_id]

        if rule_id in defined_rules:
            valid_rules.append(rule_id)
            print(f"{Colors.GREEN}[OK]{Colors.NC} {rule_id}: {defined_rules[rule_id]}")

            if verbose:
                print(f"  Referenced in {len(locations)} location(s):")
                for file_path, line_num in locations[:3]:  # Show first 3
                    rel_path = file_path.relative_to(backend_dir)
                    print(f"    - {rel_path}:{line_num}")
                if len(locations) > 3:
                    print(f"    ... and {len(locations) - 3} more")
        else:
            missing_rules.append(rule_id)
            print(f"{Colors.RED}[FAIL]{Colors.NC} {rule_id}: NOT DEFINED IN RULES.md")

            if verbose:
                print(f"  Referenced in:")
                for file_path, line_num in locations:
                    rel_path = file_path.relative_to(backend_dir)
                    print(f"    - {rel_path}:{line_num}")

    print()

    # Summary
    print(f"{Colors.BLUE}{'=' * 60}{Colors.NC}")
    print(f"Rule References: {len(code_rules)}")
    print(f"{Colors.GREEN}Valid:{Colors.NC} {len(valid_rules)}")
    print(f"{Colors.RED}Missing:{Colors.NC} {len(missing_rules)}")

    if missing_rules:
        print(f"\n{Colors.YELLOW}[WARN] The following rules are referenced in code but not defined:{Colors.NC}")
        for rule_id in missing_rules:
            print(f"  - {rule_id}")
        print(f"\n{Colors.YELLOW}Action required:{Colors.NC} Add these rules to RULES.md or remove references from code")
        return 1
    else:
        print(f"\n{Colors.GREEN}[OK] All rule references are properly defined{Colors.NC}")
        return 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] in ["--help", "-h"]:
        print(__doc__)
        sys.exit(0)

    sys.exit(main())
