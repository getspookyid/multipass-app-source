import 'package:flutter/foundation.dart';
import 'dart:io';

/// Manages the application's "Ghost Mode" (Diagnostic Layer).
/// This allows the AGENT to perform autonomous testing by mocking hardware.
class DiagnosticManager {
  static final DiagnosticManager _instance = DiagnosticManager._internal();
  factory DiagnosticManager() => _instance;
  DiagnosticManager._internal();

  bool _isDiagnosticMode = false;

  /// Returns true if the app is in diagnostic/testing mode.
  bool get isDiagnosticMode => _isDiagnosticMode;

  /// Checks for diagnostic mode triggers.
  /// 1. Presence of /sdcard/spooky_test_mode
  /// 2. (Optional) Custom build flag
  Future<void> initialize() async {
    try {
      final triggerFile = File('/sdcard/spooky_test_mode');
      if (await triggerFile.exists()) {
        _isDiagnosticMode = true;
        debugPrint('🕵️ DIAGNOSTIC MODE ACTIVE: Found trigger file.');
      }
    } catch (e) {
      // Fail silent in case of permission issues
      debugPrint('DiagnosticManager init error: $e');
    }

    if (kDebugMode && !_isDiagnosticMode) {
      debugPrint('DiagnosticManager: Running in Debug Mode (Normal).');
    }
  }

  /// Manually enable diagnostic mode (useful for unit tests or specific intents).
  void enableDiagnosticMode() {
    _isDiagnosticMode = true;
    debugPrint('🕵️ DIAGNOSTIC MODE ENABLED MANUALLY.');
  }
}

final diagnosticManager = DiagnosticManager();
