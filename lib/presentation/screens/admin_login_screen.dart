import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import '../../core/theme.dart';
import '../../core/crypto_bridge.dart';
import '../../data/datasources/credential_storage.dart';
import '../../core/strongbox_manager.dart'; // NEW: Enclave binding
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _storage = CredentialStorage();
  final _bridge = CryptoBridge();
  final _localAuth = LocalAuthentication();
  final _strongbox = StrongboxManager(); // NEW

  bool _isLoading = false;
  String _status = 'Authenticating...';
  String? _accessToken;
  int _phase = 1; // 1: JCOP, 2: Strongbox

  @override
  void initState() {
    super.initState();
    // Auto-start biometric auth on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateAndLogin();
    });
  }

  Future<void> _authenticateAndLogin() async {
    // Skip biometric for now (MainActivity compatibility issue)
    // Proceed directly to BBS+ proof generation
    setState(() => _status = 'Loading credential...');
    await Future.delayed(const Duration(milliseconds: 500));
    await _performAdminLogin();
  }

  Future<void> _performAdminLogin() async {
    setState(() => _isLoading = true);

    try {
      final creds = await _storage.getAll();
      debugPrint('DEBUG: Found ${creds.length} credentials');
      for (var c in creds) {
        debugPrint('DEBUG: Credential - Type: ${c.type}, Issuer: ${c.issuer}');
      }

      final adminCred = creds.firstWhere(
        (c) =>
            c.type == 'admin' ||
            c.issuer.contains('Admin') ||
            c.issuer.contains('Host'),
        orElse: () => throw Exception(
            'No admin credential. Import admin_credential.json first.'),
      );

      setState(() => _status = '✅ Credential loaded');
      debugPrint('DEBUG: Admin credential loaded: ${adminCred.id}');
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() => _status = 'Fetching nonce...');
      final nonceResp =
          await http.get(Uri.parse('http://localhost:7777/api/oidc/nonce'));

      if (nonceResp.statusCode != 200) {
        throw Exception('Nonce fetch failed: ${nonceResp.statusCode}');
      }

      final nonce = jsonDecode(nonceResp.body)['nonce'] as String;
      setState(() => _status = '✅ Nonce: ${nonce.substring(0, 16)}...');
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() => _status = 'Generating BBS+ proof...');

      final messages = adminCred.attributes.values.map((v) {
        try {
          if (v.length > 2 &&
              int.tryParse(v.substring(0, 2), radix: 16) != null) {
            return v;
          }
        } catch (_) {}
        return utf8
            .encode(v)
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
      }).toList();

      final proofPayload = await _bridge.generateAdminProof(
        issuerPubKeyHex: adminCred.publicKey,
        signatureHex: adminCred.signature,
        messagesHex: messages,
        nonce: nonce,
      );

      setState(() => _status = '✅ Proof generated');
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() => _status = 'Phase 1: Submitting Identity proof...');

      // PHASE 1: JCOP HANDSHAKE
      final loginResp = await http.post(
        Uri.parse('http://localhost:7777/api/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(proofPayload),
      );

      debugPrint('📡 Phase 1 Response: ${loginResp.statusCode}');
      if (loginResp.statusCode != 200) {
        final error = jsonDecode(loginResp.body);
        throw Exception(error['message'] ?? 'Phase 1 failed');
      }

      final phase1Result = jsonDecode(loginResp.body);
      final String deviceNonce = phase1Result['device_challenge'] ?? '';

      if (deviceNonce.isEmpty) {
        // Backward compatibility: If no challenge, assume direct login (Standard flow)
        if (phase1Result['status'] == 'verified') {
          setState(() {
            _accessToken = phase1Result['access_token'];
            _status = '✅ ACCESS GRANTED!';
          });
          return;
        } else {
          throw Exception('Invalid server response');
        }
      }

      // PHASE 2: STRONGBOX HANDSHAKE
      setState(() {
        _phase = 2;
        _status = 'Phase 2: Authorizing Device Enclave...';
      });
      await Future.delayed(const Duration(milliseconds: 500));

      final nonceBytes = utf8.encode(deviceNonce);
      final signature = await _strongbox.sign('admin_key', nonceBytes);

      if (signature == null) {
        throw Exception('Enclave signing failed. Is Strongbox active?');
      }

      setState(() => _status = '✅ Device proof generated. Finalizing...');

      final phase2Resp = await http.post(
        Uri.parse('http://localhost:7777/api/admin/verify_device'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_id': phase1Result['session_id'],
          'signature': base64Encode(signature),
          'nonce': deviceNonce,
        }),
      );

      if (phase2Resp.statusCode == 200) {
        final finalResult = jsonDecode(phase2Resp.body);
        setState(() {
          _accessToken = finalResult['access_token'];
          _status = '✅ ACCESS GRANTED!';
        });
      } else {
        final error = jsonDecode(phase2Resp.body);
        throw Exception(error['message'] ?? 'Phase 2 Authorization failed');
      }
    } catch (e) {
      setState(() {
        _status = '❌ $e';
        _accessToken = null;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _accessToken != null
                    ? Icons.verified_user
                    : (_phase == 2 ? Icons.security : Icons.fingerprint),
                size: 96,
                color: _accessToken != null
                    ? AppTheme.electricBlue
                    : (_phase == 2 ? Colors.orange : AppTheme.hotPink),
              ),
              const SizedBox(height: 32),
              Text(
                _accessToken != null ? 'Access Granted' : 'Authenticating',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _accessToken != null
                        ? AppTheme.electricBlue.withOpacity(0.5)
                        : Colors.white10,
                  ),
                ),
                child: Column(
                  children: [
                    if (_isLoading)
                      const CircularProgressIndicator(
                          color: AppTheme.electricBlue, strokeWidth: 3),
                    if (_isLoading) const SizedBox(height: 16),
                    Text(
                      _status,
                      style: GoogleFonts.robotoMono(
                        fontSize: 13,
                        color: _accessToken != null
                            ? AppTheme.electricBlue
                            : Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (_accessToken != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.electricBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.electricBlue),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Access Token',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.electricBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_accessToken!.substring(0, 48)}...',
                        style: GoogleFonts.robotoMono(
                            fontSize: 10, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminDashboardScreen(
                            accessToken: _accessToken!,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.dashboard, size: 24),
                    label: const Text('OPEN DASHBOARD'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.electricBlue,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: GoogleFonts.outfit(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ] else if (!_isLoading && _status.startsWith('❌')) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _authenticateAndLogin,
                    icon: const Icon(Icons.refresh),
                    label: const Text('RETRY'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.hotPink,
                      side: const BorderSide(color: AppTheme.hotPink),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Text(
                'StrongBox + BBS+ Zero-Knowledge',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
