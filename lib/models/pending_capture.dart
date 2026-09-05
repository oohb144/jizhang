class PendingCapture {
  final int? id;
  final double amount;
  final String direction;
  final String channel;
  final String? merchant;
  final double confidence;
  final String sourcePackage;
  final String sourceFingerprint;
  final DateTime receivedAt;
  final String status;

  const PendingCapture({
    this.id,
    required this.amount,
    required this.direction,
    required this.channel,
    this.merchant,
    required this.confidence,
    required this.sourcePackage,
    required this.sourceFingerprint,
    required this.receivedAt,
    this.status = 'pending',
  });

  bool get isExpense => direction == 'expense';
  bool get isIncome => direction == 'income';

  factory PendingCapture.fromNativeMap(Map<Object?, Object?> map) {
    return PendingCapture(
      amount: (map['amount'] as num).toDouble(),
      direction: map['direction'] as String,
      channel: map['channel'] as String,
      merchant: map['merchant'] as String?,
      confidence: (map['confidence'] as num).toDouble(),
      sourcePackage: map['sourcePackage'] as String,
      sourceFingerprint: map['sourceFingerprint'] as String,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['receivedAt'] as num).toInt(),
      ),
    );
  }

  factory PendingCapture.fromMap(Map<String, Object?> map) {
    return PendingCapture(
      id: map['id'] as int?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      direction: map['direction'] as String? ?? 'expense',
      channel: map['payment_channel'] as String? ?? 'other',
      merchant: map['merchant'] as String?,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
      sourcePackage: map['source_package'] as String,
      sourceFingerprint: map['source_fingerprint'] as String,
      receivedAt: DateTime.parse(map['received_at'] as String),
      status: map['status'] as String? ?? 'pending',
    );
  }

  Map<String, Object?> toDatabaseMap() => {
        'amount': amount,
        'merchant': merchant,
        'payment_channel': channel,
        'direction': direction,
        'confidence': confidence,
        'source_package': sourcePackage,
        'source_fingerprint': sourceFingerprint,
        'received_at': receivedAt.toIso8601String(),
        'status': status,
      };
}
