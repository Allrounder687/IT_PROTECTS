import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  String _pin = '';

  void _onKeyPress(String key) {
    setState(() {
      if (_pin.length < 6) _pin += key;
    });
  }

  void _onDelete() {
    setState(() {
      if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  bool _isPinValid() {
    if (_pin.length != 6) return false;
    // Check for trivial sequences
    if (_pin == '123456' || _pin == '000000' || _pin == '111111' || _pin == '222222' || 
        _pin == '333333' || _pin == '444444' || _pin == '555555' || _pin == '666666' || 
        _pin == '777777' || _pin == '888888' || _pin == '999999' || _pin == '654321') {
      return false;
    }
    return true;
  }

  void _onContinue() {
    if (_isPinValid()) {
      context.push('/setup-pin/confirm', extra: _pin);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a stronger PIN')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create PIN'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 48),
          Text(
            'Create a 6-digit Vault PIN',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Avoid common patterns like 123456',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
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
              _buildActionKey(
                icon: Icons.arrow_forward,
                onPressed: _isPinValid() ? _onContinue : null,
                color: _isPinValid() ? Theme.of(context).primaryColor : Colors.grey,
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
