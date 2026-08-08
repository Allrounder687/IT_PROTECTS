import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../state/auth_notifier.dart';

class BiometricSetupScreen extends ConsumerStatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  ConsumerState<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen> {
  bool _isChecking = true;
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    debugPrint('[BIOMETRIC_SETUP] checking biometrics...');
    bool canCheckBiometrics = false;
    
    try {
      final auth = LocalAuthentication();
      final canLocalCheck = await auth.canCheckBiometrics;
      final isSupported = await auth.isDeviceSupported();
      final biometrics = await auth.getAvailableBiometrics();
      debugPrint('[BIOMETRIC_SETUP] LocalAuth canCheck=$canLocalCheck, supported=$isSupported, available=$biometrics');
      canCheckBiometrics = canLocalCheck && isSupported;
    } catch (e) {
      debugPrint('[BIOMETRIC_SETUP] LocalAuth exception: $e');
      canCheckBiometrics = false;
    }
    
    if (mounted) {
      setState(() {
        _canCheckBiometrics = canCheckBiometrics;
        _isChecking = false;
      });
      
      // If biometrics are not supported on this device, skip this screen.
      if (!canCheckBiometrics) {
        context.go('/setup-cloud');
      }
    }
  }

  Future<void> _enableBiometrics() async {
    try {
      await ref.read(authNotifierProvider.notifier).enrollBiometrics();
      if (mounted) {
        context.go('/setup-cloud');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to enable biometrics. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_canCheckBiometrics) {
      // Screen will auto-skip via initState, but return empty scaffold just in case
      return const Scaffold();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Unlock'),
        actions: [
          TextButton(
            onPressed: () => context.go('/setup-cloud'),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(
                Icons.fingerprint,
                size: 100,
                color: Colors.greenAccent,
              ),
              const SizedBox(height: 32),
              Text(
                'Unlock Quickly & Securely',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Unlock IT PROTECTS instantly using your device\'s fingerprint or Face ID.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _enableBiometrics,
                  child: const Text('Enable Biometrics'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: () => context.go('/setup-cloud'),
                  child: const Text('Maybe later'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
