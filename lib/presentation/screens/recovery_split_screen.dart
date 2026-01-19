import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme.dart';
import '../../core/crypto_bridge.dart';

class RecoverySplitScreen extends StatefulWidget {
  const RecoverySplitScreen({super.key});

  @override
  State<RecoverySplitScreen> createState() => _RecoverySplitScreenState();
}

class _RecoverySplitScreenState extends State<RecoverySplitScreen> {
  final _bridge = CryptoBridge();
  int _threshold = 2;
  int _totalShares = 3;
  List<String>? _generatedShares;
  bool _isGenerating = false;

  Future<void> _generateShares() async {
    setState(() => _isGenerating = true);

    try {
      // TODO: Get actual master secret from StrongBox
      // For now, use placeholder
      // Placeholder secret (all 7s) for demo/test until StrongBox is wired
      final placeholderSecret = List.generate(32, (i) => 7);

      final shares = await _bridge.splitSecret(
        secret: Uint8List.fromList(placeholderSecret),
        threshold: _threshold,
        total: _totalShares,
      );

      setState(() {
        _generatedShares = shares.map((s) => base64Encode(s)).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Backup Identity',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _generatedShares == null
            ? _buildConfigScreen()
            : _buildSharesScreen(),
      ),
    );
  }

  Widget _buildConfigScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trustless Recovery',
          style: GoogleFonts.outfit(
              fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          'Split your master secret into shares using Shamir\'s Secret Sharing. Distribute them to trusted locations.',
          style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.hotPink.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuration',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text('Shares Required (K)',
                  style: GoogleFonts.outfit(color: Colors.white70)),
              Slider(
                value: _threshold.toDouble(),
                min: 2,
                max: 5,
                divisions: 3,
                activeColor: AppTheme.electricBlue,
                label: '$_threshold',
                onChanged: (val) {
                  setState(() {
                    _threshold = val.toInt();
                    if (_totalShares < _threshold) _totalShares = _threshold;
                  });
                },
              ),
              const SizedBox(height: 16),
              Text('Total Shares (N)',
                  style: GoogleFonts.outfit(color: Colors.white70)),
              Slider(
                value: _totalShares.toDouble(),
                min: _threshold.toDouble(),
                max: 9,
                divisions: 9 - _threshold,
                activeColor: AppTheme.hotPink,
                label: '$_totalShares',
                onChanged: (val) => setState(() => _totalShares = val.toInt()),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.electricBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_threshold-of-$_totalShares threshold: Any $_threshold shares can recover your identity',
                  style: GoogleFonts.robotoMono(
                      fontSize: 12, color: AppTheme.electricBlue),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generateShares,
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.splitscreen),
            label: Text(_isGenerating ? 'GENERATING...' : 'GENERATE SHARES'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.hotPink,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle:
                  GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSharesScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() => _generatedShares = null),
            ),
            const SizedBox(width: 8),
            Text(
              '$_totalShares Shares Generated',
              style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Never store all shares in the same location!',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: _generatedShares!.length,
            itemBuilder: (context, index) {
              final share = _generatedShares![index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Share ${index + 1}',
                          style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.electricBlue),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy,
                              color: Colors.white70, size: 20),
                          onPressed: () {
                            // TODO: Copy to clipboard
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Share copied!')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: QrImageView(
                          data: share,
                          version: QrVersions.auto,
                          size: 180.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        share,
                        style: GoogleFonts.robotoMono(
                            fontSize: 10, color: AppTheme.hotPink),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check_circle),
            label: const Text('DONE'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.electricBlue,
              side: const BorderSide(color: AppTheme.electricBlue),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
