import 'package:flutter/foundation.dart';
import 'strongbox_manager.dart';

class SecurityViolationException implements Exception {
  final String message;
  SecurityViolationException(this.message);
  @override
  String toString() => 'SecurityViolationException: $message';
}

/// Enforces "Fail-Closed" security policy on application startup.
/// Checks hardware backing and key attestation.
class SecurityGuard {
  final StrongboxManager _strongbox = StrongboxManager();

  // The alias used for the core identity or storage key we want to attest.
  static const String _attestationTarget = 'spooky_identity';

  Future<void> verifyDeviceIntegrity() async {
    debugPrint('🛡️ Initiating Security Guard Integrity Check...');

    // 1. Check if StrongBox is available (Hardware Root of Trust)
    // Note: StrongboxManager.isStrongBoxAvailable() wraps the native check.
    final bool hasStrongBox = await _strongbox.isStrongBoxAvailable();

    if (!hasStrongBox) {
      // In strict production, this might be a violation.
      // For now, we log a critical warning but might allow TEE if policy permits.
      // However, per "Phase 10 Fail-Closed", we should be strict.
      debugPrint(
          '⚠️ WARNING: StrongBox HSM not available. Operating in TEE/Software mode.');
      // throw SecurityViolationException("Device lacks StrongBox Hardware Security Module.");
      // Note: Allowing TEE fallback for broad compatibility unless strictly Phase 10 violation.
      // User requirement says: "If the device is not backed by hardware... app must refuse".
      // Let's enforce it strictly for the task.
      throw SecurityViolationException(
          "Hardware Root of Trust (StrongBox) Missing.");
    }

    // 2. Check Key Attestation
    // Ensures the keys are actually in the hardware and the OS is not rooted/compromised.
    final bool isAttested =
        await _strongbox.checkAttestation(_attestationTarget);

    if (!isAttested) {
      debugPrint('🚨 CRITICAL: Key Attestation Failed.');
      throw SecurityViolationException(
          "Device Integrity Validation Failed (Attestation Rejection).");
    }

    debugPrint('✅ Security Guard: Device Integrity Verified.');
  }
}
