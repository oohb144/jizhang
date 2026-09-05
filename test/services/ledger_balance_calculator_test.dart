import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang/models/account.dart';
import 'package:jizhang/models/transaction.dart';
import 'package:jizhang/services/ledger_balance_calculator.dart';

void main() {
  group('LedgerBalanceCalculator', () {
    final account = Account(
      id: 1,
      name: '微信',
      type: AccountType.wechat,
      openingBalance: 1000,
      manualAdjustment: 50,
      currency: 'CNY',
    );

    test('applies income, expense, transfers and adjustments correctly', () {
      final transactions = <Transaction>[
        Transaction(
          accountId: 1,
          amount: 200,
          type: TransactionType.income,
          category: '工资',
          transactionDate: DateTime(2026, 9, 1),
        ),
        Transaction(
          accountId: 1,
          amount: 80,
          type: TransactionType.expense,
          category: '餐饮',
          transactionDate: DateTime(2026, 9, 2),
        ),
        Transaction(
          accountId: 1,
          destinationAccountId: 2,
          amount: 120,
          type: TransactionType.transfer,
          category: '转账',
          transactionDate: DateTime(2026, 9, 3),
        ),
        Transaction(
          accountId: 2,
          destinationAccountId: 1,
          amount: 30,
          type: TransactionType.transfer,
          category: '转账',
          transactionDate: DateTime(2026, 9, 4),
        ),
        Transaction(
          accountId: 1,
          amount: 20,
          type: TransactionType.adjustment,
          category: '余额调整',
          transactionDate: DateTime(2026, 9, 5),
        ),
      ];

      final result = LedgerBalanceCalculator.balanceForAccount(
        account: account,
        transactions: transactions,
      );

      expect(result, 1100);
    });

    test('ignores transactions unrelated to the account', () {
      final transactions = <Transaction>[
        Transaction(
          accountId: 2,
          amount: 999,
          type: TransactionType.expense,
          category: '购物',
          transactionDate: DateTime(2026, 9, 1),
        ),
      ];

      final result = LedgerBalanceCalculator.balanceForAccount(
        account: account,
        transactions: transactions,
      );

      expect(result, 1050);
    });
  });
}
