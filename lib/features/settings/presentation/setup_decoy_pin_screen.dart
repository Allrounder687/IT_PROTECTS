import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_use_case.dart';
import '../state/settings_providers.dart';

class SetupDecoyPinScreen extends ConsumerStatefulWidget {
  const SetupDecoyPinScreen({super.key});

  @override
  ConsumerState<SetupDecoyPinScreen> createState() => _SetupDecoyPinScreenState();
}

class _SetupDecoyPinScreenState extends ConsumerState<SetupDecoyPinScreen> {
  String _pin = '';
  bool _isLoading = false;

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

  Future<void> _onContinue() async {
    if (_pin.length == 4) {
      setState(() => _isLoading = true);
      try {
        final authRepo = ref.read(authRepositoryProvider);
        final authUseCase = ref.read(authUseCaseProvider);
        
        final decoySalt = await authRepo.getOrGenerateDecoySalt();
        final hash = await authUseCase.hashPin(_pin, decoySalt);
        
        await authRepo.saveDecoyPinHash(hash);
        
        // Ensure the setting is enabled
        ref.read(securitySettingsProvider.notifier).toggleDecoyVault(true);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Decoy Vault enabled successfully!')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error setting up Decoy Vault: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Decoy PIN'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 48),
          Text(
            'Enter a fake PIN for the Decoy Vault',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Entering this PIN on the lock screen will open a constrained, fake version of your vault.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
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
                      ? Colors.redAccent
                      : Colors.transparent,
                  border: Border.all(
                    color: Colors.redAccent,
                    width: 2,
                  ),
                ),
              );
            }),
          ),
          const Spacer(),
          _buildNumberPad(),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildNumberPad() {
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
              _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    )
                  : _buildActionKey(
                      icon: Icons.check,
                      onPressed: _pin.length == 4 ? _onContinue : null,
                      color: _pin.length == 4 ? Colors.redAccent : Colors.grey,
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
