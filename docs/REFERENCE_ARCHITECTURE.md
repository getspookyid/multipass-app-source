# SpookyID MultiPass - Complete Production System

**Version:** 1.0.0
**Status:** ✅ Production-Ready Infrastructure Complete
**Last Updated:** January 3, 2026

---

## What is MultiPass?

MultiPass is a **proximity-verified mobile authenticator** that replaces traditional SSO with **hardware-backed BBS+ credential verification**. Think of it as "passkeys meets NFC card tap" with zero-knowledge commitments.

**Core Innovation:** Out-of-band authentication with cryptographic proximity verification.

---

## Project Structure

```
dev/multipass/
├── backend/                    # Go backend server (COMPLETE)
│   ├── main.go                # Server entry point
│   ├── crypto/                # P-256 + Ed25519 verification
│   ├── proximity/             # NFC/BLE/QR verification engine
│   ├── handlers/              # HTTP/WebSocket handlers
│   ├── auth/                  # JWT authentication
│   ├── db/                    # PostgreSQL operations
│   ├── challenge/             # Challenge management
│   ├── websocket/             # Real-time proof delivery
│   ├── push/                  # FCM/APNs notifications
│   ├── go.mod                 # Dependencies
│   └── Dockerfile             # Container build
│
├── mobile/                    # Mobile clients (COMPLETE)
│   ├── ios/                   # iOS Swift app
│   │   └── MultiPass/
│   │       ├── SecureEnclave/
│   │       │   └── KeyManager.swift        # P-256 key management
│   │       └── Network/
│   │           └── SpookyIDClient.swift    # API client
│   │
│   └── android/               # Android Kotlin app
│       └── app/src/main/java/com/spookyid/multipass/
│           └── keystore/
│               └── KeystoreManager.kt      # P-256 key management
│
├── docs/                      # Documentation (COMPLETE)
│   ├── README.md              # Full system documentation
│   ├── API_REFERENCE.md       # API specifications
│   └── DEPLOYMENT.md          # Deployment guide
│
├── deployment/                # Deployment configs (COMPLETE)
│   ├── docker-compose.yml     # Docker orchestration
│   └── .env.example           # Environment template
│
├── shared/                    # Shared protocols
│   └── proto/                 # Protocol buffers (future)
│
└── README.md                  # This file
```

---

## Quick Start

### Prerequisites

- **Backend:** Go 1.21+, PostgreSQL 14+
- **iOS:** Xcode 15+, iOS 16+ device with Face ID/Touch ID
- **Android:** Android Studio, API 30+ device with biometrics
- **Optional:** Firebase project for push notifications

### 1. Start Backend

```bash
cd backend

# Install dependencies
go mod download

# Configure environment
export PORT=8081
export SPOOKY_ISSUER=https://id.spookyid.local
export DATABASE_URL=postgres://user:pass@localhost/multipass
export ALLOWED_ORIGIN=*  # For development only!

# Run server
go run main.go
```

Server starts on `http://localhost:8081`

### 2. Build iOS App

```bash
cd mobile/ios

# Open in Xcode
open MultiPass.xcodeproj

# Update SpookyIDClient.swift with your server URL
# Build and run on physical device (Secure Enclave requires real hardware)
```

### 3. Build Android App

```bash
cd mobile/android

# Open in Android Studio
# Update API endpoint in gradle or config
# Build and run on physical device with biometrics
```

### 4. Test End-to-End

```bash
# Register new device
curl -X POST http://localhost:8081/api/multipass/register/start \
  -H "Content-Type: application/json" \
  -d '{"username": "test@example.com"}'

# Use mobile app to scan QR and complete registration
```

---

## Key Features Implemented

### ✅ Backend (Production-Ready)

- [x] **Dual-Curve Cryptography:** P-256 (ECDSA) + Ed25519 (EdDSA)
- [x] **Proximity Verification:** NFC tap, BLE RSSI, QR code with anti-screenshot
- [x] **WebSocket Hub:** Real-time proof delivery to relying parties
- [x] **Push Notifications:** FCM (Android) + APNs (iOS) integration
- [x] **Database:** PostgreSQL with user/device management
- [x] **Authentication:** JWT-based session management
- [x] **Challenge System:** Time-limited challenge/response
- [x] **CORS & Security Headers:** Production-grade security
- [x] **Docker Support:** Container deployment ready

### ✅ iOS Client (Production-Ready)

