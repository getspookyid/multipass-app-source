#!/usr/bin/env python3
"""
bootstrap_context.py - SpookyID Context Verification

Purpose: Read BOOTSTRAP.md and verify all referenced files exist, check environment variables,
         verify critical binaries are built, and confirm system is ready to work.

Layer: 3 (Execution - Deterministic validation)
Compatible with: Antigravity architecture

Usage: python bootstrap_context.py
       python bootstrap_context.py --fix  # Attempt to fix issues
"""

import os
import sys
import subprocess
from pathlib import Path
from typing import List, Tuple

# Colors for terminal output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'


def check_command(command: str, min_version: str = None) -> bool:
    """Check if a command exists and optionally verify version."""
    try:
        result = subprocess.run(
            [command, "--version"],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            version_output = result.stdout.strip()
            print(f"{Colors.GREEN}[OK]{Colors.NC} {command}: {version_output.split()[0] if version_output else 'installed'}")
            return True
        else:
            print(f"{Colors.RED}[FAIL]{Colors.NC} {command}: not found")
            return False
    except FileNotFoundError:
        print(f"{Colors.RED}[FAIL]{Colors.NC} {command}: not found")
        return False
    except Exception as e:
        print(f"{Colors.YELLOW}[WARN]{Colors.NC} {command}: error checking version ({e})")
        return False


def find_project_root() -> Path:
    """Find the SpookyID project root directory."""
    current = Path.cwd()

    # Try multipass directives location
    if (current / "directives" / "BOOTSTRAP.md").exists():
        return current.parent if (current.parent / "SpookyID_stack").exists() else current

    # Try SpookyID_stack location
    if (current / "backend" / "Cargo.toml").exists():
        return current

    # Search upward
    for parent in current.parents:
        if (parent / "SpookyID_stack" / "backend" / "Cargo.toml").exists():
            return parent
        if (parent / "backend" / "Cargo.toml").exists():
            return parent

    return current  # Fall back to current directory


def check_critical_files(root: Path) -> Tuple[List[str], List[str]]:
    """Check existence of critical files mentioned in BOOTSTRAP.md."""
    found = []
    missing = []

    critical_files = [
        ("multipass/directives/BOOTSTRAP.md", "Bootstrap protocol"),
        ("multipass/directives/CHAINS.md", "9-Chain specification"),
        ("multipass/directives/RULES.md", "Security/business rules"),
        ("multipass/directives/AGENTS.md", "Agent taxonomy"),
        ("multipass/directives/progress.md", "Phase tracking"),
        ("SpookyID_stack/SPEC.md", "System architecture"),
        ("SpookyID_stack/backend/Cargo.toml", "Backend manifest"),
        ("SpookyID_stack/scripts/bootstrap.sh", "Bootstrap script"),
        ("SpookyID_stack/scripts/test.sh", "Test suite"),
        ("multipass/.claude/settings.json", "Claude Code config"),
    ]

    for rel_path, description in critical_files:
        full_path = root / rel_path
        if full_path.exists():
            found.append(f"{description}: {rel_path}")
        else:
            missing.append(f"{description}: {rel_path}")

    return found, missing


def check_environment_variables() -> Tuple[List[str], List[str]]:
    """Check critical environment variables from .env."""
    found = []
    missing = []

    critical_vars = [
        ("DATABASE_URL", "PostgreSQL connection string"),
        ("SPOOKY_ISSUER", "Issuer URL"),
        ("SPOOKY_JWT_SECRET", "JWT signing secret"),
        ("SPOOKY_PEPPER", "Password pepper salt"),
    ]

    for var_name, description in critical_vars:
        value = os.environ.get(var_name)
        if value:
            # Mask sensitive values
            if "SECRET" in var_name or "PEPPER" in var_name or "PASSWORD" in var_name:
                masked = value[:8] + "..." if len(value) > 8 else "***"
                found.append(f"{var_name}={masked}")
            else:
                found.append(f"{var_name}={value}")
        else:
            missing.append(f"{var_name} ({description})")

    return found, missing


def check_built_binaries(root: Path) -> Tuple[List[str], List[str]]:
    """Check if critical binaries have been built."""
    found = []
    missing = []

    binaries = [
        ("SpookyID_stack/backend/target/release/oidc_service", "OIDC backend service"),
        ("SpookyID_stack/backend/target/debug/oidc_service", "OIDC backend service (debug)"),
    ]

    for rel_path, description in binaries:
        full_path = root / rel_path
        if full_path.exists():
            size = full_path.stat().st_size / (1024 * 1024)  # MB
            found.append(f"{description}: {rel_path} ({size:.1f} MB)")
            break  # Only need one
    else:
        missing.append(f"OIDC service binary (run: cd backend && cargo build --release)")

    return found, missing


def main():
    """Main verification logic."""
    fix_mode = "--fix" in sys.argv

    print(f"{Colors.BLUE}{'=' * 60}{Colors.NC}")
    print(f"{Colors.BLUE}  SpookyID Context Verification{Colors.NC}")
    print(f"{Colors.BLUE}{'=' * 60}{Colors.NC}\n")

    issues_found = 0

    # Check 1: Prerequisites
    print(f"{Colors.BLUE}[1/5]{Colors.NC} Checking prerequisites...\n")

    prereqs = [
        ("cargo", "Rust toolchain"),
        ("node", "Node.js runtime"),
        ("python3", "Python 3"),
    ]

    prereq_ok = True
    for command, description in prereqs:
        if not check_command(command):
            prereq_ok = False
            issues_found += 1

    # Optional tools
    check_command("docker")

    if not prereq_ok:
        print(f"\n{Colors.RED}[FAIL] Missing required prerequisites{Colors.NC}")
        print("Install missing tools before continuing.")
        return 1

    print()

    # Check 2: Project structure
    print(f"{Colors.BLUE}[2/5]{Colors.NC} Verifying project structure...\n")

    root = find_project_root()
    print(f"Project root: {root}\n")

    found_files, missing_files = check_critical_files(root)

    for file_desc in found_files:
        print(f"{Colors.GREEN}[OK]{Colors.NC} {file_desc}")

    if missing_files:
        for file_desc in missing_files:
            print(f"{Colors.RED}[FAIL]{Colors.NC} Missing: {file_desc}")
            issues_found += 1

    print()

    # Check 3: Environment variables
    print(f"{Colors.BLUE}[3/5]{Colors.NC} Checking environment variables...\n")

    found_vars, missing_vars = check_environment_variables()

    for var_desc in found_vars:
        print(f"{Colors.GREEN}[OK]{Colors.NC} {var_desc}")

    if missing_vars:
        for var_desc in missing_vars:
            print(f"{Colors.YELLOW}[WARN]{Colors.NC} Not set: {var_desc}")

        print(f"\n{Colors.YELLOW}Tip:{Colors.NC} Create .env file or set environment variables")
        print("Example: export DATABASE_URL=postgresql://postgres:password@localhost:5432/spookyid")

    print()

    # Check 4: Built binaries
    print(f"{Colors.BLUE}[4/5]{Colors.NC} Checking built binaries...\n")

    found_bins, missing_bins = check_built_binaries(root)

    for bin_desc in found_bins:
        print(f"{Colors.GREEN}[OK]{Colors.NC} {bin_desc}")

    if missing_bins:
        for bin_desc in missing_bins:
            print(f"{Colors.YELLOW}[WARN]{Colors.NC} {bin_desc}")

        if fix_mode:
            print(f"\n{Colors.BLUE}Attempting to build backend...{Colors.NC}")
            try:
                subprocess.run(
                    ["cargo", "build", "--release", "--bin", "oidc_service"],
                    cwd=root / "SpookyID_stack" / "backend",
                    check=True
                )
                print(f"{Colors.GREEN}[OK]{Colors.NC} Backend built successfully")
            except subprocess.CalledProcessError:
                print(f"{Colors.RED}[FAIL]{Colors.NC} Build failed")
                issues_found += 1

    print()

    # Check 5: Documentation sync
    print(f"{Colors.BLUE}[5/5]{Colors.NC} Checking documentation sync...\n")

    # Run verify_documentation.py if it exists
    verify_script = root / "multipass" / "directives" / "execution" / "verify_documentation.py"
    if verify_script.exists():
        try:
            result = subprocess.run(
                ["python3", str(verify_script)],
                capture_output=True,
                text=True,
                timeout=30
            )
            if result.returncode == 0:
                print(f"{Colors.GREEN}[OK]{Colors.NC} Documentation is in sync")
            else:
                print(f"{Colors.YELLOW}[WARN]{Colors.NC} Documentation discrepancies found (see verify_documentation.py)")
        except Exception as e:
            print(f"{Colors.YELLOW}[WARN]{Colors.NC} Could not run verify_documentation.py: {e}")
    else:
        print(f"{Colors.YELLOW}[WARN]{Colors.NC} verify_documentation.py not found (skipping)")

    print()

    # Summary
    print(f"{Colors.BLUE}{'=' * 60}{Colors.NC}")
    if issues_found == 0 and not missing_vars:
        print(f"{Colors.GREEN}[OK] System is ready to work{Colors.NC}")
        print("\nYou can now:")
        print("  - Start backend: cd SpookyID_stack/backend && cargo run --bin oidc_service")
        print("  - Run tests: cd SpookyID_stack && ./scripts/test.sh")
        print("  - Read directives: multipass/directives/BOOTSTRAP.md")
        return 0
    else:
        print(f"{Colors.YELLOW}[WARN] Found {issues_found} critical issue(s){Colors.NC}")
        if missing_vars:
            print(f"{Colors.YELLOW}[WARN] Some environment variables are not set{Colors.NC}")
        print("\nResolve issues before continuing. Run with --fix to attempt automatic fixes.")
        return 1


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] in ["--help", "-h"]:
        print(__doc__)
        sys.exit(0)

    sys.exit(main())
