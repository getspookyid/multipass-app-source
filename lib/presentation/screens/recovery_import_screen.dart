import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../core/theme.dart';
import '../../core/crypto_bridge.dart';

class RecoveryImportScreen extends StatefulWidget {
  const RecoveryImportScreen({super.key});

  @override
  State<RecoveryImportScreen> createState() => _RecoveryImportScreenState();
}

class _RecoveryImportScreenState extends State<RecoveryImportScreen> {
  final _bridge = CryptoBridge();
  final MobileScannerController _scannerController = MobileScannerController();
  final Set<String> _scannedShares = {};
  bool _isReconstructing = false;
  String _statusMessage = 'Scan your Guardian Shares';
  final int _threshold = 3; // Default, will try to infer or require 3

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isReconstructing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final share = barcode.rawValue!;
        if (!_scannedShares.contains(share)) {
          setState(() {
            _scannedShares.add(share);
            _statusMessage = 'Scanned ${_scannedShares.length} shares';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Share Scanned! Total: ${_scannedShares.length}'),
                duration: const Duration(seconds: 1)),
          );
        }
      }
    }
  }

  Future<void> _attemptRecovery() async {
    if (_scannedShares.length < _threshold) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Need at least $_threshold shares to attempt recovery')),
      );
      return;
    }

    setState(() {
      _isReconstructing = true;
      _statusMessage = 'Attempting Reconstruction...';
    });

    try {
      final List<Uint8List> sharesBytes =
          _scannedShares.map((s) => base64Decode(s)).toList();

      final secret = await _bridge.reconstructSecret(shares: sharesBytes);

      // Verification successful if no error thrown
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text('Identity Recovered!',
              style: GoogleFonts.outfit(color: AppTheme.electricBlue)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text(
                'Your Master Identity has been successfully reconstructed from ${_scannedShares.length} shares.',
                style: GoogleFonts.outfit(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                'Secret Hash: ${secret.sublist(0, 4).toString()}', // Debug info
                style:
                    GoogleFonts.robotoMono(color: Colors.white30, fontSize: 10),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Exit screen
              },
              child: const Text('CONTINUE'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recovery Failed: $e')),
      );
    } finally {
      setState(() {
        _isReconstructing = false;
        _statusMessage = 'Ready to Scan';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Import Identity',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.electricBlue.withValues(alpha: 0.5)),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onDetect,
                  ),
                  Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppTheme.hotPink.withValues(alpha: 0.5),
                            width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scanned Shares',
                    style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusMessage,
                    style:
                        GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _scannedShares.length,
                      itemBuilder: (context, index) {
                        final share = _scannedShares.elementAt(index);
                        return ListTile(
                          leading: const Icon(Icons.qr_code,
                              color: AppTheme.electricBlue),
                          title: Text('Share Fragment #${index + 1}',
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text('${share.substring(0, 10)}...',
                              style: const TextStyle(
                                  color: Colors.white30,
                                  fontFamily: 'monospace')),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                _scannedShares.remove(share);
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isReconstructing ? null : _attemptRecovery,
                      icon: _isReconstructing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.lock_open),
                      label: Text(_isReconstructing
                          ? 'RECONSTRUCTING...'
                          : 'RECOVER IDENTITY'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.electricBlue,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        textStyle: GoogleFonts.outfit(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
