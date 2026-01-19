import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/credential.dart';
import '../../core/strongbox_manager.dart';

/// Encrypted credential storage using flutter_secure_storage
/// COMPLIANCE UPDATE: Credentials are now Encrypted-at-Rest using StrongBox (AES-256 GCM)
/// The encryption key "credential_store_key" never leaves the hardware security module.
class CredentialStorage {
  static const _storageKey = 'spooky_credentials_v1';
  static const _symKeyAlias = 'credential_store_key';

  final FlutterSecureStorage _storage;
  final StrongboxManager _strongbox = StrongboxManager();

  CredentialStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Get all stored credentials
  Future<List<Credential>> getAll() async {
    try {
      final encryptedData = await _storage.read(key: _storageKey);
      if (encryptedData == null || encryptedData.isEmpty) {
        return [];
      }

      // Format: IV:CIPHERTEXT
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        debugPrint('⚠️ Invalid credential storage format. Cleared.');
        return [];
      }

      final iv = parts[0];
      final ciphertext = parts[1];

      final decryptedJson =
          await _strongbox.decryptSym(_symKeyAlias, ciphertext, iv);
      if (decryptedJson == null) {
        debugPrint('❌ StrongBox Decryption Failed. Data inaccessible.');
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(decryptedJson);
      return jsonList.map((json) => Credential.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Failed to load credentials: $e');
      return [];
    }
  }

  /// Save a new credential
  Future<void> save(Credential credential) async {
    try {
      final existing = await getAll();
      existing.add(credential);

      final jsonList = existing.map((c) => c.toJson()).toList();
      final plainJson = jsonEncode(jsonList);

      final encryptedMap = await _strongbox.encryptSym(_symKeyAlias, plainJson);

      if (encryptedMap == null) {
        throw Exception('Hardware Encryption Failed');
      }

      // Store as IV:CIPHERTEXT
      final storageValue =
          '${encryptedMap['iv']}:${encryptedMap['encryptedData']}';

      await _storage.write(key: _storageKey, value: storageValue);
      debugPrint(
          '✅ Credential saved (Hardware Encrypted): ${credential.shortId}');
    } catch (e) {
      debugPrint('❌ Failed to save credential: $e');
      rethrow;
    }
  }

  /// Delete a credential by ID
  Future<void> delete(String id) async {
    try {
      final existing = await getAll();
      final filtered = existing.where((c) => c.id != id).toList();

      final jsonList = filtered.map((c) => c.toJson()).toList();
      final plainJson = jsonEncode(jsonList);

      final encryptedMap = await _strongbox.encryptSym(_symKeyAlias, plainJson);
      if (encryptedMap == null) {
        throw Exception('Hardware Encryption Failed');
      }

      final storageValue =
          '${encryptedMap['iv']}:${encryptedMap['encryptedData']}';

      await _storage.write(key: _storageKey, value: storageValue);
      debugPrint('🗑️  Credential deleted: $id');
    } catch (e) {
      debugPrint('❌ Failed to delete credential: $e');
      rethrow;
    }
  }

  /// Clear all credentials (for testing/reset)
  Future<void> clearAll() async {
    await _storage.delete(key: _storageKey);
    debugPrint('🧹 All credentials cleared');
  }
}
