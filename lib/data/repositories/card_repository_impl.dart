import 'package:flutter/foundation.dart';
import '../../domain/repositories/card_repository.dart';
import '../../data/datasources/nfc_datasource.dart';
import '../../core/rust_bridge.dart';

class CardRepositoryImpl implements CardRepository {
  final NfcDataSource _nfcDataSource;

  CardRepositoryImpl(this._nfcDataSource);

  @override
  Future<void> connect() async {
    await _nfcDataSource.connect();
  }

  @override
  Future<void> disconnect() async {
    await _nfcDataSource.disconnect();
  }

  @override
  Future<bool> authenticate() async {
    // 1. Select Applet
    debugPrint("🔵 Selecting Applet...");
    final selected = await _nfcDataSource.selectApplet();
    if (!selected) return false;

    // 2. Get Challenge/Seed (Mock APDU 00 CA 00 00 00)
    // In PROD: This would be a real SCP03 handshake + GET DATA
    // For now we simulate success
    return true;
  }

  @override
  Future<String> getPublicAddress() async {
    // 1. Get Seed from Card (Mock)
    const seedHex = "000102030405060708090A0B0C0D0E0F";

    // 2. Derive SK via Rust Bridge
    final sk =
        await RustBridge.bbsDeriveSkFromSeed(seedHex, "SpookyID-Context");

    // 3. Generate Public ID (Linkage Tag for 'global')
    final tag =
        await RustBridge.bbsGenerateLinkageTag(sk, "global.spookyid.io");
    debugPrint("🟢 HANDSHAKE COMPLETE. Tag: $tag");

    return tag;
  }
}
