import 'package:flutter/material.dart';
import 'presentation/screens/recovery_import_screen.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/scan_screen.dart';
import 'presentation/screens/wallet_screen.dart';
import 'presentation/screens/import_screen.dart';
import 'presentation/screens/admin_login_screen.dart';
import 'presentation/screens/recovery_split_screen.dart';
import 'data/datasources/nfc_datasource.dart';
import 'data/repositories/card_repository_impl.dart';
import 'domain/repositories/card_repository.dart';
import 'core/diagnostic_manager.dart';

import 'src/rust/api.dart'; // Ensure this matches your FRB generation
import 'src/rust/frb_generated.dart';
import 'core/strongbox_manager.dart';

import 'core/security_guard.dart';
import 'presentation/screens/security_failure_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  await diagnosticManager.initialize();

  try {
    // Phase 10: Fail-Closed Security Check
    final guard = SecurityGuard();
    await guard.verifyDeviceIntegrity();

    // Phase 6: Initialize Native Bridge with StrongBox Entropy
    final strongbox = StrongboxManager();
    // Request 32 bytes of secure entropy from Android KeyStore/SecureRandom
    final strongboxSeed = await strongbox.getEntropy(32);
    // Inject into Rust Bridge (Fail-Closed if this fails)
    // Note: initBridge is likely in api.dart or generated top-level
    await RustLib.instance.api
        .crateApiInitBridge(strongboxSeed: strongboxSeed.toList());

    runApp(const MultipassApp());
  } catch (e) {
    // If strict security check fails, show Red Screen of Death
    runApp(SecurityFailureScreen(errorMessage: e.toString()));
  }
}

class MultipassApp extends StatelessWidget {
  const MultipassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CardRepository>(
          create: (_) => CardRepositoryImpl(NfcDataSource()),
        ),
      ],
      child: MaterialApp(
        title: 'SpookyID Multipass',
        theme: AppTheme.darkTheme, // Ensure AppTheme is defined
        initialRoute: '/',
        routes: {
          '/': (context) => const OnboardingScreen(),
          '/scan': (context) => const ScanScreen(),
          '/wallet': (context) => const WalletScreen(),
          '/import': (context) => const ImportScreen(),
          '/admin-login': (context) => const AdminLoginScreen(),
          '/recovery-split': (context) => const RecoverySplitScreen(),
          '/recovery/import': (context) => const RecoveryImportScreen(),
        },
      ),
    );
  }
}
