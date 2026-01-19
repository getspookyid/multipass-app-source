import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../core/diagnostic_manager.dart';

class NfcDataSource {
  // J3H145 Applet AID (Example)
  static const String _aid = "A000000151000000";

  Future<void> connect() async {
    if (diagnosticManager.isDiagnosticMode) {
      debugPrint('👻 Ghost Mode: Skipping physical NFC poll.');
      return;
    }
    // Poll for ISO-DEP card
    await FlutterNfcKit.poll(
      timeout: const Duration(seconds: 10),
      iosMultipleTagMessage: "Multiple tags found!",
      iosAlertMessage: "Hold your phone near the Anchor",
    );
  }

  Future<Uint8List> transceive(Uint8List capdu) async {
    if (diagnosticManager.isDiagnosticMode) {
      debugPrint('👻 Ghost Mode: Mocking APDU transceive.');
      return Uint8List.fromList([0x90, 0x00]); // Status OK
    }
    return await FlutterNfcKit.transceive(capdu);
  }

  Future<void> disconnect() async {
    if (diagnosticManager.isDiagnosticMode) return;
    await FlutterNfcKit.finish();
  }

  /// Select the SpookyID Applet
  Future<bool> selectApplet() async {
    if (diagnosticManager.isDiagnosticMode) {
      debugPrint('👻 Ghost Mode: Mocking Applet Selection.');
      return true;
    }
    final capdu = _buildSelectApdu(_aid);
    final rapdu = await transceive(capdu);
    // basic check for 9000
    if (rapdu.length >= 2) {
      final sw1 = rapdu[rapdu.length - 2];
      final sw2 = rapdu[rapdu.length - 1];
      return sw1 == 0x90 && sw2 == 0x00;
    }
    return false;
  }

  Uint8List _buildSelectApdu(String aid) {
    // 00 A4 04 00 Lc [AID] 00
    final aidBytes = _hexToBytes(aid);
    final bb = BytesBuilder();
    bb.addByte(0x00); // CLA
    bb.addByte(0xA4); // INS
    bb.addByte(0x04); // P1
    bb.addByte(0x00); // P2
    bb.addByte(aidBytes.length); // Lc
    bb.add(aidBytes);
    bb.addByte(0x00); // Le
    return bb.toBytes();
  }

  Uint8List _hexToBytes(String hex) {
    final result = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(result);
  }
}
