import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/strongbox_manager.dart';

class AttestationDatasource {
  final StrongboxManager _strongboxManager;
  final String _baseUrl; // e.g. "https://api.getspooky.io"

  AttestationDatasource(this._strongboxManager,
      {String baseUrl = "http://localhost:7777"})
      : _baseUrl = baseUrl;

  /// Performs the Hardware Attestation Handshake
  /// 1. Generates Key in StrongBox (if not exists)
  /// 2. Retrieves Certificate Chain
  /// 3. Sends Chain to Broker
  Future<bool> performHandshake(String alias) async {
    try {
      // 1. Ensure Key Exists
      bool keyExists = await _strongboxManager.generateKey(alias);
      if (!keyExists) {
        throw Exception("Failed to generate StrongBox key");
      }

      // 2. Get Chain
      List<String> chainBase64 = await _strongboxManager.getAttestation(alias);
      if (chainBase64.isEmpty) {
        throw Exception("Empty attestation chain");
      }

      // 3. Send to Broker
      final response = await http.post(
        Uri.parse('$_baseUrl/api/register_device'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_alias': alias,
          'attestation_chain': chainBase64,
        }),
      );

      if (response.statusCode == 200) {
        print("Attestation Handshake Successful!");
        return true;
      } else {
        print("Handshake Failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Attestation Error: $e");
      return false;
    }
  }
}