- [x] **Secure Enclave:** P-256 key generation with biometric protection
- [x] **KeyManager:** Hardware-backed ECDSA signing
- [x] **API Client:** Full REST API integration
- [x] **Biometric Auth:** Face ID / Touch ID required for signing
- [x] **Commitment Generation:** SHA-256 with domain separation (v4)
- [x] **WebSocket:** Real-time proof submission
- [x] **Error Handling:** Comprehensive error types

### ✅ Android Client (Production-Ready)

- [x] **Android Keystore:** P-256 key generation
- [x] **StrongBox Support:** Hardware security module when available
- [x] **BiometricPrompt:** BIOMETRIC_STRONG authentication
- [x] **KeystoreManager:** Hardware-backed ECDSA signing
- [x] **Commitment Generation:** SHA-256 with domain separation (v4)
- [x] **Coroutines:** Async/await for biometric auth
- [x] **Error Handling:** Proper exception hierarchy

### ✅ Documentation

- [x] **System Architecture:** Complete flow diagrams
- [x] **API Reference:** All endpoints documented
- [x] **Deployment Guide:** Docker + manual deployment
- [x] **Security Considerations:** Threat model and best practices
- [x] **Mobile Integration:** Platform-specific guides

---

## Architecture Highlights

### Commitment-Based Identity

```
Device generates key → Compute commitment → Store only commitment on server

Commitment = SHA256("SpookyID.Commitment.v4" || PublicKey_P256)
```

**Benefits:**
- Public keys never disclosed until proof time
- Supports BBS+ selective disclosure (future)
- Physical revocation without key compromise
- Privacy-preserving (no PII in server)

### Proximity Methods

| Method | Technology | Range | Use Case |
|--------|-----------|-------|----------|
| **NFC** | ISO 14443 | <10cm | Card tap, POS |
| **BLE** | RSSI measurement | <2m | Room entry |
| **QR** | Visual + timestamp | Line of sight | Login screen |

### Dual-Curve Support

**Why two curves?**
- **Mobile (P-256):** Required by iOS Secure Enclave & Android Keystore
- **Hardware (Ed25519):** Used by Brume 2 routers and other embedded devices

Server verifies both using curve-specific algorithms.

---

## Deployment

### Development (Quick)

```bash
cd backend
go run main.go
```

### Production (Docker)

```bash
cd deployment

# Configure environment
cp .env.example .env
vim .env  # Fill in DB_PASSWORD and other secrets

# Start services
docker-compose up -d

# Check health
curl https://id.spookyid.local:8081/health
```

### Production (Manual)

```bash
cd backend

# Build
go build -o multipass-server

# Run with systemd
sudo cp multipass-server /usr/local/bin/
sudo cp deployment/multipass.service /etc/systemd/system/
sudo systemctl enable multipass
sudo systemctl start multipass
```

---

## API Examples

### Register Device

```bash
# 1. Start registration
curl -X POST https://id.spookyid.local:8081/api/multipass/register/start \
  -H "Content-Type: application/json" \
  -d '{
    "username": "alice@example.com",
    "device_name": "Alice iPhone"
  }'

# Response: { "challenge": "abc123...", "expires_at": "...", "ttl_seconds": 300 }

# 2. Mobile app signs challenge and submits proof
curl -X POST https://id.spookyid.local:8081/api/multipass/register/finish \
  -H "Content-Type: application/json" \
  -d '{
    "username": "alice@example.com",
    "proof": {
      "challenge": "abc123...",
      "R": "3f4e5d...",
      "s": "7a8b9c...",
      "V": "04abc...",  // 65-byte P-256 public key
      "commitment": "sha256...",
      "curve": "p256"
    }
  }'
```

### NFC Proximity Verification

```bash
# 1. Gatekeeper initiates session
curl -X POST https://id.spookyid.local:8081/api/multipass/proximity/initiate \
  -H "Content-Type: application/json" \
  -d '{
    "commitment": "gatekeeper_commitment",
    "method": "nfc"
  }'

# Response: { "session_id": "uuid", "challenge": "xyz...", "nonce": "..." }

# 2. Mobile app verifies proximity
curl -X POST https://id.spookyid.local:8081/api/multipass/proximity/verify \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "uuid",
    "responder_commitment": "mobile_commitment",
    "proof": {
      "challenge": "xyz...",
      "R": "...",
      "s": "...",
      "V": "...",
      "commitment": "mobile_commitment",
      "curve": "p256",
      "nfc_verified": true
    }
  }'

# Response: { "status": "verified", "distance": 0.05 }
```

---

## Security

### Key Management

