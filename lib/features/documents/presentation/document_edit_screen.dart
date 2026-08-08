import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/document_template.dart';
import '../../vault/state/vault_notifier.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/presentation/components/custom_app_bar.dart';

class DocumentEditScreen extends ConsumerStatefulWidget {
  const DocumentEditScreen({super.key});

  @override
  ConsumerState<DocumentEditScreen> createState() => _DocumentEditScreenState();
}

class _DocumentEditScreenState extends ConsumerState<DocumentEditScreen> {
  DocumentTemplateType _selectedTemplate = DocumentTemplateType.governmentId;
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  
  // Gov ID
  final _govFullNameController = TextEditingController();
  final _govIdNumberController = TextEditingController();
  final _govDobController = TextEditingController();
  final _govIssueController = TextEditingController();
  final _govExpiryController = TextEditingController();

  // Credit Card
  final _ccNameController = TextEditingController();
  final _ccNumberController = TextEditingController();
  final _ccExpiryController = TextEditingController();
  final _ccCvvController = TextEditingController();

  // Bank
  final _bankNameController = TextEditingController();
  final _bankAccountNameController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _bankRoutingController = TextEditingController();

  File? _attachedFile;
  bool _isSaving = false;

  void _onTemplateChanged(DocumentTemplateType? value) {
    if (value != null) {
      setState(() {
        _selectedTemplate = value;
        if (_titleController.text.isEmpty || _isDefaultTitle()) {
          _titleController.text = _getDefaultTitle(value);
        }
      });
    }
  }

  bool _isDefaultTitle() {
    return DocumentTemplateType.values.map((e) => _getDefaultTitle(e)).contains(_titleController.text);
  }

  String _getDefaultTitle(DocumentTemplateType t) {
    switch (t) {
      case DocumentTemplateType.governmentId: return 'Government ID';
      case DocumentTemplateType.creditCard: return 'Credit Card';
      case DocumentTemplateType.bankAccount: return 'Bank Account';
      case DocumentTemplateType.custom: return 'Custom Document';
    }
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _attachedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      DocumentTemplate template;
      switch (_selectedTemplate) {
        case DocumentTemplateType.governmentId:
          template = GovernmentIdTemplate(
            title: _titleController.text,
            fullName: _govFullNameController.text,
            idNumber: _govIdNumberController.text,
            dateOfBirth: _govDobController.text,
            issueDate: _govIssueController.text.isNotEmpty ? _govIssueController.text : null,
            expirationDate: _govExpiryController.text,
          );
          break;
        case DocumentTemplateType.creditCard:
          template = CreditCardTemplate(
            title: _titleController.text,
            cardholderName: _ccNameController.text,
            cardNumber: _ccNumberController.text,
            expirationDate: _ccExpiryController.text,
            cvv: _ccCvvController.text,
          );
          break;
        case DocumentTemplateType.bankAccount:
          template = BankAccountTemplate(
            title: _titleController.text,
            bankName: _bankNameController.text,
            accountName: _bankAccountNameController.text,
            accountNumber: _bankAccountNumberController.text,
            routingNumber: _bankRoutingController.text,
          );
          break;
        case DocumentTemplateType.custom:
          template = CustomDocumentTemplate(
            title: _titleController.text,
            data: {},
          );
          break;
      }

      final notifier = ref.read(vaultListProvider.notifier);
      
      await notifier.importDocument(
        template: template,
        filePath: _attachedFile?.path,
      );
      
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'New Document',
        actions: [
          IconButton(
            icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
            onPressed: _isSaving ? null : _save,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<DocumentTemplateType>(
                  value: _selectedTemplate,
                  decoration: const InputDecoration(labelText: 'Document Type'),
                  items: DocumentTemplateType.values.map((t) {
                    return DropdownMenuItem(value: t, child: Text(_getDefaultTitle(t)));
                  }).toList(),
                  onChanged: _onTemplateChanged,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                if (_selectedTemplate == DocumentTemplateType.governmentId) ...[
                  TextFormField(
                    controller: _govFullNameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    autofillHints: const [AutofillHints.name],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _govIdNumberController,
                    decoration: const InputDecoration(labelText: 'ID Number'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _govIssueController,
                          decoration: const InputDecoration(labelText: 'Issued (MM/YY)'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _govExpiryController,
                          decoration: const InputDecoration(labelText: 'Expiry (MM/YY)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _govDobController,
                    decoration: const InputDecoration(labelText: 'Date of Birth'),
                    autofillHints: const [AutofillHints.birthday],
                  ),
                ] else if (_selectedTemplate == DocumentTemplateType.creditCard) ...[
                  TextFormField(
                    controller: _ccNameController,
                    decoration: const InputDecoration(labelText: 'Cardholder Name'),
                    autofillHints: const [AutofillHints.creditCardName],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ccNumberController,
                    decoration: const InputDecoration(labelText: 'Card Number'),
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.creditCardNumber],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ccExpiryController,
                          decoration: const InputDecoration(labelText: 'Expiry (MM/YY)'),
                          autofillHints: const [AutofillHints.creditCardExpirationDate],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _ccCvvController,
                          decoration: const InputDecoration(labelText: 'CVV'),
                          keyboardType: TextInputType.number,
                          autofillHints: const [AutofillHints.creditCardSecurityCode],
                        ),
                      ),
                    ],
                  ),
                ] else if (_selectedTemplate == DocumentTemplateType.bankAccount) ...[
                  TextFormField(
                    controller: _bankNameController,
                    decoration: const InputDecoration(labelText: 'Bank Name'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bankAccountNameController,
                    decoration: const InputDecoration(labelText: 'Account Holder Name'),
                    autofillHints: const [AutofillHints.name],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bankAccountNumberController,
                    decoration: const InputDecoration(labelText: 'Account Number'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bankRoutingController,
                    decoration: const InputDecoration(labelText: 'Routing Number'),
                    keyboardType: TextInputType.number,
                  ),
                ],

                const SizedBox(height: 32),
                const Text('Attachment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ListTile(
                  tileColor: AppTheme.surfaceVariant,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.attach_file),
                  title: Text(_attachedFile != null ? _attachedFile!.path.split(Platform.pathSeparator).last : 'No file attached'),
                  trailing: IconButton(
                    icon: Icon(_attachedFile != null ? Icons.edit : Icons.add),
                    onPressed: _pickAttachment,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
