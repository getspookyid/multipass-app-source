# SpookyID Deployment Guide

**Target Component**: Multipass (Mobile App)
**Environment**: Production / Release

## Prerequisites
- **Flutter SDK**: Stable channel (latest)
- **Rust Toolchain**: Stable (1.80+)
- **Android NDK**: Version 26.x+
- **JavaCard Tools**: GlobalPlatformPro (for applet loading)

## Build Instructions
### 1. Compile Rust Core
```bash
# Build UniFFI bindings and shared libraries
cd multipass
cargo build --release
```

### 2. Build Flutter Bundle
```bash
# Generate APK / AAB
flutter build apk --release --no-shrink
```

## Release Protocol (The "No Stubs" Rule)
> [!IMPORTANT]
> Production builds MUST NOT contain any mock implementations.

1.  **Audit**: Run `execution/audit_suite.py` to verify no `TODO`, `FIXME`, or mock paths exist.
2.  **Hardware Check**: Verify `AGENT-deploy.md` constraints (Periwinkle entropy, Hardware Attestation).
3.  **Signing**: Sign release artifact with production keys.

## Troubleshooting
[Common install/build issues]
