import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../core/theme.dart';
import '../../data/models/credential.dart';
import '../../data/datasources/credential_storage.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _storage = CredentialStorage();
  bool _isImporting = false;

  Future<void> _importFromJson(String jsonString) async {
    setState(() => _isImporting = true);
    
    try {
      final json = jsonDecode(jsonString);
      final credential = Credential.fromJson(json);
      
      await _storage.save(credential);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Credential imported: ${credential.displayName}'),
            backgroundColor: AppTheme.electricBlue,
          ),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  void _showPasteDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('Paste JSON', style: GoogleFonts.outfit(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 10,
          style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            hintText: '{ "issuer": "...", ... }',
            hintStyle: GoogleFonts.robotoMono(color: Colors.white38),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _importFromJson(controller.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.electricBlue),
            child: const Text('Import', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Import Credential', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: _isImporting
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.electricBlue),
                  const SizedBox(height: 16),
                  Text('Importing...', style: GoogleFonts.outfit(color: Colors.white54)),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // QR Scan Option
                    _buildOption(
                      icon: Icons.qr_code_scanner,
                      title: 'Scan QR Code',
                      subtitle: 'Scan a credential QR',
                      color: AppTheme.electricBlue,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('QR Scanner not implemented yet')),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // JSON Paste Option
                    _buildOption(
                      icon: Icons.content_paste,
                      title: 'Paste JSON',
                      subtitle: 'Import from clipboard',
                      color: AppTheme.hotPink,
                      onTap: _showPasteDialog,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
