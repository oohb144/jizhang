import '../../models/account.dart';

class AccountMatcher {
  const AccountMatcher();

  Account? match(List<Account> accounts, String channel) {
    switch (channel) {
      case 'wechat':
        return _first(accounts, AccountType.wechat, '微信');
      case 'alipay':
        return _first(accounts, AccountType.alipay, '支付宝');
      case 'bank':
      case 'unionpay':
        final bankAccounts = accounts.where((account) {
          return account.type == AccountType.bankCard ||
              account.type == AccountType.creditCard;
        }).toList();
        return bankAccounts.length == 1 ? bankAccounts.first : null;
      default:
        return null;
    }
  }

  Account? _first(List<Account> accounts, AccountType type, String nameHint) {
    for (final account in accounts) {
      if (account.type == type) return account;
    }
    for (final account in accounts) {
      if (account.name.contains(nameHint)) return account;
    }
    return null;
  }
}
