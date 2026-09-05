import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang/models/transaction.dart';

void main() {
  test('legacy negative amount is inferred as expense', () {
    final transaction = Transaction.fromMap({
      'id': 1,
      'account_id': 1,
      'amount': -18.5,
      'category': '餐饮',
      'transaction_date': '2026-09-05T12:00:00.000',
    });

    expect(transaction.type, TransactionType.expense);
  });

  test('legacy positive amount is inferred as income', () {
    final transaction = Transaction.fromMap({
      'id': 2,
      'account_id': 1,
      'amount': 200.0,
      'category': '工资',
      'transaction_date': '2026-09-05T13:00:00.000',
    });

    expect(transaction.type, TransactionType.income);
  });
}
