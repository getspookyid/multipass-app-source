import subprocess
import os
import sys

# Absolute path to Flutter (found in environment)
FLUTTER_BIN = r"C:\flutter\bin\flutter.bat"

def main():
    if not os.path.exists(FLUTTER_BIN):
        print(f"❌ Flutter binary not found at {FLUTTER_BIN}")
        sys.exit(1)
        
    print("🚀 Launching SpookyID Multipass (Python Wrapper)...")
    cmd = [FLUTTER_BIN, "run"]
    
    try:
        # User requested this because PowerShell was flaky.
        # This simply delegates to the absolute path of flutter.bat
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        print(f"❌ Launch failed: {e}")
        # Remind about Dev Mode
        print("\n⚠️  NOTE: If this failed with 'symlink' errors, enable Windows Developer Mode.")
        sys.exit(e.returncode)

if __name__ == "__main__":
    main()
