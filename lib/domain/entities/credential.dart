class Credential {
  final String id;
  final String issuer;
  final DateTime issuanceDate;
  final String type;
  final Map<String, dynamic> claims;

  Credential({
    required this.id,
    required this.issuer,
    required this.issuanceDate,
    required this.type,
    required this.claims,
  });
}
