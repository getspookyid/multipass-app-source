import subprocess
import os
import sys

# Absolute path to Flutter (found in environment)
FLUTTER_BIN = r"C:\flutter\bin\flutter.bat"

def run_flutter(args):
    """Runs flutter with the given arguments."""
    if not os.path.exists(FLUTTER_BIN):
        print(f"❌ Flutter binary not found at {FLUTTER_BIN}")
        sys.exit(1)
        
    cmd = [FLUTTER_BIN] + args
    print(f"[*] Running: {' '.join(cmd)}")
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        print(f"[-] Command failed with exit code {e.returncode}")
        sys.exit(e.returncode)

def main():
    if len(sys.argv) < 2:
        print("Usage: python build.py [run|build]")
        sys.exit(1)
        
    action = sys.argv[1]
    
    if action == "run":
        print("[*] Launching App...")
        run_flutter(["run"])
    elif action == "build":
        print("[*] Building APK...")
        run_flutter(["build", "apk", "--debug"])
    else:
        print(f"Unknown action: {action}")

if __name__ == "__main__":
    main()
