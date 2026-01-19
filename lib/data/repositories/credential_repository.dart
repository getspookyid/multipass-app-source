import 'dart:convert';
import 'dart:typed_data';
import 'package:multipass/core/crypto_bridge.dart';

class CredentialRepository {
  final CryptoBridge _cryptoBridge;
  
  // Mock "Master Credential" Data (simulating a stored mDL)
  // Indexes:
  // 0: Credential ID
  // 1: Subject DID
  // 2: Family Name
  // 3: Given Name
  // 4: Birth Date
  // 5: Issue Date
  // 6: Expiry Date
  // 7: Driving Privileges
  final List<String> _attributes = [
    "vc:spooky:mock:12345",
    "did:spooky:alice",
    "Doe",
    "Alice",
    "1990-01-01",
    "2026-01-01",
    "2030-01-01",
    "A,B"
  ];

  // Hardcoded Mock Signature (Would be checked against Mock Issuer PK)
  // In a real app, this comes from the Issuer during Issuance.
  // We use placeholder bytes here since we can't generate a real sig 
  // without running the Rust 'sign' function with the Issuer SK.
  final Uint8List _mockSignature = Uint8List(112); 
  
  // Mock Issuer Public Key (Placeholder)
  final Uint8List _mockPublicKey = Uint8List(96);

  CredentialRepository(this._cryptoBridge);

  List<String> get attributes => _attributes;

  /// Generates a ZKP revealing only the specified indices
  Future<Uint8List> generatePresentation({
    required List<int> revealedIndices,
    required String nonce,
    required String siteId,
  }) async {
    // 1. Prepare Messages (UTF-8 Bytes)
    List<Uint8List> messages = _attributes.map((s) => Uint8List.fromList(utf8.encode(s))).toList();

    // 2. Prepare Nonce & SiteID
    Uint8List nonceBytes = Uint8List.fromList(utf8.encode(nonce));
    Uint8List siteBytes = Uint8List.fromList(utf8.encode(siteId));

    // 3. Call Bridge
    return await _cryptoBridge.createProof(
      publicKey: _mockPublicKey,
      signature: _mockSignature,
      messages: messages,
      revealedIndices: revealedIndices,
      nonce: nonceBytes,
      siteId: siteBytes,
    );
  }
}
