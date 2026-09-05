import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang/database/v2/app_database.dart';
import 'package:jizhang/database/v2/account_repository.dart';
import 'package:jizhang/database/v2/transaction_repository.dart';
import 'package:jizhang/models/account.dart';
import 'package:jizhang/models/transaction.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabaseV2 database;
  late AccountRepository accounts;
  late TransactionRepository transactions;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await AppDatabaseV2.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    accounts = AccountRepository(database.db);
    transactions = TransactionRepository(database.db);
  });

  tearDown(() async {
    await database.close();
  });

  test('schema creates all phase 1 core tables', () async {
    final tables = await database.db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final names = tables.map((row) => row['name']).whereType<String>().toSet();

    expect(names, containsAll(<String>{
      'metadata',
      'accounts',
      'categories',
      'budgets',
      'category_budgets',
      'ledger_transactions',
      'merchant_rules',
      'pending_captures',
    }));
  });

  test('editing and deleting a transaction recalculates derived balance', () async {
    final accountId = await accounts.insert(Account(
      name: '微信',
      type: AccountType.wechat,
      openingBalance: 1000,
      manualAdjustment: 0,
    ));

    final transactionId = await transactions.insert(Transaction(
      accountId: accountId,
      amount: 100,
      type: TransactionType.expense,
      category: '餐饮',
      transactionDate: DateTime(2026, 9, 5),
    ));

    expect(await accounts.derivedBalance(accountId), 900);

    await transactions.update(Transaction(
      id: transactionId,
      accountId: accountId,
      amount: 40,
      type: TransactionType.expense,
      category: '餐饮',
      transactionDate: DateTime(2026, 9, 5),
    ));

    expect(await accounts.derivedBalance(accountId), 960);

    await transactions.delete(transactionId);
    expect(await accounts.derivedBalance(accountId), 1000);
  });

  test('owned-account transfer moves balance without creating income or expense', () async {
    final fromId = await accounts.insert(Account(
      name: '微信',
      type: AccountType.wechat,
      openingBalance: 500,
    ));
    final toId = await accounts.insert(Account(
      name: '工商银行',
      type: AccountType.bankCard,
      openingBalance: 1000,
    ));

    await transactions.insert(Transaction(
      accountId: fromId,
      destinationAccountId: toId,
      amount: 120,
      type: TransactionType.transfer,
      category: '转账',
      transactionDate: DateTime(2026, 9, 5),
    ));

    expect(await accounts.derivedBalance(fromId), 380);
    expect(await accounts.derivedBalance(toId), 1120);

    final summary = await transactions.monthSummary(2026, 9);
    expect(summary.income, 0);
    expect(summary.expense, 0);
  });
}
