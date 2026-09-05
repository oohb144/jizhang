class MerchantRule {
  final int? id;
  final String merchantPattern;
  final int categoryId;
  final int? accountId;
  final String? paymentChannel;
  final int priority;
  final bool learnedFromUser;
  final bool enabled;

  const MerchantRule({
    this.id,
    required this.merchantPattern,
    required this.categoryId,
    this.accountId,
    this.paymentChannel,
    this.priority = 0,
    this.learnedFromUser = false,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'merchant_pattern': merchantPattern,
        'category_id': categoryId,
        'account_id': accountId,
        'payment_channel': paymentChannel,
        'priority': priority,
        'learned_from_user': learnedFromUser ? 1 : 0,
        'enabled': enabled ? 1 : 0,
      };

  factory MerchantRule.fromMap(Map<String, dynamic> map) {
    return MerchantRule(
      id: map['id'] as int?,
      merchantPattern: map['merchant_pattern'] as String,
      categoryId: map['category_id'] as int,
      accountId: map['account_id'] as int?,
      paymentChannel: map['payment_channel'] as String?,
      priority: map['priority'] as int? ?? 0,
      learnedFromUser: _readBool(map['learned_from_user']),
      enabled: map['enabled'] == null ? true : _readBool(map['enabled']),
    );
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return false;
  }
}
