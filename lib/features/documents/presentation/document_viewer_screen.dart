import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/presentation/components/custom_app_bar.dart';
import '../../auth/state/auth_notifier.dart';
import '../domain/document_template.dart';
import '../../vault/data/local_vault_repository.dart';
import '../../vault/domain/encryption_use_case.dart';
import '../../../core/providers/session_provider.dart';

class DocumentViewerScreen extends ConsumerStatefulWidget {
  final String itemId;

  const DocumentViewerScreen({
    super.key,
    required this.itemId,
  });

  @override
  ConsumerState<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends ConsumerState<DocumentViewerScreen> {
  bool _isLoading = true;
  String? _error;
  DocumentTemplate? _document;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      final repo = ref.read(localVaultRepositoryProvider);
      final authMode = ref.read(authNotifierProvider).authMode;
      final encUseCase = ref.read(encryptionUseCaseProvider);
      final masterKeyBytes = ref.read(sessionProvider);

      if (masterKeyBytes == null) throw Exception("Master key not found");

      final item = await repo.getMediaItem(int.parse(widget.itemId), authMode: authMode);
      if (item == null) throw Exception("Document not found");

      if (item.encryptedMetadata == null || item.encryptedMetadata!.isEmpty) {
        // Fallback for non-metadata items
        _document = CustomDocumentTemplate(title: item.originalName, data: {});
      } else {
        final masterKey = await encUseCase.importMasterKey(masterKeyBytes);
        final jsonStr = await encUseCase.decryptMetadata(item.encryptedMetadata!, masterKey);
        _document = DocumentTemplate.fromJsonString(jsonStr);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildFieldRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardView(CreditCardTemplate template) {
    return Card(
      color: const Color(0xFF1E293B),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.credit_card, size: 40, color: Colors.white70),
            const SizedBox(height: 32),
            Text(
              template.cardNumber.isNotEmpty ? template.cardNumber.replaceAllMapped(RegExp(r".{4}"), (match) => "${match.group(0)} ") : '**** **** **** ****',
              style: const TextStyle(
                fontSize: 22,
                fontFamily: 'monospace',
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CARDHOLDER', style: TextStyle(fontSize: 10, color: Colors.white54, letterSpacing: 1)),
                    Text(template.cardholderName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('VALID THRU', style: TextStyle(fontSize: 10, color: Colors.white54, letterSpacing: 1)),
                    Text(template.expirationDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
            if (template.cvv.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              _buildFieldRow('CVV', template.cvv),
            ],
            if (template.pin != null && template.pin!.isNotEmpty) _buildFieldRow('PIN', template.pin!),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardView(DocumentTemplate template) {
    return Card(
      color: AppTheme.surfaceVariant.withValues(alpha: 0.3),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2))),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: template.data.entries.map((e) {
            // Prettify keys
            final label = e.key.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m.group(1)} ${m.group(2)}');
            return _buildFieldRow(label, e.value.toString());
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _document?.title ?? 'Document',
        actions: [
          IconButton(
            icon: const Icon(Icons.file_present),
            tooltip: 'View Attached File',
            onPressed: () {
              // Open the standard media viewer for this item
              context.push('/viewer/${widget.itemId}?isDirect=true');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.error)))
              : ListView(
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    if (_document is CreditCardTemplate)
                      _buildCreditCardView(_document as CreditCardTemplate)
                    else
                      _buildStandardView(_document!),
                    
                    const SizedBox(height: 32),
                    if (_document!.data['notes'] != null && _document!.data['notes'].toString().isNotEmpty) ...[
                      const Text('NOTES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Text(_document!.data['notes'].toString()),
                    ],
                  ],
                ),
    );
  }
}
