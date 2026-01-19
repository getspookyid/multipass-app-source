#!/usr/bin/env python3
"""
verify_documentation.py - SpookyID Documentation Accuracy Verifier

Purpose: Check that SPEC.md matches actual endpoints, RULES.md references exist in code,
         and CHAINS.md integrations are documented.

Layer: 3 (Execution - Deterministic validation)
Compatible with: Antigravity architecture

Usage: python verify_documentation.py
       python verify_documentation.py --help
"""

import re
import sys
from pathlib import Path
from typing import List, Set, Tuple

# Colors for terminal output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'  # No Color


def find_project_root() -> Path:
    """Find the SpookyID project root directory."""
    current = Path.cwd()

    # Try multipass directives location
    if (current / "directives" / "BOOTSTRAP.md").exists():
        return current

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
    print("Expected structure: SpookyID_stack/backend/Cargo.toml")
    sys.exit(1)


def extract_code_endpoints(backend_dir: Path) -> Set[str]:
    """Extract all HTTP endpoints from Rust code."""
    endpoints = set()

    # Find all .rs files in backend/src/bin/
    bin_dir = backend_dir / "src" / "bin"
    if not bin_dir.exists():
        print(f"{Colors.YELLOW}Warning: {bin_dir} not found{Colors.NC}")
        return endpoints

    for rs_file in bin_dir.rglob("*.rs"):
        content = rs_file.read_text(encoding='utf-8')

        # Match .route("path", ...) patterns
        # Examples: .route("/api/oidc/token", ...), .route("/health", ...)
        matches = re.findall(r'\.route\(\s*"([^"]+)"', content)
        endpoints.update(matches)

    return endpoints


def extract_spec_endpoints(spec_file: Path) -> Set[str]:
    """Extract documented endpoints from SPEC.md."""
    if not spec_file.exists():
        print(f"{Colors.RED}Error: SPEC.md not found at {spec_file}{Colors.NC}")
        return set()

    content = spec_file.read_text(encoding='utf-8')
    endpoints = set()

    # Match HTTP method lines: GET /path, POST /path, etc.
    # Examples: "GET /api/oidc/token", "POST /api/anchor/register"
    matches = re.findall(r'^(?:GET|POST|PUT|DELETE|PATCH)\s+(\S+)', content, re.MULTILINE)
    endpoints.update(matches)

    return endpoints


def extract_code_rules(backend_dir: Path) -> Set[str]:
    """Extract all Rule R-* references from Rust code."""
    rules = set()

    for rs_file in backend_dir.rglob("*.rs"):
        content = rs_file.read_text(encoding='utf-8', errors='ignore')

        # Match "Rule R-XXX-NNN" patterns in comments and strings
        matches = re.findall(r'Rule (R-[A-Z]+-\d+)', content)
        rules.update(matches)

    return rules


def extract_defined_rules(rules_file: Path) -> Set[str]:
    """Extract all defined rules from RULES.md."""
    if not rules_file.exists():
        print(f"{Colors.YELLOW}Warning: RULES.md not found at {rules_file}{Colors.NC}")
        return set()

    content = rules_file.read_text(encoding='utf-8')
    rules = set()

    # Match "### Rule R-XXX-NNN" headers
    matches = re.findall(r'^###\s+Rule\s+(R-[A-Z]+-\d+)', content, re.MULTILINE)
    rules.update(matches)

    return rules


def extract_code_chains(backend_dir: Path) -> Set[int]:
    """Extract all Chain N references from Rust code."""
    chains = set()

    for rs_file in backend_dir.rglob("*.rs"):
        content = rs_file.read_text(encoding='utf-8', errors='ignore')

        # Match "Chain N" patterns (N = 1-9)
        matches = re.findall(r'Chain\s+([1-9])', content)
        chains.update(int(n) for n in matches)

    return chains


def check_chain_documented(chain_num: int, chains_file: Path) -> bool:
    """Check if a chain is documented in CHAINS.md."""
    if not chains_file.exists():
        return False

    content = chains_file.read_text(encoding='utf-8')

    # Look for "### Chain N:" header
    pattern = f"### Chain {chain_num}:"
    return pattern in content


