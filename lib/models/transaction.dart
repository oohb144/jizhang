class Transaction {
  final int? id;
  final int accountId;
  final double amount;
  final String category;
  final String? subcategory;
  final String? note;
  final DateTime transactionDate;
  final DateTime? createdAt;

  Transaction({
    this.id,
    required this.accountId,
    required this.amount,
    required this.category,
    this.subcategory,
    this.note,
    required this.transactionDate,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'amount': amount,
      'category': category,
      'subcategory': subcategory,
      'note': note,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      subcategory: map['subcategory'] as String?,
      note: map['note'] as String?,
      transactionDate: DateTime.parse(map['transaction_date']),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }
}
