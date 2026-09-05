enum TransactionType { expense, income, transfer, adjustment }

enum TransactionSource { manual, notification, import }

class Transaction {
  final int? id;
  final int accountId;
  final int? destinationAccountId;
  final double amount;
  final TransactionType type;
  final String category;
  final String? subcategory;
  final int? categoryId;
  final String? merchant;
  final String? paymentChannel;
  final String? note;
  final TransactionSource source;
  final bool autoDetected;
  final double? confidence;
  final String? sourceFingerprint;
  final String? rawSourceId;
  final DateTime transactionDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Transaction({
    this.id,
    required this.accountId,
    this.destinationAccountId,
    required this.amount,
    this.type = TransactionType.expense,
    required this.category,
    this.subcategory,
    this.categoryId,
    this.merchant,
    this.paymentChannel,
    this.note,
    this.source = TransactionSource.manual,
    this.autoDetected = false,
    this.confidence,
    this.sourceFingerprint,
    this.rawSourceId,
    required this.transactionDate,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'destination_account_id': destinationAccountId,
      'amount': amount,
      'type': type.name,
      'category': category,
      'subcategory': subcategory,
      'category_id': categoryId,
      'merchant': merchant,
      'payment_channel': paymentChannel,
      'note': note,
      'source': source.name,
      'auto_detected': autoDetected ? 1 : 0,
      'confidence': confidence,
      'source_fingerprint': sourceFingerprint,
      'raw_source_id': rawSourceId,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    final rawType = map['type'] as String?;
    final rawSource = map['source'] as String?;

    return Transaction(
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      destinationAccountId: map['destination_account_id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (value) => value.name == rawType,
        orElse: () => _inferLegacyType((map['amount'] as num).toDouble()),
      ),
      category: map['category'] as String? ?? '其他',
      subcategory: map['subcategory'] as String?,
      categoryId: map['category_id'] as int?,
      merchant: map['merchant'] as String?,
      paymentChannel: map['payment_channel'] as String?,
      note: map['note'] as String?,
      source: TransactionSource.values.firstWhere(
        (value) => value.name == rawSource,
        orElse: () => TransactionSource.manual,
      ),
      autoDetected: _readBool(map['auto_detected']),
      confidence: (map['confidence'] as num?)?.toDouble(),
      sourceFingerprint: map['source_fingerprint'] as String?,
      rawSourceId: map['raw_source_id'] as String?,
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  static TransactionType _inferLegacyType(double amount) {
    return amount < 0 ? TransactionType.income : TransactionType.expense;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return false;
  }
}
