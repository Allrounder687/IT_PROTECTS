import 'dart:convert';
import 'package:flutter/material.dart';

enum DocumentTemplateType {
  creditCard,
  bankAccount,
  governmentId,
  custom,
}

abstract class DocumentTemplate {
  final String title;
  final DocumentTemplateType type;
  final Map<String, dynamic> data;

  DocumentTemplate({
    required this.title,
    required this.type,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'type': type.name,
        'data': data,
      };

  String toJsonString() => jsonEncode(toJson());

  static DocumentTemplate fromJsonString(String jsonString) {
    if (jsonString.isEmpty) {
      return CustomDocumentTemplate(title: 'Unknown', data: {});
    }
    
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      final typeStr = map['type'] as String?;
      final type = DocumentTemplateType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => DocumentTemplateType.custom,
      );
      final title = map['title'] as String? ?? 'Document';
      final data = map['data'] as Map<String, dynamic>? ?? {};

      switch (type) {
        case DocumentTemplateType.creditCard:
          return CreditCardTemplate.fromData(title, data);
        case DocumentTemplateType.bankAccount:
          return BankAccountTemplate.fromData(title, data);
        case DocumentTemplateType.governmentId:
          return GovernmentIdTemplate.fromData(title, data);
        case DocumentTemplateType.custom:
          return CustomDocumentTemplate(title: title, data: data);
      }
    } catch (e) {
      return CustomDocumentTemplate(title: 'Invalid Data', data: {});
    }
  }

  // Helper for UI icons
  IconData get icon {
    switch (type) {
      case DocumentTemplateType.creditCard:
        return Icons.credit_card;
      case DocumentTemplateType.bankAccount:
        return Icons.account_balance;
      case DocumentTemplateType.governmentId:
        return Icons.badge;
      case DocumentTemplateType.custom:
        return Icons.description;
    }
  }
}

class CreditCardTemplate extends DocumentTemplate {
  CreditCardTemplate({
    required String title,
    required String cardholderName,
    required String cardNumber,
    required String expirationDate,
    required String cvv,
    String? pin,
    String? notes,
  }) : super(
          title: title,
          type: DocumentTemplateType.creditCard,
          data: {
            'cardholderName': cardholderName,
            'cardNumber': cardNumber,
            'expirationDate': expirationDate,
            'cvv': cvv,
            if (pin != null) 'pin': pin,
            if (notes != null) 'notes': notes,
          },
        );

  factory CreditCardTemplate.fromData(String title, Map<String, dynamic> data) {
    return CreditCardTemplate(
      title: title,
      cardholderName: data['cardholderName']?.toString() ?? '',
      cardNumber: data['cardNumber']?.toString() ?? '',
      expirationDate: data['expirationDate']?.toString() ?? '',
      cvv: data['cvv']?.toString() ?? '',
      pin: data['pin']?.toString(),
      notes: data['notes']?.toString(),
    );
  }

  String get cardholderName => data['cardholderName'] as String;
  String get cardNumber => data['cardNumber'] as String;
  String get expirationDate => data['expirationDate'] as String;
  String get cvv => data['cvv'] as String;
  String? get pin => data['pin'] as String?;
  String? get notes => data['notes'] as String?;
}

class GovernmentIdTemplate extends DocumentTemplate {
  GovernmentIdTemplate({
    required String title,
    required String fullName,
    required String idNumber,
    required String dateOfBirth,
    String? issueDate,
    required String expirationDate,
    String? address,
    String? notes,
  }) : super(
          title: title,
          type: DocumentTemplateType.governmentId,
          data: {
            'fullName': fullName,
            'idNumber': idNumber,
            'dateOfBirth': dateOfBirth,
            if (issueDate != null) 'issueDate': issueDate,
            'expirationDate': expirationDate,
            if (address != null) 'address': address,
            if (notes != null) 'notes': notes,
          },
        );

  factory GovernmentIdTemplate.fromData(String title, Map<String, dynamic> data) {
    return GovernmentIdTemplate(
      title: title,
      fullName: data['fullName']?.toString() ?? '',
      idNumber: data['idNumber']?.toString() ?? '',
      dateOfBirth: data['dateOfBirth']?.toString() ?? '',
      issueDate: data['issueDate']?.toString(),
      expirationDate: data['expirationDate']?.toString() ?? '',
      address: data['address']?.toString(),
      notes: data['notes']?.toString(),
    );
  }
}

class BankAccountTemplate extends DocumentTemplate {
  BankAccountTemplate({
    required String title,
    required String bankName,
    required String accountName,
    required String accountNumber,
    required String routingNumber,
    String? swiftBic,
    String? notes,
  }) : super(
          title: title,
          type: DocumentTemplateType.bankAccount,
          data: {
            'bankName': bankName,
            'accountName': accountName,
            'accountNumber': accountNumber,
            'routingNumber': routingNumber,
            if (swiftBic != null) 'swiftBic': swiftBic,
            if (notes != null) 'notes': notes,
          },
        );

  factory BankAccountTemplate.fromData(String title, Map<String, dynamic> data) {
    return BankAccountTemplate(
      title: title,
      bankName: data['bankName']?.toString() ?? '',
      accountName: data['accountName']?.toString() ?? '',
      accountNumber: data['accountNumber']?.toString() ?? '',
      routingNumber: data['routingNumber']?.toString() ?? '',
      swiftBic: data['swiftBic']?.toString(),
      notes: data['notes']?.toString(),
    );
  }
}

class CustomDocumentTemplate extends DocumentTemplate {
  CustomDocumentTemplate({
    required String title,
    required Map<String, dynamic> data,
  }) : super(
          title: title,
          type: DocumentTemplateType.custom,
          data: data,
        );
}
