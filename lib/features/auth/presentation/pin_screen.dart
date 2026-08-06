import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/auth_notifier.dart';
import '../data/auth_repository.dart';

final hasPinProvider = FutureProvider<bool>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  final pinHash = await repo.getPinHash();
  return pinHash != null;
});

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  String? _firstPin; // Used for confirm pin step

  void _onKeyPress(String key) {
    setState(() {
      if (_pin.length < 4) _pin += key;
    });
  }

  void _onDelete() {
    setState(() {
      if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  void _onContinue(bool hasPin) {
    if (_pin.length == 4) {
      if (hasPin) {
        // Unlock existing
        ref.read(authNotifierProvider.notifier).unlockVault(_pin);
      } else {
        // Setup flow
        if (_firstPin == null) {
          // First time they entered 4 digits
          setState(() {
            _firstPin = _pin;
            _pin = '';
          });
        } else {
          // Confirming
          if (_pin == _firstPin) {
            ref.read(authNotifierProvider.notifier).unlockVault(_pin);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PINs do not match. Try again.')),
            );
            setState(() {
              _firstPin = null;
              _pin = '';
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final hasPinAsync = ref.watch(hasPinProvider);
    
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next == AuthState.unlocked) {
        context.go('/vault');
      } else if (next == AuthState.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to unlock vault')),
        );
        setState(() {
          _pin = '';
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: hasPinAsync.when(
          data: (hasPin) => Text(hasPin ? 'Enter PIN' : 'Create PIN'),
          loading: () => const Text('Secure Vault'),
          error: (_, __) => const Text('Error'),
        ),
      ),
      body: hasPinAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (hasPin) => Column(
          children: [
            const SizedBox(height: 48),
            Text(
              hasPin 
                ? 'Secure your vault'
                : (_firstPin == null ? 'Create a 4-digit PIN' : 'Confirm your 4-digit PIN'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _pin.length
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const Spacer(),
            _buildNumberPad(authState == AuthState.authenticating, hasPin),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad(bool isLoading, bool hasPin) {
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
                      onPressed: _pin.length == 4 ? () => _onContinue(hasPin) : null,
                      color: _pin.length == 4 ? Theme.of(context).primaryColor : Colors.grey,
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
