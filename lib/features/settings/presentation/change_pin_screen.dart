import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/presentation/components/custom_app_bar.dart';
import '../../../core/theme/app_theme.dart';

enum ChangePinStep { verifyCurrent, enterNew, confirmNew }

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  ChangePinStep _step = ChangePinStep.verifyCurrent;
  String _pin = '';
  String _newPin = '';
  bool _hasError = false;

  void _onKeyPress(String key) {
    if (_pin.length < 6) {
      setState(() {
        _pin += key;
        _hasError = false;
      });
      if (_pin.length == 6) {
        _onSubmit();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _hasError = false;
      });
    }
  }

  void _onSubmit() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      
      if (_step == ChangePinStep.verifyCurrent) {
        // Mock verification
        if (_pin == '123456') { // Mock current PIN
           setState(() {
             _step = ChangePinStep.enterNew;
             _pin = '';
           });
        } else {
          _showError();
        }
      } else if (_step == ChangePinStep.enterNew) {
        // Basic validation
        if (_pin == '123456' || _pin == '000000') { // Mock validation failure
          _showError();
        } else {
          setState(() {
             _newPin = _pin;
             _step = ChangePinStep.confirmNew;
             _pin = '';
          });
        }
      } else if (_step == ChangePinStep.confirmNew) {
        if (_pin == _newPin) {
          // Success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Master PIN successfully changed')),
          );
          context.pop();
        } else {
          _showError();
          setState(() {
             _step = ChangePinStep.enterNew;
             _pin = '';
             _newPin = '';
          });
        }
      }
    });
  }

  void _showError() {
    setState(() {
      _hasError = true;
      _pin = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    String title = '';
    String subtitle = '';
    
    switch (_step) {
      case ChangePinStep.verifyCurrent:
        title = 'Enter Current PIN';
        subtitle = 'Verify your identity to continue';
        break;
      case ChangePinStep.enterNew:
        title = 'Create New PIN';
        subtitle = 'Must be 6 digits. Avoid common patterns.';
        break;
      case ChangePinStep.confirmNew:
        title = 'Confirm New PIN';
        subtitle = 'Enter your new PIN again';
        break;
    }

    Widget pinDots = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isFilled = index < _pin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppTheme.primary : AppTheme.surfaceVariant,
            border: isFilled ? null : Border.all(color: Colors.grey.withValues(alpha: 0.5)),
          ),
        );
      }),
    );

    if (_hasError) {
      pinDots = pinDots.animate(onPlay: (controller) => controller.forward(from: 0)).shakeX();
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Change PIN'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(color: _hasError ? Colors.redAccent : AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 48),
                    pinDots,
                  ],
                ),
              ),
            ),
            _buildNumpad(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['1', '2', '3'].map((key) => _buildNumKey(key)).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['4', '5', '6'].map((key) => _buildNumKey(key)).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['7', '8', '9'].map((key) => _buildNumKey(key)).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72, height: 72),
              _buildNumKey('0'),
              _buildBackspaceKey(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumKey(String digit) {
    return InkWell(
      onTap: () => _onKeyPress(digit),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surfaceVariant.withValues(alpha: 0.3),
        ),
        child: Text(
          digit,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    return InkWell(
      onTap: _onBackspace,
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        child: const Icon(Icons.backspace_outlined, size: 28),
      ),
    );
  }
}
