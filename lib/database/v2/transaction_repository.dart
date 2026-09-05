import 'package:sqflite/sqflite.dart' hide Transaction;

import '../../models/transaction.dart';

class MonthSummary {
  final double income;
  final double expense;

  const MonthSummary({required this.income, required this.expense});

  double get net => income - expense;
}

class TransactionRepository {
  final Database db;

  TransactionRepository(this.db);

  Future<int> insert(Transaction transaction) {
    return db.insert('ledger_transactions', _toRow(transaction));
  }

  Future<int> update(Transaction transaction) {
    if (transaction.id == null) {
      throw ArgumentError('Transaction id is required for update');
    }
    return db.update(
      'ledger_transactions',
      _toRow(transaction),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> delete(int id) {
    return db.delete(
      'ledger_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Transaction>> getByMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final rows = await db.query(
      'ledger_transactions',
      where: 'transaction_date >= ? AND transaction_date < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'transaction_date DESC, id DESC',
    );
    return rows.map(Transaction.fromMap).toList();
  }

  Future<MonthSummary> monthSummary(int year, int month) async {
    final transactions = await getByMonth(year, month);
    var income = 0.0;
    var expense = 0.0;

    for (final transaction in transactions) {
      switch (transaction.type) {
        case TransactionType.income:
          income += transaction.amount.abs();
          break;
        case TransactionType.expense:
          expense += transaction.amount.abs();
          break;
        case TransactionType.transfer:
        case TransactionType.adjustment:
          break;
      }
    }

    return MonthSummary(income: income, expense: expense);
  }

  Map<String, Object?> _toRow(Transaction transaction) => {
        if (transaction.id != null) 'id': transaction.id,
        'account_id': transaction.accountId,
        'destination_account_id': transaction.destinationAccountId,
        'amount': transaction.amount,
        'type': transaction.type.name,
        'category': transaction.category,
        'subcategory': transaction.subcategory,
        'category_id': transaction.categoryId,
        'merchant': transaction.merchant,
        'payment_channel': transaction.paymentChannel,
        'note': transaction.note,
        'source': transaction.source.name,
        'auto_detected': transaction.autoDetected ? 1 : 0,
        'confidence': transaction.confidence,
        'source_fingerprint': transaction.sourceFingerprint,
        'raw_source_id': transaction.rawSourceId,
        'transaction_date': transaction.transactionDate.toIso8601String(),
        'created_at': transaction.createdAt?.toIso8601String(),
        'updated_at': transaction.updatedAt?.toIso8601String(),
      };
}
