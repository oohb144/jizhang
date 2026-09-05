enum AccountType {
  cash,
  wechat,
  alipay,
  bankCard,
  creditCard,
  campusCard,
  other,
}

class Account {
  final int? id;
  final String name;

  /// Legacy field kept for backward compatibility with the current UI/data.
  /// V2 balance views should prefer [openingBalance] + ledger history.
  final double balance;
  final AccountType type;
  final double openingBalance;
  final double manualAdjustment;
  final String currency;
  final String? icon;
  final bool isArchived;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Account({
    this.id,
    required this.name,
    double? balance,
    this.type = AccountType.other,
    double? openingBalance,
    this.manualAdjustment = 0,
    this.currency = 'CNY',
    this.icon,
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
  })  : openingBalance = openingBalance ?? balance ?? 0,
        balance = balance ?? openingBalance ?? 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'type': type.name,
      'opening_balance': openingBalance,
      'manual_adjustment': manualAdjustment,
      'currency': currency,
      'icon': icon,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    final legacyBalance = (map['balance'] as num?)?.toDouble() ?? 0;
    final rawType = map['type'] as String?;

    return Account(
      id: map['id'] as int?,
      name: map['name'] as String,
      balance: legacyBalance,
      type: AccountType.values.firstWhere(
        (value) => value.name == rawType,
        orElse: () => _inferLegacyType(map['name'] as String),
      ),
      openingBalance:
          (map['opening_balance'] as num?)?.toDouble() ?? legacyBalance,
      manualAdjustment:
          (map['manual_adjustment'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'CNY',
      icon: map['icon'] as String?,
      isArchived: _readBool(map['is_archived']),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  static AccountType _inferLegacyType(String name) {
    if (name.contains('微信')) return AccountType.wechat;
    if (name.contains('支付宝')) return AccountType.alipay;
    if (name.contains('现金')) return AccountType.cash;
    if (name.contains('校园')) return AccountType.campusCard;
    if (name.contains('信用卡')) return AccountType.creditCard;
    if (name.contains('银行') || name.contains('卡')) return AccountType.bankCard;
    return AccountType.other;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return false;
  }
}
