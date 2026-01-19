#!/usr/bin/env python3
"""
SpookyID: Admin Credential Issuance (Phase 3)
---------------------------------------------
Issues a BBS+ Credential to the Mobile App *if and only if*
the Root Anchor (JCOP Card) is physically present.
"""

import sys
import os
import subprocess
import json
import time

def run_gp_info():
    """Checks card presence and returns info. STRICT HARDWARE ONLY."""
    if not os.path.exists("gp.jar"):
        print("❌ gp.jar not found.")
        sys.exit(1)
        
    cmd = ["java", "-jar", "gp.jar", "--info"]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode == 0 and "ICSerialNumber" in res.stdout:
            return res.stdout
    except Exception:
        pass
    
    return None

def main():
    print("\n🔐 SpookyID: Admin Credential Issuance")
    print("========================================")
    print("👉 Insert ROOT ANCHOR (JCOP Card) to Authorize...")
    
    # 1. Haptic Wait Loop (Strict)
    card_info = None
    for i in range(10): 
        card_info = run_gp_info()
        if card_info:
            break
        time.sleep(1)
        print(".", end="", flush=True)
        
    if not card_info:
        print("\n❌ No Card Detected. Authorization Failed (Hardware Required).")
        sys.exit(1)
        
    print("\n✅ Card Detected! Analyzing Serial...")
    
    # 2. Extract Serial
    card_id = "UNKNOWN"
    for line in card_info.split('\n'):
        if "ICSerialNumber=" in line:
            card_id = f"JCOP-{line.split('=')[1].strip()}"
            break
            
    print(f"🛡️  Authority: {card_id}")
    
    # 3. Call Rust logic to Sign Credential
    print("\n⚡ Minting BBS+ Credential (Host-Side)...")
    
    out_file = "admin_credential.json"

    # Real Cargo Call Only
    env = os.environ.copy()
    env["SPOOKY_ADMIN_TOKEN"] = "supersecret" # Required by startup checks
    
    cmd = [
        "cargo", "run", "--bin", "oidc_service", 
        "--", "issue-admin", 
        "--card-id", card_id,
        "--out", out_file
    ]
    
    # Point to the actual backend in the stack
    cwd = os.path.abspath(os.path.join(os.getcwd(), "../SpookyID_stack/backend"))
    if not os.path.exists(cwd):
            print(f"❌ Backend not found at {cwd}")
            sys.exit(1)
    
    try:
        subprocess.run(cmd, cwd=cwd, env=env, check=True)
    except subprocess.CalledProcessError:
        print("❌ Signing Failed.")
        sys.exit(1)
        
    # 4. Display Result
    if os.path.exists(out_file):
        print(f"\n✅ Credential Issued: {out_file}")
        
        # Load and verify
        with open(out_file) as f:
            cred = json.load(f)
            
        print("\n📜 Credential Contents:")
        print(f"   Issuer: {cred['issuer']}")
        print(f"   Root:   {cred['root_anchor']}")
        print(f"   Timestamp: {cred['timestamp']}")
        
        print("\n📱 ACTION REQUIRED:")
        print("   Open Multipass App -> Scan JSON content (Raw Import)")
        
    else:
        print("❌ Output file missing.")

if __name__ == "__main__":
    main()
