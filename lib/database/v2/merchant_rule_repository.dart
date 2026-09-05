import 'package:sqflite/sqflite.dart';

import '../../models/merchant_rule.dart';

class MerchantRuleRepository {
  final Database db;

  MerchantRuleRepository(this.db);

  Future<int> insert(MerchantRule rule) {
    return db.insert('merchant_rules', rule.toMap()..remove('id'));
  }

  Future<List<MerchantRule>> getEnabled() async {
    final rows = await db.query(
      'merchant_rules',
      where: 'enabled = 1',
      orderBy: 'priority DESC, id ASC',
    );
    return rows.map(MerchantRule.fromMap).toList();
  }

  Future<MerchantRule?> match(String merchant) async {
    final normalized = merchant.trim().toLowerCase();
    final rules = await getEnabled();

    for (final rule in rules) {
      if (normalized.contains(rule.merchantPattern.trim().toLowerCase())) {
        return rule;
      }
    }
    return null;
  }
}
