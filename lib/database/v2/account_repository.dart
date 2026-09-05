import 'package:sqflite/sqflite.dart' hide Transaction;

import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../services/ledger_balance_calculator.dart';

class AccountRepository {
  final Database db;

  AccountRepository(this.db);

  Future<int> insert(Account account) {
    return db.insert('accounts', _toRow(account));
  }

  Future<List<Account>> getAll({bool includeArchived = false}) async {
    final rows = await db.query(
      'accounts',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'id ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<Account?> getById(int id) async {
    final rows = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  Future<int> update(Account account) {
    if (account.id == null) {
      throw ArgumentError('Account id is required for update');
    }
    return db.update(
      'accounts',
      _toRow(account),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<double> balanceForAccount(int accountId) => derivedBalance(accountId);

  Future<double> derivedBalance(int accountId) async {
    final account = await getById(accountId);
    if (account == null) {
      throw StateError('Account $accountId does not exist');
    }

    final rows = await db.query(
      'ledger_transactions',
      where: 'account_id = ? OR destination_account_id = ?',
      whereArgs: [accountId, accountId],
      orderBy: 'transaction_date ASC, id ASC',
    );

    final transactions = rows.map(Transaction.fromMap);
    return LedgerBalanceCalculator.balanceForAccount(
      account: account,
      transactions: transactions,
    );
  }

  Future<double> totalAssets() async {
    final accounts = await getAll();
    var total = 0.0;
    for (final account in accounts) {
      total += await derivedBalance(account.id!);
    }
    return total;
  }

  Map<String, Object?> _toRow(Account account) => {
        if (account.id != null) 'id': account.id,
        'name': account.name,
        'type': account.type.name,
        'opening_balance': account.openingBalance,
        'manual_adjustment': account.manualAdjustment,
        'currency': account.currency,
        'icon': account.icon,
        'is_archived': account.isArchived ? 1 : 0,
        'created_at': account.createdAt?.toIso8601String(),
        'updated_at': account.updatedAt?.toIso8601String(),
      };

  Account _fromRow(Map<String, Object?> row) {
    return Account.fromMap({
      ...row,
      'balance': row['opening_balance'],
    });
  }
}
