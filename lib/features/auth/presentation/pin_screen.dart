import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../state/auth_notifier.dart';
import '../../settings/state/settings_providers.dart';
import 'onboarding_screen.dart';

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  bool _isError = false;
  double _shakeKey = 0.0;

  void _onKeyPress(String key) {
    if (_isError) {
      setState(() {
        _isError = false;
        _pin = '';
      });
    }

    setState(() {
      if (_pin.length < 6) _pin += key;
    });

    if (_pin.length == 6) {
      _verifyPin();
    }
  }

  void _onDelete() {
    setState(() {
      if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      _isError = false;
    });
  }

  void _verifyPin() {
    ref.read(authNotifierProvider.notifier).unlockVault(_pin);
  }

  void _triggerShake() {
    setState(() {
      _isError = true;
      _shakeKey += 1.0;
    });
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot PIN?'),
        content: const Text(
          'IT PROTECTS uses zero-knowledge encryption. We do not have your PIN, so we cannot recover it for you.\n\n'
          'If you cannot remember your PIN, you must completely reset your vault, which will permanently delete all encrypted files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authNotifierProvider.notifier).resetVault().then((_) {
                if (context.mounted) {
                  // Invalidate the provider so OnboardingScreen knows the PIN is gone
                  ref.invalidate(hasPinProvider);
                  context.go('/');
                }
              });
            },
            child: const Text('Reset Vault', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final securitySettings = ref.watch(securitySettingsProvider);
    
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next == AuthState.unlocked) {
        context.go('/vault');
      } else if (next == AuthState.error) {
        _triggerShake();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect PIN')),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Text(
              'Enter PIN for IT PROTECTS',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ).animate(key: ValueKey(_shakeKey))
              .shake(hz: 8, curve: Curves.easeInOut),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _pin.length
                        ? (_isError ? Colors.redAccent : Theme.of(context).primaryColor)
                        : Colors.transparent,
                    border: Border.all(
                      color: _isError ? Colors.redAccent : Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                );
              }),
            ).animate(key: ValueKey(_shakeKey + 1))
              .shakeX(hz: 8, curve: Curves.easeInOut),
            const SizedBox(height: 16),
            if (securitySettings.biometricEnabled)
              IconButton(
                icon: const Icon(Icons.fingerprint, size: 40, color: Colors.greenAccent),
                onPressed: () {
                  ref.read(authNotifierProvider.notifier).unlockWithBiometrics();
                },
              ),
            const Spacer(),
            _buildNumberPad(authState == AuthState.authenticating),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _showForgotPinDialog,
              child: const Text('Forgot PIN?', style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad(bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [_buildKey('1'), _buildKey('2'), _buildKey('3')],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [_buildKey('4'), _buildKey('5'), _buildKey('6')],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [_buildKey('7'), _buildKey('8'), _buildKey('9')],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionKey(icon: Icons.backspace, onPressed: _onDelete),
              _buildKey('0'),
              isLoading
                  ? const CircularProgressIndicator()
                  : _buildActionKey(
                      icon: Icons.check,
                      onPressed: _pin.length == 6 ? _verifyPin : null,
                      color: _pin.length == 6 ? Theme.of(context).primaryColor : Colors.grey,
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String value) {
    return TextButton(
      onPressed: () => _onKeyPress(value),
      style: TextButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(24),
        foregroundColor: Colors.white,
      ),
      child: Text(
        value,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildActionKey({required IconData icon, required VoidCallback? onPressed, Color? color}) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(24),
        foregroundColor: color ?? Colors.white70,
      ),
      child: Icon(icon, size: 28),
    );
  }
}
