import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'diagnostic_manager.dart';
import '../src/rust/api.dart';

class CryptoBridge {
  /// Generates a BBS+ Zero-Knowledge Proof (Native)
  Future<Uint8List> createProof({
    required Uint8List publicKey,
    required Uint8List signature,
    required List<Uint8List> messages,
    required List<int> revealedIndices,
    required Uint8List nonce,
    required Uint8List siteId,
  }) async {
    // Note: User-provided Rust implementation dropped nonce/siteId/freshness support
    // We strictly follow the 'generateBbsProof' signature.
    return generateBbsProof(
      dpkBytes: publicKey,
      sigBytes: signature,
      messages: messages.map((m) => utf8.decode(m)).toList(),
      revealedIndices: Uint64List.fromList(revealedIndices),
    );
  }

  /// Verifies a BBS+ Proof (Native)
  Future<bool> verifyProof({
    required Uint8List publicKey,
    required Uint8List proof,
    required int totalMessageCount,
    required List<int> revealedIndices,
    required List<Uint8List> revealedMessages,
    required Uint8List nonce,
  }) async {
    return verifyProofApi(
      publicKey: publicKey,
      proof: proof,
      totalMessageCount: BigInt.from(totalMessageCount),
      revealedIndices: revealedIndices,
      revealedMessagesContent: revealedMessages,
      nonce: nonce,
      aliasIndex: BigInt.from(0),
      freshnessClaim: null,
    );
  }

  /// Splits a secret into N shares with threshold K (Native SSS)
  Future<List<Uint8List>> splitSecret({
    required Uint8List secret,
    required int threshold,
    required int total,
  }) async {
    return splitSecretApi(
      secret: secret,
      threshold: threshold,
      total: total,
    );
  }

  /// Reconstructs secret from shares (Native SSS)
  Future<Uint8List> reconstructSecret({
    required List<Uint8List> shares,
  }) async {
    return reconstructSecretApi(shares: shares);
  }

  /// Encodes data into mDoc CBOR format (Native)
  Future<Uint8List> encodeMdoc({
    required String docType,
    required String dataJson,
  }) async {
    final docTypeBytes = Uint8List.fromList(utf8.encode(docType));
    final dataJsonBytes = Uint8List.fromList(utf8.encode(dataJson));

    return encodeMdocBytes(
      docType: docTypeBytes,
      dataJson: dataJsonBytes,
    );
  }

  /// Signs the MSO using the issuer's private key (Native)
  Future<Uint8List> signMso(List<int> msoBytes, List<int> privateKey) async {
    return signMsoBytes(
      msoBytes: Uint8List.fromList(msoBytes),
      issuerPrivateKey: Uint8List.fromList(privateKey),
    );
  }

  /// Generate Admin Login Proof (Real via Native Bridge)
  Future<Map<String, dynamic>> generateAdminProof({
    required String issuerPubKeyHex,
    required String signatureHex,
    required List<String> messagesHex, // [timestamp, role, tier]
    required String nonce,
  }) async {
    debugPrint('🔐 Generating Real Admin Proof (BBS+ Native)...');

    try {
      final pk = Uint8List.fromList(_hexToBytes(issuerPubKeyHex));
      final sig = Uint8List.fromList(_hexToBytes(signatureHex));
      final msgs =
          messagesHex.map((m) => Uint8List.fromList(_hexToBytes(m))).toList();
      final nonceBytes = Uint8List.fromList(_hexToBytes(nonce));
      final siteId = Uint8List.fromList(utf8.encode('admin.dashboard'));

      // 0: Timestamp, 1: Role. Reveal both.
      final proof = await createProof(
        publicKey: pk,
        signature: sig,
        messages: msgs,
        revealedIndices: [0, 1],
        nonce: nonceBytes,
        siteId: siteId,
      );

      final proofHex = _bytesToHex(proof);

      // Disclosed messages match revealed_indices
      final disclosed = [
        '0:${messagesHex[0]}', // Timestamp
        '1:${messagesHex[1]}', // Role: Admin
      ];

      debugPrint(
          '✅ Real Proof generated: ${proofHex.substring(0, 32)}... (Size: ${proof.length})');

      return {
        'proof': proofHex,
        'nonce': nonce,
        'dpk': issuerPubKeyHex,
        'message_count': messagesHex.length,
        'revealed_indices': [0, 1],
        'disclosed_messages': disclosed,
        'diagnostic': diagnosticManager.isDiagnosticMode,
      };
    } catch (e) {
      debugPrint('🚨 Proof generation failed: $e');
      rethrow;
    }
  }

  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  List<int> _hexToBytes(String hex) {
    final result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }
}
