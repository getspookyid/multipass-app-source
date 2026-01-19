import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'diagnostic_manager.dart';

class StrongboxManager {
  static const MethodChannel _channel =
      MethodChannel('io.getspooky.multipass/strongbox');

  Future<bool> isStrongBoxAvailable() async {
    if (diagnosticManager.isDiagnosticMode) return true;
    try {
      final bool result = await _channel.invokeMethod('isStrongBoxAvailable');
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to check StrongBox: '${e.message}'.");
      return false;
    }
  }

  Future<bool> generateKey(String alias) async {
    if (diagnosticManager.isDiagnosticMode) return true;
    try {
      final bool result =
          await _channel.invokeMethod('generateKey', {'alias': alias});
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to generate key: '${e.message}'.");
      return false;
    }
  }

  Future<List<String>> getAttestation(String alias) async {
    if (diagnosticManager.isDiagnosticMode) return ["MOCK_ATTESTATION_CHAIN"];
    try {
      final List<dynamic> result =
          await _channel.invokeMethod('getAttestation', {'alias': alias});
      return result.cast<String>();
    } on PlatformException catch (e) {
      debugPrint("Failed to get attestation: '${e.message}'.");
      return [];
    }
  }

  Future<Uint8List?> sign(String alias, Uint8List data) async {
    if (diagnosticManager.isDiagnosticMode) {
      debugPrint('👻 Ghost Mode: Mocking Strongbox signature.');
      // Return a 64-byte mock ECDSA signature (R + S)
      return Uint8List(64);
    }
    try {
      final Uint8List? result = await _channel.invokeMethod('sign', {
        'alias': alias,
        'data': data,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to sign data: '${e.message}'.");
      return null;
    }
  }

  Future<bool> generateSymKey(String alias) async {
    if (diagnosticManager.isDiagnosticMode) return true;
    try {
      final bool result =
          await _channel.invokeMethod('generateSymKey', {'alias': alias});
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to generate symmetric key: '${e.message}'.");
      return false;
    }
  }

  Future<Map<String, String>?> encryptSym(String alias, String data) async {
    if (diagnosticManager.isDiagnosticMode) {
      // Mock encryption
      return {
        'encryptedData': base64Encode(utf8.encode(data)),
        'iv': 'MOCK_IV',
      };
    }
    try {
      final Map<dynamic, dynamic> result =
          await _channel.invokeMethod('encryptSym', {
        'alias': alias,
        'data': data,
      });
      return result.cast<String, String>();
    } on PlatformException catch (e) {
      debugPrint("Failed to encrypt data: '${e.message}'.");
      return null;
    }
  }

  Future<String?> decryptSym(
    String alias,
    String encryptedData,
    String iv,
  ) async {
    if (diagnosticManager.isDiagnosticMode) {
      // Mock decryption
      return utf8.decode(base64Decode(encryptedData));
    }
    try {
      final String? result = await _channel.invokeMethod('decryptSym', {
        'alias': alias,
        'encryptedData': encryptedData,
        'iv': iv,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to decrypt data: '${e.message}'.");
      return null;
    }
  }

  Future<bool> checkAttestation(String alias) async {
    if (diagnosticManager.isDiagnosticMode) {
      debugPrint('👻 Ghost Mode: Mocking Attestation Check.');
      return true;
    }
    try {
      final bool result =
          await _channel.invokeMethod('checkAttestation', {'alias': alias});
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to check attestation: '${e.message}'.");
      return false; // Fail-Closed
    }
  }

  Future<Uint8List> getEntropy(int size) async {
    if (diagnosticManager.isDiagnosticMode) {
      // Return deterministic mock entropy for testing
      return Uint8List.fromList(List.filled(size, 0x42));
    }
    try {
      final Uint8List? result =
          await _channel.invokeMethod('getEntropy', {'size': size});
      if (result == null) {
        throw PlatformException(
            code: "NULL_ENTROPY", message: "Received null entropy");
      }
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to get entropy: '${e.message}'.");
      // Critical failure - cannot proceed without entropy
      rethrow;
    }
  }
}
