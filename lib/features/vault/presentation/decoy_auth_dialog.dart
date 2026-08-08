import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_use_case.dart';
import '../domain/vault_item_entity.dart';
import '../domain/encryption_use_case.dart';
import '../data/local_vault_repository.dart';
import '../../auth/state/auth_notifier.dart';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import '../../../core/providers/auth_mode_provider.dart';
import '../../../core/providers/session_provider.dart';

class DecoyAuthDialog extends ConsumerStatefulWidget {
  final VaultItemEntity item;
  
  const DecoyAuthDialog({super.key, required this.item});

  @override
  ConsumerState<DecoyAuthDialog> createState() => _DecoyAuthDialogState();
}

class _DecoyAuthDialogState extends ConsumerState<DecoyAuthDialog> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _submit() async {
    final pin = _pinController.text;
    if (pin.length != 4) {
      setState(() => _error = 'Enter a 4-digit PIN');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final authUseCase = ref.read(authUseCaseProvider);
      
      final storedDecoyPinHash = await authRepo.getDecoyPinHash();
      if (storedDecoyPinHash == null) {
        throw Exception('Decoy Vault not set up. Set it up in Settings.');
      }

      final decoySalt = await authRepo.getOrGenerateDecoySalt();
      final enteredDecoyHash = await authUseCase.hashPin(pin, decoySalt);
      
      if (enteredDecoyHash != storedDecoyPinHash) {
        throw Exception('Incorrect Decoy PIN');
      }

      // 1. Unwrap Decoy Master Key
      final decoyKek = await authUseCase.deriveKek(pin, decoySalt);
      final wrappedDecoyKey = await authRepo.getWrappedDecoyMasterKey();
      if (wrappedDecoyKey == null) throw Exception('Decoy Master Key missing');
      
      final decoyMasterKeyBytes = await authUseCase.unwrapMasterKey(wrappedDecoyKey, decoyKek);
      final decoyMasterKey = SecretKey(decoyMasterKeyBytes);

      // 2. Unwrap CEK with Main Master Key
      final encUseCase = ref.read(encryptionUseCaseProvider);
      final mainMasterKeyBytes = ref.read(sessionProvider);
      if (mainMasterKeyBytes == null) throw Exception('Main session missing');
      final mainMasterKey = SecretKey(mainMasterKeyBytes);
      
      final ivBase64 = widget.item.iv;
      final wrappedKeyBase64 = widget.item.wrappedContentKey;
      
      final nonce = base64Decode(ivBase64);
      final wrappedKeyData = base64Decode(wrappedKeyBase64);
      final macLength = 16; // AES-GCM MAC length is 16
      final cipherText = wrappedKeyData.sublist(0, wrappedKeyData.length - macLength);
      final macBytes = wrappedKeyData.sublist(wrappedKeyData.length - macLength);
      
      final cekBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      );
      
      final aesGcm = AesGcm.with256bits();
      final cekBytes = await aesGcm.decrypt(
        cekBox,
        secretKey: mainMasterKey,
      );
      
      // 3. Rewrap CEK with Decoy Master Key
      final newCekBox = await aesGcm.encrypt(
        cekBytes,
        secretKey: decoyMasterKey,
      );
      
      final newWrappedKeyBase64 = base64Encode(newCekBox.cipherText + newCekBox.mac.bytes);
      final newIvBase64 = base64Encode(newCekBox.nonce);

      // 4. Find Decoy Vault album and move item
      final repo = ref.read(localVaultRepositoryProvider);
      final decoyAlbumId = await repo.getOrCreateDecoyAlbum(authMode: AuthMode.decoy);
      
      await repo.updateMediaItemKeys(widget.item.id, newWrappedKeyBase64, newIvBase64, authMode: AuthMode.real);
      await repo.moveItemToAlbum(widget.item.id, decoyAlbumId, authMode: AuthMode.real);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text('Mark as Decoy'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter your Decoy PIN to move this file to the Decoy Vault. It will be hidden from the main vault.'),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            decoration: InputDecoration(
              hintText: '4-digit PIN',
              errorText: _error,
            ),
          ),
          if (_isLoading) const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: CircularProgressIndicator(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
