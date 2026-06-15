class Budget {
  final int? id;
  final String month;
  final double totalAmount;
  final double? dailyAmount;
  final DateTime? createdAt;

  Budget({
    this.id,
    required this.month,
    required this.totalAmount,
    this.dailyAmount,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'month': month,
      'total_amount': totalAmount,
      'daily_amount': dailyAmount,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      month: map['month'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      dailyAmount: map['daily_amount'] != null ? (map['daily_amount'] as num).toDouble() : null,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }
}
