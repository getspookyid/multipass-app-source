/// Verifiable Credential Model
/// Represents a BBS+ signed credential (admin, identity, etc.)
class Credential {
  final String id;
  final String issuer;
  final String type; // "admin" | "identity"
  final Map<String, String> attributes; // name, birthdate, etc.
  final String signature; // Base64 BBS+ signature
  final String publicKey; // Base64 issuer public key
  final DateTime issuedAt;

  Credential({
    required this.id,
    required this.issuer,
    required this.type,
    required this.attributes,
    required this.signature,
    required this.publicKey,
    required this.issuedAt,
  });

  /// Parse from admin_credential.json format
  factory Credential.fromJson(Map<String, dynamic> json) {
    String type = json['type'] ?? 'identity';

    // Auto-detect admin from issuer or content
    final issuer = json['issuer'] ?? '';
    final dynamic rawAttributes = json['attributes'] ?? json['messages'] ?? {};
    final Map<String, String> attributesMap = {};

    if (rawAttributes is Map) {
      rawAttributes
          .forEach((k, v) => attributesMap[k.toString()] = v.toString());
    } else if (rawAttributes is List) {
      for (int i = 0; i < rawAttributes.length; i++) {
        attributesMap[i.toString()] = rawAttributes[i].toString();
      }
    }

    if (issuer.contains('Admin') ||
        issuer.contains('Host (Safe Mode)') ||
        attributesMap.values.any((v) => v.contains('Admin'))) {
      type = 'admin';
    }

    return Credential(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      issuer: issuer.isEmpty ? 'Unknown' : issuer,
      type: type,
      attributes: attributesMap,
      signature: json['signature'] ?? json['signature_hex'] ?? '',
      publicKey:
          json['public_key'] ?? json['publicKey'] ?? json['pk_hex'] ?? '',
      issuedAt: json['timestamp'] != null
          ? (json['timestamp'] is int
              ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] * 1000)
              : DateTime.parse(json['timestamp'].toString()))
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issuer': issuer,
      'type': type,
      'attributes': attributes,
      'signature': signature,
      'public_key': publicKey,
      'timestamp': issuedAt.toIso8601String(),
    };
  }

  /// Display name for UI
  String get displayName {
    return attributes['name'] ?? attributes['issuer'] ?? 'Credential';
  }

  /// Short ID for display
  String get shortId {
    return id.length > 8 ? id.substring(0, 8) : id;
  }
}
