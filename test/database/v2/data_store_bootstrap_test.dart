import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang/database/v2/data_store_bootstrap.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('initializes an empty v2 database when legacy json is absent', () async {
    final result = await DataStoreBootstrap.initialize(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );

    expect(result.migration.migrated, isFalse);
    expect(await result.database.db.query('accounts'), isEmpty);
    await result.database.close();
  });

  test('migrates legacy json during bootstrap and preserves the file', () async {
    final dir = await Directory.systemTemp.createTemp('jizhang_bootstrap_');
    final source = File('${dir.path}/data.json');
    final text = jsonEncode({
      'accounts': [
        {'id': 1, 'name': '微信', 'balance': 88.0, 'icon': 'wechat'},
      ],
      'categories': [],
      'budgets': [],
      'category_budgets': [],
      'transactions': [],
    });
    await source.writeAsString(text);

    final result = await DataStoreBootstrap.initialize(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
      legacyJsonFile: source,
    );

    expect(result.migration.migrated, isTrue);
    expect((await result.database.db.query('accounts')).length, 1);
    expect(await source.readAsString(), text);

    await result.database.close();
    await dir.delete(recursive: true);
  });

  test('closes database and leaves legacy file untouched when migration fails', () async {
    final dir = await Directory.systemTemp.createTemp('jizhang_bootstrap_bad_');
    final source = File('${dir.path}/data.json');
    const invalid = '{"accounts":"not-a-list"}';
    await source.writeAsString(invalid);

    await expectLater(
      DataStoreBootstrap.initialize(
        factory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
        legacyJsonFile: source,
      ),
      throwsA(isA<FormatException>()),
    );
    expect(await source.readAsString(), invalid);

    await dir.delete(recursive: true);
  });
}