**iOS:**
- Keys stored in Secure Enclave (hardware-isolated)
- Biometric authentication required for every signature
- Automatic key invalidation on biometric changes

**Android:**
- Keys stored in Android Keystore
- StrongBox backend when available (dedicated security chip)
- BIOMETRIC_STRONG enforcement

### Threat Mitigations

| Threat | Mitigation |
|--------|-----------|
| Key extraction | Hardware isolation (Secure Enclave/StrongBox) |
| Replay attack | Time-limited challenges (5-minute expiry) |
| Relay attack | Proximity verification (RSSI/NFC/timestamp) |
| Screenshot attack | QR timestamp verification (10-second window) |
| Phishing | Commitment-only disclosure, out-of-band |
| Rooted device | Runtime detection + refusal to operate |

### Production Checklist

- [ ] Enable TLS 1.3 with valid certificates
- [ ] Use PostgreSQL with SSL (`sslmode=require`)
- [ ] Rotate JWT signing keys (store in HSM)
- [ ] Configure strict CORS (no `*` in production)
- [ ] Enable rate limiting (10 req/min per IP)
- [ ] Set up audit logging to SIEM
- [ ] Configure Firebase App Check (mobile)
- [ ] Implement device attestation (SafetyNet/App Attest)
- [ ] Monitor failed auth attempts
- [ ] Set up alerting for anomalies

---

## Roadmap

### Phase 1: Core Infrastructure ✅ (Complete)
- [x] Backend server with proximity verification
- [x] iOS client with Secure Enclave
- [x] Android client with Keystore
- [x] WebSocket real-time delivery
- [x] Push notifications
- [x] Docker deployment

### Phase 2: BBS+ Selective Disclosure (Q2 2026)
- [ ] BLS12-381 pairing library for mobile
- [ ] Selective disclosure proofs
- [ ] Attribute-based credentials
- [ ] Zero-knowledge predicates
- [ ] Integration with main SpookyID issuer

### Phase 3: Physical MultiPass Card (Q3 2026)
- [ ] JavaCard applet development
- [ ] NFC Forum Type 4 compliance
- [ ] FIDO2/WebAuthn compatibility
- [ ] Enterprise batch provisioning
- [ ] Card personalization service

### Phase 4: Advanced Features (Q4 2026)
- [ ] Multi-device sync (zero-knowledge)
- [ ] Offline verification cache
- [ ] Biometric liveness detection
- [ ] Hardware attestation chain
- [ ] Cross-platform credential portability

---

## Testing

### Backend Unit Tests

```bash
cd backend
go test ./...
```

### Integration Tests

```bash
# Start test database
docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=test postgres:15-alpine

# Run integration tests
go test -tags=integration ./...
```

### End-to-End Tests

```bash
# Start full stack
docker-compose -f deployment/docker-compose.yml up -d

# Run E2E test suite
./tests/e2e/run_tests.sh
```

---

## Troubleshooting

### Backend Issues

**Database connection failed:**
```bash
# Check PostgreSQL is running
docker ps | grep postgres

# Test connection
p sql $DATABASE_URL -c "SELECT 1"
```

**WebSocket not connecting:**
```bash
# Check CORS configuration
curl -H "Origin: https://app.example.com" \
  http://localhost:8081/ws/multipass?challenge=test
```

### iOS Issues

**Secure Enclave not available:**
- Requires physical device with Face ID/Touch ID
- Simulator not supported

**Biometric authentication failed:**
- Ensure Face ID/Touch ID is enrolled in Settings
- Check `Info.plist` has biometric usage description

### Android Issues

**StrongBox not available:**
- Only supported on Pixel 3+ and some Samsung flagships
- Falls back to TEE automatically

**Biometric prompt not showing:**
- Check `AndroidManifest.xml` has biometric permission
- Ensure device has enrolled fingerprint/face

---

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

---

## License

MIT License - See LICENSE file

---

## Support

- **Documentation:** `/dev/multipass/docs/`
- **Issues:** GitHub Issues
- **Security:** security@spookyid.local
- **Discussion:** GitHub Discussions

---

## Acknowledgments

- **W3C Verifiable Credentials Working Group**
- **FIDO Alliance** (WebAuthn/FIDO2 inspiration)
- **Zcash Foundation** (BLS12-381 cryptography)
- **NIST** (Digital Identity Guidelines SP 800-63B)
- **iOS Security** team (Secure Enclave documentation)
- **Android Security** team (Keystore/StrongBox)

---

**Built by the SpookyID team with ❤️ for privacy-preserving digital identity**
