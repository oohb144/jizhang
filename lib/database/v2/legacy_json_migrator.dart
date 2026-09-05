import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

class MigrationResult {
  final bool migrated;
  final int accountCount;
  final int transactionCount;

  const MigrationResult({
    required this.migrated,
    required this.accountCount,
    required this.transactionCount,
  });
}

class LegacyJsonMigrator {
  static const migrationKey = 'legacy_json_migration_v1';

  final Database db;

  LegacyJsonMigrator(this.db);

  Future<MigrationResult> migrateIfNeeded(File source) async {
    final completed = await db.query(
      'metadata',
      where: 'key = ?',
      whereArgs: [migrationKey],
      limit: 1,
    );
    if (completed.isNotEmpty) {
      return const MigrationResult(
        migrated: false,
        accountCount: 0,
        transactionCount: 0,
      );
    }

    if (!await source.exists()) {
      return const MigrationResult(
        migrated: false,
        accountCount: 0,
        transactionCount: 0,
      );
    }

    final originalText = await source.readAsString();
    final decoded = jsonDecode(originalText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Legacy data root must be an object');
    }

    final accounts = _rows(decoded, 'accounts');
    final categories = _rows(decoded, 'categories');
    final budgets = _rows(decoded, 'budgets');
    final categoryBudgets = _rows(decoded, 'category_budgets');
    final transactions = _rows(decoded, 'transactions');

    final netImpactByAccount = <int, double>{};
    for (final transaction in transactions) {
      final accountId = _requiredInt(transaction, 'account_id');
      final amount = _requiredNum(transaction, 'amount').toDouble();
      netImpactByAccount[accountId] =
          (netImpactByAccount[accountId] ?? 0) + amount;
    }

    await db.transaction((txn) async {
      for (final account in accounts) {
        final id = _requiredInt(account, 'id');
        final currentBalance = _requiredNum(account, 'balance').toDouble();
        final openingBalance =
            currentBalance - (netImpactByAccount[id] ?? 0.0);
        await txn.insert('accounts', {
          'id': id,
          'name': _requiredString(account, 'name'),
          'type': _inferAccountType(_requiredString(account, 'name')),
          'opening_balance': openingBalance,
          'manual_adjustment': 0.0,
          'currency': 'CNY',
          'icon': account['icon'] as String?,
          'is_archived': 0,
          'created_at': account['created_at'] as String?,
          'updated_at': account['updated_at'] as String?,
        });
      }

      for (final category in categories) {
        await txn.insert('categories', {
          'id': _requiredInt(category, 'id'),
          'name': _requiredString(category, 'name'),
          'parent_name': category['parent_name'] as String?,
          'icon': (category['icon'] as String?) ?? 'more_horiz',
          'sort_order': (category['sort_order'] as num?)?.toInt() ?? 0,
          'type': (category['type'] as String?) ?? 'expense',
        });
      }

      for (final budget in budgets) {
        await txn.insert('budgets', {
          'id': _requiredInt(budget, 'id'),
          'month': _requiredString(budget, 'month'),
          'total_amount': _requiredNum(budget, 'total_amount').toDouble(),
          'daily_amount': (budget['daily_amount'] as num?)?.toDouble(),
          'created_at': budget['created_at'] as String?,
        });
      }

      for (final item in categoryBudgets) {
        await txn.insert('category_budgets', {
          'id': _requiredInt(item, 'id'),
          'month': _requiredString(item, 'month'),
          'category_name': _requiredString(item, 'category_name'),
          'budget_amount': _requiredNum(item, 'budget_amount').toDouble(),
          'used_amount': (item['used_amount'] as num?)?.toDouble() ?? 0.0,
          'created_at': item['created_at'] as String?,
        });
      }

      for (final transaction in transactions) {
        final accountId = _requiredInt(transaction, 'account_id');
        final amount = _requiredNum(transaction, 'amount').toDouble();
        await txn.insert('ledger_transactions', {
          'id': _requiredInt(transaction, 'id'),
          'account_id': accountId,
          'destination_account_id': null,
          'amount': amount.abs(),
          'type': amount < 0 ? 'expense' : 'income',
          'category': (transaction['category'] as String?) ?? '其他',
          'subcategory': transaction['subcategory'] as String?,
          'category_id': null,
          'merchant': null,
          'payment_channel': null,
          'note': transaction['note'] as String?,
          'source': 'import',
          'auto_detected': 0,
          'confidence': null,
          'source_fingerprint': null,
          'raw_source_id': null,
          'transaction_date': _requiredString(transaction, 'transaction_date'),
          'created_at': transaction['created_at'] as String?,
          'updated_at': null,
        });
      }

      await _validateCounts(
        txn,
        accountCount: accounts.length,
        categoryCount: categories.length,
        budgetCount: budgets.length,
        categoryBudgetCount: categoryBudgets.length,
        transactionCount: transactions.length,
      );

      await txn.insert('metadata', {
        'key': migrationKey,
        'value': DateTime.now().toUtc().toIso8601String(),
      });
    });

    return MigrationResult(
      migrated: true,
      accountCount: accounts.length,
      transactionCount: transactions.length,
    );
  }

  List<Map<String, dynamic>> _rows(Map<String, dynamic> root, String key) {
    final value = root[key];
    if (value == null) return <Map<String, dynamic>>[];
    if (value is! List) {
      throw FormatException('$key must be a list');
    }
    return value.map((row) {
      if (row is! Map) throw FormatException('$key contains a non-object row');
      return Map<String, dynamic>.from(row);
    }).toList();
  }

  Future<void> _validateCounts(
    Transaction txn, {
    required int accountCount,
    required int categoryCount,
    required int budgetCount,
    required int categoryBudgetCount,
    required int transactionCount,
  }) async {
    final checks = <String, int>{
      'accounts': accountCount,
      'categories': categoryCount,
      'budgets': budgetCount,
      'category_budgets': categoryBudgetCount,
      'ledger_transactions': transactionCount,
    };
    for (final entry in checks.entries) {
      final result = await txn.rawQuery('SELECT COUNT(*) AS c FROM ${entry.key}');
      final count = Sqflite.firstIntValue(result) ?? 0;
      if (count != entry.value) {
        throw StateError(
          'Migration validation failed for ${entry.key}: $count != ${entry.value}',
        );
      }
    }
  }

  int _requiredInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is num) return value.toInt();
    throw FormatException('$key must be an integer');
  }

  num _requiredNum(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is num) return value;
    throw FormatException('$key must be numeric');
  }

  String _requiredString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('$key must be a non-empty string');
  }

  String _inferAccountType(String name) {
    if (name.contains('微信')) return 'wechat';
    if (name.contains('支付宝')) return 'alipay';
    if (name.contains('现金')) return 'cash';
    if (name.contains('校园')) return 'campusCard';
    if (name.contains('信用卡')) return 'creditCard';
    if (name.contains('银行') || name.contains('卡')) return 'bankCard';
    return 'other';
  }
}
