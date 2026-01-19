import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multipass/core/security_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel('io.getspooky.multipass/strongbox');
  final List<MethodCall> log = <MethodCall>[];

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'isStrongBoxAvailable':
            // Default mock: StrongBox is available
            return true;
          case 'checkAttestation':
            // Default mock: Attestation check passes
            return true;
          default:
            return null;
        }
      },
    );
    // Ensure Diagnostic Mode is FALSE for strict testing
    // Accessing private field if possible or just assuming default.
    // DiagnosticManager singleton should be default.
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      null,
    );
  });

  group('SecurityGuard Fail-Closed Tests', () {
    test(
        'verifyDeviceIntegrity passes when StrongBox and Attestation are valid',
        () async {
      final guard = SecurityGuard();
      await guard.verifyDeviceIntegrity();
      expect(log, hasLength(2));
      expect(log[0].method, 'isStrongBoxAvailable');
      expect(log[1].method, 'checkAttestation');
    });

    test('verifyDeviceIntegrity throws Violation when StrongBox is missing',
        () async {
      // Mock StrongBox MISSING
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          if (methodCall.method == 'isStrongBoxAvailable') return false;
          return null;
        },
      );

      final guard = SecurityGuard();

      expect(
        () async => await guard.verifyDeviceIntegrity(),
        throwsA(isA<SecurityViolationException>()),
      );
    });

    test('verifyDeviceIntegrity throws Violation when Attestation fails',
        () async {
      // Mock StrongBox OK, but Attestation FAIL
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          if (methodCall.method == 'isStrongBoxAvailable') return true;
          if (methodCall.method == 'checkAttestation') return false;
          return null;
        },
      );

      final guard = SecurityGuard();

      expect(
        () async => await guard.verifyDeviceIntegrity(),
        throwsA(isA<SecurityViolationException>()),
      );
    });
  });
}