def main():
    """Main verification logic."""
    print(f"{Colors.BLUE}{'=' * 60}{Colors.NC}")
    print(f"{Colors.BLUE}  SpookyID Documentation Verification{Colors.NC}")
    print(f"{Colors.BLUE}{'=' * 60}{Colors.NC}\n")

    issues_found = 0

    # Find project root
    root = find_project_root()
    backend_dir = root / "backend"
    spec_file = root / "SPEC.md"

    # Find directives (might be in multipass or parent)
    directives_dir = None
    for candidate in [root.parent / "multipass" / "directives", root / "directives"]:
        if candidate.exists():
            directives_dir = candidate
            break

    if not directives_dir:
        print(f"{Colors.YELLOW}Warning: Could not find directives folder{Colors.NC}")
        directives_dir = Path(".")

    rules_file = directives_dir / "RULES.md"
    chains_file = directives_dir / "CHAINS.md"

    # Check 1: SPEC.md endpoint accuracy
    print(f"{Colors.BLUE}[1/3]{Colors.NC} Checking SPEC.md endpoint accuracy...")

    code_endpoints = extract_code_endpoints(backend_dir)
    spec_endpoints = extract_spec_endpoints(spec_file)

    undocumented = code_endpoints - spec_endpoints

    if undocumented:
        print(f"{Colors.YELLOW}[WARN]{Colors.NC} Endpoints in code but not in SPEC.md:")
        for endpoint in sorted(undocumented):
            print(f"  - {endpoint}")
        issues_found += len(undocumented)
    else:
        print(f"{Colors.GREEN}[OK]{Colors.NC} All {len(code_endpoints)} endpoints documented in SPEC.md")

    print()

    # Check 2: RULES.md references
    print(f"{Colors.BLUE}[2/3]{Colors.NC} Checking RULES.md rule references...")

    code_rules = extract_code_rules(backend_dir)
    defined_rules = extract_defined_rules(rules_file)

    if code_rules:
        print(f"Found {len(code_rules)} rule references in code")

        undefined = code_rules - defined_rules
        if undefined:
            print(f"{Colors.YELLOW}[WARN]{Colors.NC} Rules referenced in code but not defined in RULES.md:")
            for rule in sorted(undefined):
                print(f"  - {rule}")
            issues_found += len(undefined)
        else:
            print(f"{Colors.GREEN}[OK]{Colors.NC} All {len(code_rules)} referenced rules are defined")
    else:
        print(f"{Colors.GREEN}[OK]{Colors.NC} No rule references found in code")

    print()

    # Check 3: CHAINS.md references
    print(f"{Colors.BLUE}[3/3]{Colors.NC} Checking CHAINS.md chain references...")

    code_chains = extract_code_chains(backend_dir)

    if code_chains:
        print(f"Found references to chains: {sorted(code_chains)}")

        undocumented_chains = []
        for chain in sorted(code_chains):
            if check_chain_documented(chain, chains_file):
                print(f"{Colors.GREEN}[OK]{Colors.NC} Chain {chain} documented")
            else:
                print(f"{Colors.YELLOW}[WARN]{Colors.NC} Chain {chain} referenced but not documented")
                undocumented_chains.append(chain)
                issues_found += 1
    else:
        print(f"{Colors.GREEN}[OK]{Colors.NC} No chain references found in code")

    print()

    # Summary
    print(f"{Colors.BLUE}{'=' * 60}{Colors.NC}")
    if issues_found == 0:
        print(f"{Colors.GREEN}[OK] Documentation is accurate (no issues found){Colors.NC}")
        return 0
    else:
        print(f"{Colors.YELLOW}[WARN] Found {issues_found} documentation accuracy issue(s){Colors.NC}")
        print("Please update relevant documentation files.")
        return 1


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] in ["--help", "-h"]:
        print(__doc__)
        sys.exit(0)

    sys.exit(main())
