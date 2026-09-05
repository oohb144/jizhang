import '../models/account.dart';
import '../models/transaction.dart';

class LedgerBalanceCalculator {
  const LedgerBalanceCalculator._();

  static double balanceForAccount({
    required Account account,
    required Iterable<Transaction> transactions,
  }) {
    var balance = account.openingBalance + account.manualAdjustment;

    for (final transaction in transactions) {
      switch (transaction.type) {
        case TransactionType.expense:
          if (transaction.accountId == account.id) {
            balance -= transaction.amount.abs();
          }
          break;
        case TransactionType.income:
          if (transaction.accountId == account.id) {
            balance += transaction.amount.abs();
          }
          break;
        case TransactionType.transfer:
          if (transaction.accountId == account.id) {
            balance -= transaction.amount.abs();
          }
          if (transaction.destinationAccountId == account.id) {
            balance += transaction.amount.abs();
          }
          break;
        case TransactionType.adjustment:
          if (transaction.accountId == account.id) {
            balance += transaction.amount;
          }
          break;
      }
    }

    return balance;
  }
}
