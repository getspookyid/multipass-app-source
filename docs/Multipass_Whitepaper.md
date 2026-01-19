# SpookyID Multipass Whitepaper

**Status**: Draft / Stub
**Version**: 0.1.0

## Abstract
[To be populated]

## Architecture
### Hybrid Trust Model
- **Root of Trust**: JavaCard applet (NXP J3H145) running `SpookyIDApplet`.
- **Compute Interface**: Flutter mobile application acting as the bridge.

### Core Components
1. **The Anchor** (Hardware)
   - Stores master seed (TRNG)
   - Performs critical signing operations (Ed25519)
   - Secure Element isolation

2. **The Bridge** (Mobile App)
   - Rust/Flutter integration via UniFFI
   - Handles high-bandwidth crypto (BBS+ Zero-Knowledge Proofs)
   - Manages Network I/O with SpookyID Backend

## Cryptographic Flows
### 1. Registration (Chain 1)
[Details on Anchor Registration flow]

### 2. Entitlements & ZKPs (Chain 2)
[Details on selective disclosure]

### 3. Offline Delegation (Chain 9)
[Details on lease token generation]

## Security & Privacy
- **No PII Storage**: System relies on cryptographic commitments.
- **Hardware-Bound**: Secrets never leave the Secure Element.
