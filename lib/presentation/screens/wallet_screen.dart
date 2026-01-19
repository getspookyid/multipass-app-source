import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../domain/repositories/card_repository.dart';
import '../../core/theme.dart';
import '../../data/datasources/credential_storage.dart';
import '../../data/models/credential.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  String _publicAddress = "Loading...";
  final _storage = CredentialStorage();
  List<Credential> _credentials = [];
  static const _channel = MethodChannel('io.getspooky.multipass/strongbox');

  Future<void> _deleteCredential(String id) async {
    try {
      await _storage.delete(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Credential deleted'),
            backgroundColor: AppTheme.hotPink,
          ),
        );
      }
      _loadCredentials();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadIdentity();
    _loadCredentials();
    _setupMethodChannel();
  }

  void _setupMethodChannel() {
    _channel.setMethodCallHandler((call) async {
      debugPrint('DEBUG: Method channel call: ${call.method}');
      if (call.method == 'autoImportBase64') {
        try {
          final base64String = call.arguments as String;
          final jsonString = utf8.decode(base64Decode(base64String));
          await _autoImportCredential(jsonString);
        } catch (e) {
          debugPrint('❌ Base64 decode failed: $e');
        }
      } else if (call.method == 'navigate') {
        final route = call.arguments as String;
        debugPrint('🚀 Navigating to $route via intent');
        if (mounted) {
          Navigator.pushNamed(context, route);
        }
      }
    });
  }

  Future<void> _autoImportCredential(String jsonString) async {
    try {
      debugPrint('DEBUG: Auto-importing credential...');
      final jsonData = jsonDecode(jsonString);
      final credential = Credential.fromJson(jsonData);
      await _storage.save(credential);
      await _loadCredentials();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Auto-imported: ${credential.displayName}'),
            backgroundColor: AppTheme.electricBlue,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Auto-import failed: $e');
    }
  }

  Future<void> _loadCredentials() async {
    final creds = await _storage.getAll();
    setState(() => _credentials = creds);
  }

  Future<void> _loadIdentity() async {
    try {
      final repo = context.read<CardRepository>();
      final addr = await repo.getPublicAddress();
      setState(() {
        _publicAddress = addr.length > 20
            ? "${addr.substring(0, 10)}...${addr.substring(addr.length - 8)}"
            : addr;
      });
    } catch (e) {
      setState(() => _publicAddress = "Error loading ID");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Vault",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/import');
              if (result == true) {
                _loadCredentials(); // Reload after import
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCredentials,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppTheme.electricBlue,
                      radius: 4,
                    ),
                    const SizedBox(width: 12),
                    Text("Anchor Active",
                        style: GoogleFonts.outfit(color: Colors.white)),
                    const Spacer(),
                    Text(
                      _credentials.isEmpty
                          ? "No credentials"
                          : "${_credentials.length} credential(s)",
                      style: GoogleFonts.robotoMono(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text("CREDENTIALS",
                  style: GoogleFonts.outfit(
                      color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
              const SizedBox(height: 16),

              // Credential List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _credentials.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final cred = _credentials[index];
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF222222), Color(0xFF111111)]),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.verified_user,
                                color: AppTheme.hotPink),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF6BFFB8)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Text("HARDWARE BACKED",
                                      style: GoogleFonts.robotoMono(
                                          fontSize: 10,
                                          color: AppTheme.electricBlue)),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.white38),
                                  onPressed: () => _deleteCredential(cred.id),
                                )
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(cred.displayName,
                            style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Text("Issuer: ${cred.issuer}",
                            style: GoogleFonts.robotoMono(
                                color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              // Details placeholder
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.hotPink,
                              side: const BorderSide(color: AppTheme.hotPink),
                            ),
                            child: const Text("VIEW DETAILS"),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/admin-login'),
                  icon: const Icon(Icons.admin_panel_settings, size: 20),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricBlue,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  label: const Text("ADMIN LOGIN"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
