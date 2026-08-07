import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.backspace) {
              _onDelete();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
              if (_pin.length == 6) _verifyPin();
              return KeyEventResult.handled;
            } else if (event.character != null && RegExp(r'^[0-9]$').hasMatch(event.character!)) {
              _onKeyPress(event.character!);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: SafeArea(
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
            // FORCED ON FOR DEBUGGING
            // if (securitySettings.biometricEnabled)
              Column(
                children: [
                  IconButton(
                    iconSize: 56,
                    padding: const EdgeInsets.all(24),
                    icon: const Icon(Icons.fingerprint, color: Colors.greenAccent),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Button tapped, requesting prompt...'), duration: Duration(seconds: 1)),
                      );
                      ref.read(authNotifierProvider.notifier).unlockWithBiometrics();
                    },
                  ),
                  if (ref.watch(biometricStatusProvider) != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      ref.watch(biometricStatusProvider)!,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ],
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _onKeyPress(value),
      child: SizedBox(
        width: 80,
        height: 80,
        child: Center(
          child: Text(
            value,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey({required IconData icon, required VoidCallback? onPressed, Color? color}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: onPressed != null ? (_) => onPressed() : null,
      child: SizedBox(
        width: 80,
        height: 80,
        child: Center(
          child: Icon(icon, size: 28, color: color ?? Colors.white70),
        ),
      ),
    );
  }
}
