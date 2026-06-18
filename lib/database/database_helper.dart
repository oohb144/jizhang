import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/account.dart';
import '../models/transaction.dart' as model;
import '../models/budget.dart';
import '../models/category.dart';
import '../models/category_budget.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static const String _dirName = 'jizhang_data';

  Map<String, List<Map<String, dynamic>>> _data = {
    'accounts': [],
    'transactions': [],
    'budgets': [],
    'categories': [],
    'category_budgets': [],
  };

  bool _initialized = false;

  DatabaseHelper._init();

  Future<Directory> get _dataDir async {
    Directory baseDir;
    if (Platform.isAndroid || Platform.isIOS) {
      baseDir = await getApplicationDocumentsDirectory();
    } else {
      final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
      baseDir = Directory(home);
    }
    final dir = Directory('${baseDir.path}/$_dirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;

    final dir = await _dataDir;
    final file = File('${dir.path}/data.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      _data = decoded.map((key, value) =>
          MapEntry(key, (value as List).cast<Map<String, dynamic>>()));
    } else {
      await _insertDefaultData();
      await _save();
    }
  }

  Future<void> _save() async {
    final dir = await _dataDir;
    final file = File('${dir.path}/data.json');
    await file.writeAsString(jsonEncode(_data));
  }

  int _nextId(String table) {
    final list = _data[table] ?? [];
    if (list.isEmpty) return 1;
    return list.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<void> _insertDefaultData() async {
    _data['accounts'] = [
      {
        'id': 1,
        'name': '微信',
        'balance': 0.0,
        'icon': 'wechat',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 2,
        'name': '支付宝',
        'balance': 0.0,
        'icon': 'alipay',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    ];

    _data['categories'] = [
      {'id': 1, 'name': '餐饮', 'parent_name': null, 'icon': 'restaurant', 'sort_order': 0},
      {'id': 2, 'name': '早餐', 'parent_name': '餐饮', 'icon': 'free_breakfast', 'sort_order': 1},
      {'id': 3, 'name': '午餐', 'parent_name': '餐饮', 'icon': 'lunch_dining', 'sort_order': 2},
      {'id': 4, 'name': '晚餐', 'parent_name': '餐饮', 'icon': 'dinner_dining', 'sort_order': 3},
      {'id': 5, 'name': '零食/夜宵', 'parent_name': '餐饮', 'icon': 'fastfood', 'sort_order': 4},
      {'id': 6, 'name': '交通', 'parent_name': null, 'icon': 'directions_car', 'sort_order': 5},
      {'id': 7, 'name': '公交/地铁', 'parent_name': '交通', 'icon': 'directions_bus', 'sort_order': 6},
      {'id': 8, 'name': '打车', 'parent_name': '交通', 'icon': 'local_taxi', 'sort_order': 7},
      {'id': 9, 'name': '加油/停车', 'parent_name': '交通', 'icon': 'local_gas_station', 'sort_order': 8},
      {'id': 10, 'name': '生活', 'parent_name': null, 'icon': 'home', 'sort_order': 9},
      {'id': 11, 'name': '房租/房贷', 'parent_name': '生活', 'icon': 'house', 'sort_order': 10},
      {'id': 12, 'name': '水电燃气', 'parent_name': '生活', 'icon': 'bolt', 'sort_order': 11},
      {'id': 13, 'name': '通讯费', 'parent_name': '生活', 'icon': 'phone', 'sort_order': 12},
      {'id': 14, 'name': '日用品', 'parent_name': '生活', 'icon': 'shopping_basket', 'sort_order': 13},
      {'id': 15, 'name': '饮料酒水', 'parent_name': null, 'icon': 'local_bar', 'sort_order': 14},
      {'id': 16, 'name': '奶茶/咖啡', 'parent_name': '饮料酒水', 'icon': 'local_cafe', 'sort_order': 15},
      {'id': 17, 'name': '饮料', 'parent_name': '饮料酒水', 'icon': 'local_drink', 'sort_order': 16},
      {'id': 18, 'name': '酒水', 'parent_name': '饮料酒水', 'icon': 'wine_bar', 'sort_order': 17},
      {'id': 19, 'name': '比赛/活动', 'parent_name': null, 'icon': 'emoji_events', 'sort_order': 18},
      {'id': 20, 'name': '报名费', 'parent_name': '比赛/活动', 'icon': 'how_to_reg', 'sort_order': 19},
      {'id': 21, 'name': '装备费', 'parent_name': '比赛/活动', 'icon': 'sports', 'sort_order': 20},
      {'id': 22, 'name': '差旅费', 'parent_name': '比赛/活动', 'icon': 'flight', 'sort_order': 21},
      {'id': 23, 'name': '娱乐', 'parent_name': null, 'icon': 'movie', 'sort_order': 22},
      {'id': 24, 'name': '电影/演出', 'parent_name': '娱乐', 'icon': 'theaters', 'sort_order': 23},
      {'id': 25, 'name': '游戏', 'parent_name': '娱乐', 'icon': 'sports_esports', 'sort_order': 24},
      {'id': 26, 'name': '运动健身', 'parent_name': '娱乐', 'icon': 'fitness_center', 'sort_order': 25},
      {'id': 27, 'name': '购物', 'parent_name': null, 'icon': 'shopping_bag', 'sort_order': 26},
      {'id': 28, 'name': '衣物', 'parent_name': '购物', 'icon': 'checkroom', 'sort_order': 27},
      {'id': 29, 'name': '电子产品', 'parent_name': '购物', 'icon': 'devices', 'sort_order': 28},
      {'id': 30, 'name': '其他购物', 'parent_name': '购物', 'icon': 'add_shopping_cart', 'sort_order': 29},
      {'id': 31, 'name': '其他', 'parent_name': null, 'icon': 'more_horiz', 'sort_order': 30, 'type': 'expense'},
      {'id': 32, 'name': '医疗', 'parent_name': '其他', 'icon': 'local_hospital', 'sort_order': 31, 'type': 'expense'},
      {'id': 33, 'name': '教育', 'parent_name': '其他', 'icon': 'school', 'sort_order': 32, 'type': 'expense'},
      {'id': 34, 'name': '社交/礼物', 'parent_name': '其他', 'icon': 'card_giftcard', 'sort_order': 33, 'type': 'expense'},
      // 收入类分类
      {'id': 35, 'name': '工资', 'parent_name': null, 'icon': 'payments', 'sort_order': 34, 'type': 'income'},
      {'id': 36, 'name': '基本工资', 'parent_name': '工资', 'icon': 'account_balance', 'sort_order': 35, 'type': 'income'},
      {'id': 37, 'name': '奖金', 'parent_name': '工资', 'icon': 'card_giftcard', 'sort_order': 36, 'type': 'income'},
      {'id': 38, 'name': '加班费', 'parent_name': '工资', 'icon': 'access_time', 'sort_order': 37, 'type': 'income'},
      {'id': 39, 'name': '投资理财', 'parent_name': null, 'icon': 'trending_up', 'sort_order': 38, 'type': 'income'},
      {'id': 40, 'name': '利息', 'parent_name': '投资理财', 'icon': 'savings', 'sort_order': 39, 'type': 'income'},
      {'id': 41, 'name': '股息', 'parent_name': '投资理财', 'icon': 'show_chart', 'sort_order': 40, 'type': 'income'},
      {'id': 42, 'name': '投资收益', 'parent_name': '投资理财', 'icon': 'trending_up', 'sort_order': 41, 'type': 'income'},
      {'id': 43, 'name': '其他收入', 'parent_name': null, 'icon': 'add_circle', 'sort_order': 42, 'type': 'income'},
      {'id': 44, 'name': '红包', 'parent_name': '其他收入', 'icon': 'card_giftcard', 'sort_order': 43, 'type': 'income'},
      {'id': 45, 'name': '退款', 'parent_name': '其他收入', 'icon': 'restore', 'sort_order': 44, 'type': 'income'},
      {'id': 46, 'name': '兼职', 'parent_name': '其他收入', 'icon': 'work', 'sort_order': 45, 'type': 'income'},
    ];
  }

  // ========== 账户操作 ==========
  Future<int> insertAccount(Account account) async {
    await _ensureInitialized();
    final id = _nextId('accounts');
    _data['accounts']!.add({
      'id': id,
      'name': account.name,
      'balance': account.balance,
      'icon': account.icon,
      'created_at': (account.createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': (account.updatedAt ?? DateTime.now()).toIso8601String(),
    });
    await _save();
    return id;
  }

  Future<List<Account>> getAccounts() async {
    await _ensureInitialized();
    return _data['accounts']!.map((map) => Account.fromMap(map)).toList();
  }

  Future<int> updateAccount(Account account) async {
    await _ensureInitialized();
    final index = _data['accounts']!.indexWhere((a) => a['id'] == account.id);
    if (index != -1) {
      _data['accounts']![index] = {
        ...account.toMap(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      await _save();
    }
    return index != -1 ? 1 : 0;
  }

  Future<double> getAccountBalance(int accountId) async {
    await _ensureInitialized();
    final account = _data['accounts']!.firstWhere(
      (a) => a['id'] == accountId,
      orElse: () => {'balance': 0.0},
    );
    return (account['balance'] as num).toDouble();
  }

  Future<void> updateAccountBalance(int accountId, double amount) async {
    await _ensureInitialized();
    final index = _data['accounts']!.indexWhere((a) => a['id'] == accountId);
    if (index != -1) {
      final currentBalance = (_data['accounts']![index]['balance'] as num).toDouble();
      _data['accounts']![index]['balance'] = currentBalance + amount;
      _data['accounts']![index]['updated_at'] = DateTime.now().toIso8601String();
      await _save();
    }
  }

  Future<void> setAccountBalance(int accountId, double balance) async {
    await _ensureInitialized();
    final index = _data['accounts']!.indexWhere((a) => a['id'] == accountId);
    if (index != -1) {
      _data['accounts']![index]['balance'] = balance;
      _data['accounts']![index]['updated_at'] = DateTime.now().toIso8601String();
      await _save();
    }
  }

  // ========== 分类操作 ==========
  Future<List<Category>> getCategories() async {
    await _ensureInitialized();
    final list = _data['categories']!.map((map) => Category.fromMap(map)).toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  Future<List<Category>> getMainCategories() async {
    await _ensureInitialized();
    final list = _data['categories']!
        .where((c) => c['parent_name'] == null)
        .map((map) => Category.fromMap(map))
        .toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  Future<List<Category>> getSubCategories(String parentName) async {
    await _ensureInitialized();
    final list = _data['categories']!
        .where((c) => c['parent_name'] == parentName)
        .map((map) => Category.fromMap(map))
        .toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  Future<List<Category>> getMainCategoriesByType(String type) async {
    await _ensureInitialized();
    final list = _data['categories']!
        .where((c) => c['parent_name'] == null && (c['type'] as String? ?? 'expense') == type)
        .map((map) => Category.fromMap(map))
        .toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  Future<List<Category>> getSubCategoriesByParentAndType(String parentName, String type) async {
    await _ensureInitialized();
    final list = _data['categories']!
        .where((c) => c['parent_name'] == parentName && (c['type'] as String? ?? 'expense') == type)
        .map((map) => Category.fromMap(map))
        .toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  Future<double> getTodayIncome() async {
    await _ensureInitialized();
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    double total = 0;
    for (final t in _data['transactions']!) {
      final date = DateTime.parse(t['transaction_date']);
      if (date.isAfter(startOfDay) && date.isBefore(endOfDay)) {
        final amount = (t['amount'] as num).toDouble();
        if (amount > 0) total += amount;
      }
    }
    return total;
  }

  Future<double> getMonthIncome(int year, int month) async {
    await _ensureInitialized();
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    double total = 0;
    for (final t in _data['transactions']!) {
      final date = DateTime.parse(t['transaction_date']);
      if (date.isAfter(startOfMonth) && date.isBefore(endOfMonth)) {
        final amount = (t['amount'] as num).toDouble();
        if (amount > 0) total += amount;
      }
    }
    return total;
  }

  Future<Map<String, double>> getCategoryIncome(int year, int month) async {
    await _ensureInitialized();
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    Map<String, double> income = {};
    for (final t in _data['transactions']!) {
      final date = DateTime.parse(t['transaction_date']);
      if (date.isAfter(startOfMonth) && date.isBefore(endOfMonth)) {
        final amount = (t['amount'] as num).toDouble();
        if (amount > 0) {
          final cat = t['subcategory'] ?? t['category'] as String;
          income[cat] = (income[cat] ?? 0) + amount;
        }
      }
    }
    return income;
  }

  // ========== 交易记录操作 ==========
  Future<int> insertTransaction(model.Transaction transaction) async {
    await _ensureInitialized();
    final id = _nextId('transactions');
    _data['transactions']!.add({
      'id': id,
      'account_id': transaction.accountId,
      'amount': transaction.amount,
      'category': transaction.category,
      'subcategory': transaction.subcategory,
      'note': transaction.note,
      'transaction_date': transaction.transactionDate.toIso8601String(),
      'created_at': (transaction.createdAt ?? DateTime.now()).toIso8601String(),
    });

    // 更新账户余额
    await updateAccountBalance(transaction.accountId, transaction.amount);

    // 更新分类预算使用情况
    await _updateCategoryBudgetUsage(transaction);

    return id;
  }

  Future<void> _updateCategoryBudgetUsage(model.Transaction transaction) async {
    if (transaction.amount >= 0) return;

    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final category = transaction.subcategory ?? transaction.category;

    final index = _data['category_budgets']!.indexWhere(
      (b) => b['month'] == month && b['category_name'] == category,
    );

    if (index != -1) {
      final currentUsed = (_data['category_budgets']![index]['used_amount'] as num).toDouble();
      _data['category_budgets']![index]['used_amount'] = currentUsed + transaction.amount.abs();
      await _save();
    }
  }

  Future<List<model.Transaction>> getTransactions({int? limit}) async {
    await _ensureInitialized();
    final list = _data['transactions']!
        .map((map) => model.Transaction.fromMap(map))
        .toList();
    list.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    if (limit != null && list.length > limit) {
      return list.sublist(0, limit);
    }
    return list;
  }

  Future<List<model.Transaction>> getTransactionsByDate(DateTime date) async {
    await _ensureInitialized();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _data['transactions']!
        .map((map) => model.Transaction.fromMap(map))
        .where((t) =>
            t.transactionDate.isAfter(startOfDay) &&
            t.transactionDate.isBefore(endOfDay))
        .toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
  }

  Future<List<model.Transaction>> getTransactionsByMonth(int year, int month) async {
    await _ensureInitialized();
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    return _data['transactions']!
        .map((map) => model.Transaction.fromMap(map))
        .where((t) =>
            t.transactionDate.isAfter(startOfMonth) &&
            t.transactionDate.isBefore(endOfMonth))
        .toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
  }

  Future<double> getTodaySpending() async {
    await _ensureInitialized();
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    double total = 0;
    for (final t in _data['transactions']!) {
      final date = DateTime.parse(t['transaction_date']);
      if (date.isAfter(startOfDay) && date.isBefore(endOfDay)) {
        final amount = (t['amount'] as num).toDouble();
        if (amount < 0) total += amount;
      }
    }
    return total.abs();
  }

  Future<double> getMonthSpending(int year, int month) async {
    await _ensureInitialized();
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    double total = 0;
    for (final t in _data['transactions']!) {
      final date = DateTime.parse(t['transaction_date']);
      if (date.isAfter(startOfMonth) && date.isBefore(endOfMonth)) {
        final amount = (t['amount'] as num).toDouble();
        if (amount < 0) total += amount;
      }
    }
    return total.abs();
  }

  Future<Map<String, double>> getCategorySpending(int year, int month) async {
    await _ensureInitialized();
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    Map<String, double> spending = {};
    for (final t in _data['transactions']!) {
      final date = DateTime.parse(t['transaction_date']);
      if (date.isAfter(startOfMonth) && date.isBefore(endOfMonth)) {
        final amount = (t['amount'] as num).toDouble();
        if (amount < 0) {
          final cat = t['subcategory'] ?? t['category'] as String;
          spending[cat] = (spending[cat] ?? 0) + amount.abs();
        }
      }
    }
    return spending;
  }

  // ========== 预算操作 ==========
  Future<int> insertBudget(Budget budget) async {
    await _ensureInitialized();
    final id = _nextId('budgets');
    _data['budgets']!.add({
      'id': id,
      'month': budget.month,
      'total_amount': budget.totalAmount,
      'daily_amount': budget.dailyAmount,
      'created_at': (budget.createdAt ?? DateTime.now()).toIso8601String(),
    });
    await _save();
    return id;
  }

  Future<int> updateBudget(Budget budget) async {
    await _ensureInitialized();
    final index = _data['budgets']!.indexWhere((b) => b['id'] == budget.id);
    if (index != -1) {
      _data['budgets']![index] = budget.toMap();
      await _save();
      return 1;
    }
    return 0;
  }

  Future<Budget?> getBudgetByMonth(String month) async {
    await _ensureInitialized();
    final found = _data['budgets']!.where((b) => b['month'] == month);
    if (found.isNotEmpty) {
      return Budget.fromMap(found.first);
    }
    return null;
  }

  Future<List<Budget>> getBudgets() async {
    await _ensureInitialized();
    final list = _data['budgets']!.map((map) => Budget.fromMap(map)).toList();
    list.sort((a, b) => b.month.compareTo(a.month));
    return list;
  }

  // ========== 分类预算操作 ==========
  Future<void> saveCategoryBudget(String month, String categoryName, double amount) async {
    await _ensureInitialized();
    final index = _data['category_budgets']!.indexWhere(
      (b) => b['month'] == month && b['category_name'] == categoryName,
    );

    if (index != -1) {
      _data['category_budgets']![index]['budget_amount'] = amount;
    } else {
      _data['category_budgets']!.add({
        'id': _nextId('category_budgets'),
        'month': month,
        'category_name': categoryName,
        'budget_amount': amount,
        'used_amount': 0,
      });
    }
    await _save();
  }

  Future<List<CategoryBudget>> getCategoryBudgets(String month) async {
    await _ensureInitialized();
    return _data['category_budgets']!
        .where((b) => b['month'] == month)
        .map((map) => CategoryBudget.fromMap(map))
        .toList();
  }

  Future<CategoryBudget?> getCategoryBudget(String month, String categoryName) async {
    await _ensureInitialized();
    final found = _data['category_budgets']!.where(
      (b) => b['month'] == month && b['category_name'] == categoryName,
    );
    if (found.isNotEmpty) {
      return CategoryBudget.fromMap(found.first);
    }
    return null;
  }

  // 删除分类预算
  Future<void> deleteCategoryBudget(String month, String categoryName) async {
    await _ensureInitialized();
    _data['category_budgets']!.removeWhere(
      (b) => b['month'] == month && b['category_name'] == categoryName,
    );
    await _save();
  }

  /// 获取指定分类在当前月份的支出金额
  Future<double> getCategorySpendingForName(String categoryName) async {
    await _ensureInitialized();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    double total = 0;
    for (final t in _data['transactions']!) {
      final date = DateTime.parse(t['transaction_date']);
      if (date.isAfter(startOfMonth) && date.isBefore(endOfMonth)) {
        final amount = (t['amount'] as num).toDouble();
        if (amount < 0) {
          final cat = t['subcategory'] ?? t['category'] as String;
          if (cat == categoryName) {
            total += amount.abs();
          }
        }
      }
    }
    return total;
  }

  // 获取当月所有分类预算（含总支出数据）
  Future<List<Map<String, dynamic>>> getCategoryBudgetsWithSpending(String month) async {
    await _ensureInitialized();
    final categoryBudgets = _data['category_budgets']!.where((b) => b['month'] == month).toList();

    // 计算当月各分类实际支出
    final startOfMonth = DateTime(int.parse(month.split('-')[0]), int.parse(month.split('-')[1]), 1);
    final endOfMonth = DateTime(int.parse(month.split('-')[0]), int.parse(month.split('-')[1]) + 1, 1);

    Map<String, double> actualSpending = {};
    for (final t in _data['transactions']!) {
      final date = DateTime.parse(t['transaction_date']);
      if (date.isAfter(startOfMonth) && date.isBefore(endOfMonth)) {
        final amount = (t['amount'] as num).toDouble();
        if (amount < 0) {
          final cat = t['subcategory'] ?? t['category'] as String;
          actualSpending[cat] = (actualSpending[cat] ?? 0) + amount.abs();
        }
      }
    }

    // 合并预算和支出数据
    List<Map<String, dynamic>> result = [];
    for (final cb in categoryBudgets) {
      final categoryName = cb['category_name'] as String;
      final budgetAmount = (cb['budget_amount'] as num).toDouble();
      final spent = actualSpending[categoryName] ?? 0.0;
      result.add({
        'category_name': categoryName,
        'budget_amount': budgetAmount,
        'spent': spent,
        'remaining': budgetAmount - spent,
        'progress': budgetAmount > 0 ? (spent / budgetAmount).clamp(0.0, 1.0) : 0.0,
      });
    }
    return result;
  }

  // ========== 聚合分类预算（大类+子分类层级） ==========
  /// 返回按主分类聚合的预算数据，用于首页树形进度条展示
  Future<List<Map<String, dynamic>>> getAggregatedCategoryBudgets(String month) async {
    await _ensureInitialized();

    // 1. 获取当月所有分类预算记录
    final categoryBudgets = _data['category_budgets']!.where((b) => b['month'] == month).toList();

    // 2. 计算当月各分类实际支出
    final startOfMonth = DateTime(int.parse(month.split('-')[0]), int.parse(month.split('-')[1]), 1);
    final endOfMonth = DateTime(int.parse(month.split('-')[0]), int.parse(month.split('-')[1]) + 1, 1);

    Map<String, double> actualSpending = {};
    for (final t in _data['transactions']!) {
      final date = DateTime.parse(t['transaction_date']);
      if (date.isAfter(startOfMonth) && date.isBefore(endOfMonth)) {
        final amount = (t['amount'] as num).toDouble();
        if (amount < 0) {
          final cat = t['subcategory'] ?? t['category'] as String;
          actualSpending[cat] = (actualSpending[cat] ?? 0) + amount.abs();
        }
      }
    }

    // 3. 按主分类分组聚合
    // 先建立分类名 -> 主分类名的映射
    final allCategories = _data['categories']!
        .map((map) => Category.fromMap(map))
        .toList();

    Map<String, String> categoryToParent = {};
    for (final cat in allCategories) {
      if (cat.parentName != null) {
        categoryToParent[cat.name] = cat.parentName!;
      }
    }

    // 找出所有有预算的主分类
    Set<String> mainCategoriesWithBudget = {};
    for (final cb in categoryBudgets) {
      final catName = cb['category_name'] as String;
      final parent = categoryToParent[catName];
      if (parent != null) {
        mainCategoriesWithBudget.add(parent);
      } else {
        // 主分类本身有预算
        mainCategoriesWithBudget.add(catName);
      }
    }

    // 获取主分类的 icon 和 color 信息
    Map<String, Category> categoryMap = {};
    for (final cat in allCategories) {
      if (cat.parentName == null) {
        categoryMap[cat.name] = cat;
      }
    }

    // 构建聚合结果
    List<Map<String, dynamic>> result = [];
    for (final mainName in mainCategoriesWithBudget) {
      final mainCat = categoryMap[mainName];
      final color = _getCategoryColor(mainName);
      final icon = mainCat?.icon ?? 'category';

      // 聚合预算和支出
      double mainBudget = 0;
      double mainSpent = 0;
      List<Map<String, dynamic>> subList = [];

      // 遍历所有预算记录，归属到对应主分类
      for (final cb in categoryBudgets) {
        final catName = cb['category_name'] as String;
        final budgetAmount = (cb['budget_amount'] as num).toDouble();
        final spent = actualSpending[catName] ?? 0.0;

        final parent = categoryToParent[catName];
        if (parent == mainName) {
          // 子分类属于当前主分类，只保留预算 > 0 的
          if (budgetAmount > 0) {
            mainBudget += budgetAmount;
            mainSpent += spent;
            subList.add({
              'name': catName,
              'icon': _getCategoryIconForName(catName),
              'budget': budgetAmount,
              'spent': spent,
              'progress': budgetAmount > 0 ? (spent / budgetAmount).clamp(0.0, 1.0) : 0.0,
            });
          }
        } else if (catName == mainName) {
          // 主分类自身有预算，只保留预算 > 0 的
          if (budgetAmount > 0) {
            mainBudget += budgetAmount;
            mainSpent += spent;
          }
        }
      }

      // 只保留总预算 > 0 的主分类
      if (mainBudget > 0) {
        result.add({
          'main_category': mainName,
          'main_icon': icon,
          'main_color': color,
          'main_budget': mainBudget,
          'main_spent': mainSpent,
          'main_remaining': mainBudget - mainSpent,
          'main_progress': mainBudget > 0 ? (mainSpent / mainBudget).clamp(0.0, 1.0) : 0.0,
          'subcategories': subList,
        });
      }
    }

    // 按主分类 sort_order 排序
    result.sort((a, b) {
      final catA = categoryMap[a['main_category']];
      final catB = categoryMap[b['main_category']];
      return (catA?.sortOrder ?? 0).compareTo(catB?.sortOrder ?? 0);
    });

    return result;
  }

  String _getCategoryIconForName(String name) {
    for (final cat in _data['categories']!) {
      final c = Category.fromMap(cat);
      if (c.name == name) return c.icon;
    }
    return 'category';
  }

  Color _getCategoryColor(String name) {
    switch (name) {
      case '餐饮':
        return Colors.orange;
      case '交通':
        return Colors.blue;
      case '生活':
        return Colors.green;
      case '饮料酒水':
        return Colors.purple;
      case '比赛/活动':
        return Colors.amber;
      case '娱乐':
        return Colors.pink;
      case '购物':
        return Colors.indigo;
      case '其他':
        return Colors.grey;
      default:
        return Colors.teal;
    }
  }

  // ========== 获取当月有预算分配的主分类列表 ==========
  /// 返回当月有预算记录的主分类名列表，用于添加账单页面筛选
  Future<List<String>> getBudgetAssignedCategories(String month, String type) async {
    await _ensureInitialized();

    final categoryBudgets = _data['category_budgets']!.where((b) => b['month'] == month).toList();
    final allCategories = _data['categories']!
        .map((map) => Category.fromMap(map))
        .where((c) => c.type == type)
        .toList();

    // 建立分类名 -> 主分类名的映射
    Map<String, String> categoryToParent = {};
    for (final cat in allCategories) {
      if (cat.parentName != null) {
        categoryToParent[cat.name] = cat.parentName!;
      }
    }

    // 找出有预算（>0）的主分类
    Map<String, double> mainCategoryBudgetSum = {};
    for (final cb in categoryBudgets) {
      final catName = cb['category_name'] as String;
      final budgetAmount = (cb['budget_amount'] as num).toDouble();
      if (budgetAmount <= 0) continue;

      final parent = categoryToParent[catName];
      if (parent != null) {
        mainCategoryBudgetSum[parent] = (mainCategoryBudgetSum[parent] ?? 0) + budgetAmount;
      } else {
        // 检查该主分类是否在指定类型中
        final isMainOfType = allCategories.any((c) => c.name == catName && c.parentName == null);
        if (isMainOfType) {
          mainCategoryBudgetSum[catName] = (mainCategoryBudgetSum[catName] ?? 0) + budgetAmount;
        }
      }
    }

    // 只返回总预算 > 0 的主分类
    return mainCategoryBudgetSum.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList();
  }

  // ========== 历史查询方法 ==========

  /// 获取某年的所有交易记录
  Future<List<model.Transaction>> getTransactionsByYear(int year) async {
    await _ensureInitialized();
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year + 1, 1, 1);

    return _data['transactions']!
        .map((map) => model.Transaction.fromMap(map))
        .where((t) =>
            t.transactionDate.isAfter(startOfYear) &&
            t.transactionDate.isBefore(endOfYear))
        .toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
  }

  /// 获取某月的汇总数据
  Future<Map<String, dynamic>> getMonthSummary(int year, int month) async {
    await _ensureInitialized();
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    double totalSpending = 0;
    double totalIncome = 0;
    Map<String, double> spendingByCategory = {};
    Map<String, double> incomeByCategory = {};

    for (final t in _data['transactions']!) {
      final date = DateTime.parse(t['transaction_date']);
      if (date.isAfter(startOfMonth) && date.isBefore(endOfMonth)) {
        final amount = (t['amount'] as num).toDouble();
        if (amount < 0) {
          totalSpending += amount.abs();
          final cat = t['subcategory'] ?? t['category'] as String;
          spendingByCategory[cat] = (spendingByCategory[cat] ?? 0) + amount.abs();
        } else if (amount > 0) {
          totalIncome += amount;
          final cat = t['subcategory'] ?? t['category'] as String;
          incomeByCategory[cat] = (incomeByCategory[cat] ?? 0) + amount;
        }
      }
    }

    final budget = await getBudgetByMonth('$year-${month.toString().padLeft(2, '0')}');
    final budgetTotal = budget?.totalAmount ?? 0;

    return {
      'total_spending': totalSpending,
      'total_income': totalIncome,
      'budget_total': budgetTotal,
      'spending_by_category': spendingByCategory,
      'income_by_category': incomeByCategory,
    };
  }

  /// 获取某年每月的收支汇总
  Future<List<Map<String, dynamic>>> getMonthlyTrend(int year) async {
    await _ensureInitialized();
    List<Map<String, dynamic>> result = [];

    for (int month = 1; month <= 12; month++) {
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 1);

      double spending = 0;
      double income = 0;

      for (final t in _data['transactions']!) {
        final date = DateTime.parse(t['transaction_date']);
        if (date.isAfter(startOfMonth) && date.isBefore(endOfMonth)) {
          final amount = (t['amount'] as num).toDouble();
          if (amount < 0) spending += amount.abs();
          if (amount > 0) income += amount;
        }
      }

      // 跳过没有数据的月份
      if (spending > 0 || income > 0) {
        result.add({
          'month': month,
          'spending': spending,
          'income': income,
        });
      }
    }

    return result;
  }

  /// 获取内部数据（供调试和外部访问）
  Map<String, List<Map<String, dynamic>>> get data => _data;

  /// 添加自定义主分类
  Future<int> insertCustomMainCategory(String name, String icon) async {
    await _ensureInitialized();
    final id = _nextId('categories');
    _data['categories']!.add({
      'id': id,
      'name': name,
      'parent_name': null,
      'icon': icon,
      'sort_order': 999,
      'type': 'expense',
    });
    await _save();
    return id;
  }

  /// 添加自定义子分类
  Future<int> insertCustomSubCategory(String mainName, String subName, String icon) async {
    await _ensureInitialized();
    final id = _nextId('categories');
    _data['categories']!.add({
      'id': id,
      'name': subName,
      'parent_name': mainName,
      'icon': icon,
      'sort_order': 999,
      'type': 'expense',
    });
    await _save();
    return id;
  }

  /// 删除自定义主分类及其所有子分类
  Future<void> deleteCustomCategory(String mainName) async {
    await _ensureInitialized();
    _data['categories']!.removeWhere((c) => c['name'] == mainName || c['parent_name'] == mainName);
    await _save();
  }
}
