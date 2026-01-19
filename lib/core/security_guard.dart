import 'package:flutter/foundation.dart';
import 'strongbox_manager.dart';

/// SecurityGuard handles anti-tamper, root detection, and
/// hardware attestation state.
class SecurityGuard extends ChangeNotifier {
  static final SecurityGuard _instance = SecurityGuard._internal();
  factory SecurityGuard() => _instance;
  SecurityGuard._internal();

  bool _isCompromised = false;
  final StrongboxManager _strongbox = StrongboxManager();
  static const String _attestationTarget = 'spooky_identity';

  /// Returns true if the device environment is deemed unsafe
  /// (e.g., rooted, hooked, or debugger attached).
  bool get isCompromised => _isCompromised;

  /// Triggers a lockdown state if a security threat is detected.
  void notifyCompromise() {
    if (_isCompromised) return; // Already in lockdown

    _isCompromised = true;
    // Log for diagnostic purposes (Chain 7)
    debugPrint("SECURITY_ALERT: Device environment compromised.");
    notifyListeners();
  }

  /// Resets the guard state (Use only for authorized debug bypass)
  void resetGuard() {
    _isCompromised = false;
    notifyListeners();
  }

  /// Enforces "Fail-Closed" security policy on application startup.
  Future<void> verifyDeviceIntegrity() async {
    debugPrint('🛡️ Initiating Security Guard Integrity Check...');

    // 1. Check if StrongBox is available (Hardware Root of Trust)
    final bool hasStrongBox = await _strongbox.isStrongBoxAvailable();
    if (!hasStrongBox) {
      debugPrint('⚠️ WARNING: StrongBox HSM not available.');
      notifyCompromise();
      // In strict mode, we might throw exception here, but for now we just flag compromise.
    }

    // 2. Check Key Attestation
    // Ensures the keys are actually in the hardware and the OS is not rooted/compromised.
    final bool isAttested =
        await _strongbox.checkAttestation(_attestationTarget);
    if (!isAttested) {
      debugPrint('🚨 CRITICAL: Key Attestation Failed.');
      notifyCompromise();
    }

    if (!_isCompromised) {
      debugPrint('✅ Security Guard: Device Integrity Verified.');
    }
  }
}
