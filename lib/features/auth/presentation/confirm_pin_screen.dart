import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../state/auth_notifier.dart';

class ConfirmPinScreen extends ConsumerStatefulWidget {
  final String initialPin;
  
  const ConfirmPinScreen({super.key, required this.initialPin});

  @override
  ConsumerState<ConfirmPinScreen> createState() => _ConfirmPinScreenState();
}

class _ConfirmPinScreenState extends ConsumerState<ConfirmPinScreen> {
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

  Future<void> _verifyPin() async {
    if (_pin == widget.initialPin) {
      // Success, create the pin
      await ref.read(authNotifierProvider.notifier).createPrimaryPin(_pin);
    } else {
      // Mismatch
      setState(() {
        _isError = true;
        _shakeKey += 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next == AuthState.unlocked) {
        context.go('/setup-decoy'); // Move to the next step in onboarding
      } else if (next == AuthState.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create vault')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm PIN'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 48),
          Text(
            'Confirm your 6-digit PIN',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _isError ? 'PINs do not match. Try again.' : 'Just to be sure...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _isError ? Colors.redAccent : Colors.grey,
            ),
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
          const Spacer(),
          _buildNumberPad(authState == AuthState.authenticating),
          const SizedBox(height: 48),
        ],
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
