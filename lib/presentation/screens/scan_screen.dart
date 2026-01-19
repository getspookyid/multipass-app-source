import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../domain/repositories/card_repository.dart';
import '../../core/theme.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}



class _ScanScreenState extends State<ScanScreen> {
  String _status = "TAP ANCHOR";
  String _subStatus = "Hold card to back of phone";
  bool _isScanning = false;

  Future<void> _startPairing() async {
    debugPrint("🔵 NFC SCAN INITIATED");
    setState(() {
      _isScanning = true;
      _status = "CONNECTING...";
    });

    try {
      final repo = context.read<CardRepository>();
      
      // 1. Connect (Poll)
      await repo.connect();
      
      if (mounted) setState(() => _status = "SECURING CHANNEL...");
      
      // 2. Authenticate (SCP03 handshake + Select)
      final success = await repo.authenticate();
      if (!success) throw Exception("Auth Failed");
      
      if (mounted) setState(() => _status = "DERIVING KEYS...");
      
      // 3. Verify Identity (Get Public Address)
      await repo.getPublicAddress(); // Just verifying we can derive it
      
      // Success!
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/wallet');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = "ERROR";
          _subStatus = e.toString();
          _isScanning = false;
        });
      }
    } finally {
      // Don't disconnect here in a real app if we want to keep session, 
      // but for this flow we might want to release NFC.
      // context.read<CardRepository>().disconnect(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Anchor Pairing"),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _isScanning ? null : _startPairing,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isScanning ? AppTheme.electricBlue : Colors.white24,
                    width: 2,
                  ),
                  boxShadow: _isScanning ? [
                     BoxShadow(color: AppTheme.electricBlue.withOpacity(0.3), blurRadius: 30, spreadRadius: 5)
                  ] : [],
                ),
                child: Icon(
                  Icons.nfc,
                  size: 80,
                  color: _isScanning ? AppTheme.electricBlue : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              _status,
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.hotPink),
            ),
            const SizedBox(height: 8),
            Text(
              _subStatus,
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
