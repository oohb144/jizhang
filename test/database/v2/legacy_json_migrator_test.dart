import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang/database/v2/app_database.dart';
import 'package:jizhang/database/v2/legacy_json_migrator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('migrates legacy JSON once and preserves the source file', () async {
    final database = await AppDatabaseV2.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    final tempDir = await Directory.systemTemp.createTemp('jizhang_migration_');
    final source = File('${tempDir.path}/data.json');
    final original = jsonEncode({
      'accounts': [
        {'id': 1, 'name': '微信', 'balance': 300.0, 'icon': 'wechat'},
        {'id': 2, 'name': '支付宝', 'balance': 500.0, 'icon': 'alipay'},
      ],
      'categories': [
        {'id': 1, 'name': '餐饮', 'parent_name': null, 'icon': 'restaurant', 'sort_order': 0},
      ],
      'budgets': [
        {'id': 1, 'month': '2026-09', 'total_amount': 1000.0, 'daily_amount': 33.0},
      ],
      'category_budgets': [
        {'id': 1, 'month': '2026-09', 'category_name': '餐饮', 'budget_amount': 500.0, 'used_amount': 18.5},
      ],
      'transactions': [
        {
          'id': 1,
          'account_id': 1,
          'amount': -18.5,
          'category': '餐饮',
          'transaction_date': '2026-09-05T12:00:00.000'
        },
        {
          'id': 2,
          'account_id': 2,
          'amount': 200.0,
          'category': '工资',
          'transaction_date': '2026-09-05T13:00:00.000'
        },
      ],
    });
    await source.writeAsString(original);

    final migrator = LegacyJsonMigrator(database.db);
    final first = await migrator.migrateIfNeeded(source);
    final second = await migrator.migrateIfNeeded(source);

    expect(first.migrated, isTrue);
    expect(first.accountCount, 2);
    expect(first.transactionCount, 2);
    expect(second.migrated, isFalse);

    expect((await database.db.query('accounts')).length, 2);
    expect((await database.db.query('categories')).length, 1);
    expect((await database.db.query('budgets')).length, 1);
    expect((await database.db.query('category_budgets')).length, 1);
    expect((await database.db.query('ledger_transactions')).length, 2);

    final transactions = await database.db.query(
      'ledger_transactions',
      orderBy: 'id ASC',
    );
    expect(transactions[0]['type'], 'expense');
    expect(transactions[1]['type'], 'income');
    expect(await source.readAsString(), original);

    await database.close();
    await tempDir.delete(recursive: true);
  });

  test('rolls back all inserts when migration data is invalid', () async {
    final database = await AppDatabaseV2.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    final tempDir = await Directory.systemTemp.createTemp('jizhang_bad_migration_');
    final source = File('${tempDir.path}/data.json');
    await source.writeAsString(jsonEncode({
      'accounts': [
        {'id': 1, 'name': '微信', 'balance': 100.0},
      ],
      'categories': [],
      'budgets': [],
      'category_budgets': [],
      'transactions': [
        {'id': 1, 'account_id': 99, 'amount': -5.0, 'category': '餐饮', 'transaction_date': '2026-09-05T12:00:00.000'},
      ],
    }));

    final migrator = LegacyJsonMigrator(database.db);

    await expectLater(
      migrator.migrateIfNeeded(source),
      throwsA(isA<Object>()),
    );
    expect(await database.db.query('accounts'), isEmpty);
    expect(await database.db.query('ledger_transactions'), isEmpty);
    expect(
      await database.db.query(
        'metadata',
        where: 'key = ?',
        whereArgs: ['legacy_json_migration_v1'],
      ),
      isEmpty,
    );

    await database.close();
    await tempDir.delete(recursive: true);
  });
}
