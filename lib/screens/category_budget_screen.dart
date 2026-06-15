import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/category.dart';
import '../models/category_budget.dart';
import '../models/budget.dart';

class CategoryBudgetScreen extends StatefulWidget {
  const CategoryBudgetScreen({super.key});

  @override
  State<CategoryBudgetScreen> createState() => _CategoryBudgetScreenState();
}

class _CategoryBudgetScreenState extends State<CategoryBudgetScreen> {
  final _totalBudgetController = TextEditingController();
  List<Category> _mainCategories = [];
  Map<String, List<Category>> _subCategories = {};
  Map<String, TextEditingController> _budgetControllers = {};
  Budget? _currentBudget;
  List<CategoryBudget> _categoryBudgets = [];
  String _currentMonth = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _loadData();
  }

  Future<void> _loadData() async {
    final mainCategories = await DatabaseHelper.instance.getMainCategories();
    Map<String, List<Category>> subCategories = {};

    for (final mainCat in mainCategories) {
      final subs = await DatabaseHelper.instance.getSubCategories(mainCat.name);
      subCategories[mainCat.name] = subs;
    }

    final budget = await DatabaseHelper.instance.getBudgetByMonth(_currentMonth);
    final categoryBudgets = await DatabaseHelper.instance.getCategoryBudgets(_currentMonth);

    setState(() {
      _mainCategories = mainCategories;
      _subCategories = subCategories;
      _currentBudget = budget;
      _categoryBudgets = categoryBudgets;

      if (budget != null) {
        _totalBudgetController.text = budget.totalAmount.toStringAsFixed(2);
      }

      _budgetControllers = {};
      for (final catBudget in categoryBudgets) {
        _budgetControllers[catBudget.categoryName] = TextEditingController(
          text: catBudget.budgetAmount.toStringAsFixed(2),
        );
      }
    });
  }

  @override
  void dispose() {
    _totalBudgetController.dispose();
    for (final controller in _budgetControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double _getCategoryBudget(String categoryName) {
    final catBudget = _categoryBudgets.firstWhere(
      (b) => b.categoryName == categoryName,
      orElse: () => CategoryBudget(
        month: _currentMonth,
        categoryName: categoryName,
        budgetAmount: 0,
      ),
    );
    return catBudget.budgetAmount;
  }

  double _getCategoryUsed(String categoryName) {
    final catBudget = _categoryBudgets.firstWhere(
      (b) => b.categoryName == categoryName,
      orElse: () => CategoryBudget(
        month: _currentMonth,
        categoryName: categoryName,
        budgetAmount: 0,
      ),
    );
    return catBudget.usedAmount;
  }

  Future<void> _saveBudgets() async {
    // 保存总预算
    final totalBudget = double.tryParse(_totalBudgetController.text) ?? 0;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = daysInMonth - now.day + 1;
    final dailyBudget = remainingDays > 0 ? totalBudget / remainingDays : 0.0;

    if (_currentBudget != null) {
      await DatabaseHelper.instance.updateBudget(Budget(
        id: _currentBudget!.id,
        month: _currentMonth,
        totalAmount: totalBudget,
        dailyAmount: dailyBudget,
      ));
    } else {
      await DatabaseHelper.instance.insertBudget(Budget(
        month: _currentMonth,
        totalAmount: totalBudget,
        dailyAmount: dailyBudget,
        createdAt: DateTime.now(),
      ));
    }

    // 保存分类预算
    for (final entry in _budgetControllers.entries) {
      final categoryName = entry.key;
      final amount = double.tryParse(entry.value.text) ?? 0;
      await DatabaseHelper.instance.saveCategoryBudget(_currentMonth, categoryName, amount);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('预算已保存')),
      );
      Navigator.pop(context, true);
    }
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'free_breakfast':
        return Icons.free_breakfast;
      case 'lunch_dining':
        return Icons.lunch_dining;
      case 'dinner_dining':
        return Icons.dinner_dining;
      case 'fastfood':
        return Icons.fastfood;
      case 'directions_car':
        return Icons.directions_car;
      case 'directions_bus':
        return Icons.directions_bus;
      case 'local_taxi':
        return Icons.local_taxi;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'home':
        return Icons.home;
      case 'house':
        return Icons.house;
      case 'bolt':
        return Icons.bolt;
      case 'phone':
        return Icons.phone;
      case 'shopping_basket':
        return Icons.shopping_basket;
      case 'local_bar':
        return Icons.local_bar;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'local_drink':
        return Icons.local_drink;
      case 'wine_bar':
        return Icons.wine_bar;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'how_to_reg':
        return Icons.how_to_reg;
      case 'sports':
        return Icons.sports;
      case 'flight':
        return Icons.flight;
      case 'movie':
        return Icons.movie;
      case 'theaters':
        return Icons.theaters;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'checkroom':
        return Icons.checkroom;
      case 'devices':
        return Icons.devices;
      case 'add_shopping_cart':
        return Icons.add_shopping_cart;
      case 'more_horiz':
        return Icons.more_horiz;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'card_giftcard':
        return Icons.card_giftcard;
      default:
        return Icons.category;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('预算管理'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 总预算设置
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Color(0xFF2196F3)),
                        const SizedBox(width: 8),
                        Text(
                          '$_currentMonth 月度总预算',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _totalBudgetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        labelText: '总预算金额',
                        prefixText: '¥ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 分类预算设置
            const Text(
              '分类预算设置',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '为每个支出分类设置预算额度',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            ..._mainCategories.map((mainCat) => _buildCategorySection(mainCat)),

            const SizedBox(height: 24),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveBudgets,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '保存预算',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(Category mainCat) {
    final color = _getCategoryColor(mainCat.name);
    final subCats = _subCategories[mainCat.name] ?? [];
    final mainBudget = _getCategoryBudget(mainCat.name);
    final mainUsed = _getCategoryUsed(mainCat.name);

    // 初始化主分类的controller
    if (!_budgetControllers.containsKey(mainCat.name)) {
      _budgetControllers[mainCat.name] = TextEditingController(
        text: mainBudget.toStringAsFixed(2),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主分类标题和预算
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getCategoryIcon(mainCat.icon),
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mainCat.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (mainBudget > 0)
                        Text(
                          '已用 ¥${mainUsed.toStringAsFixed(2)} / ¥${mainBudget.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: mainUsed > mainBudget ? Colors.red : Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 120,
                  height: 36,
                  child: TextField(
                    controller: _budgetControllers[mainCat.name],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      prefixText: '¥ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),

            // 子分类
            if (subCats.isNotEmpty) ...[
              const Divider(height: 24),
              ...subCats.map((subCat) => _buildSubCategoryItem(subCat, color)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubCategoryItem(Category subCat, Color color) {
    final budget = _getCategoryBudget(subCat.name);
    final used = _getCategoryUsed(subCat.name);

    if (!_budgetControllers.containsKey(subCat.name)) {
      _budgetControllers[subCat.name] = TextEditingController(
        text: budget > 0 ? budget.toStringAsFixed(2) : '',
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const SizedBox(width: 52),
          Icon(
            _getCategoryIcon(subCat.icon),
            color: color.withOpacity(0.7),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subCat.name,
                  style: const TextStyle(fontSize: 14),
                ),
                if (budget > 0)
                  Text(
                    '已用 ¥${used.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: used > budget ? Colors.red : Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            height: 32,
            child: TextField(
              controller: _budgetControllers[subCat.name],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                prefixText: '¥ ',
                hintText: '0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
