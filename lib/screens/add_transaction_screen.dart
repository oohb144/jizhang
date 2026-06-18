import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart' as model;
import '../models/account.dart';
import '../models/category.dart';
import 'category_budget_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedMainCategory;
  String? _selectedSubCategory;
  int? _selectedAccountId;
  bool _isExpense = true;
  List<Account> _accounts = [];
  List<Category> _mainCategories = [];
  List<Category> _subCategories = [];
  bool _isLoadingCategories = true;
  String? _emptyReason;
  bool _needCategory = true; // 收入不需要分类

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final accounts = await DatabaseHelper.instance.getAccounts();
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    List<Category> mainCategories;
    String? emptyReason;

    if (_isExpense) {
      // 支出：只显示有预算分配的主分类
      final assignedCategories = await DatabaseHelper.instance.getBudgetAssignedCategories(month, 'expense');
      if (assignedCategories.isEmpty) {
        emptyReason = '请先在预算管理中为分类设置预算';
        mainCategories = [];
      } else {
        final allMainCats = await DatabaseHelper.instance.getMainCategoriesByType('expense');
        mainCategories = allMainCats.where((c) => assignedCategories.contains(c.name)).toList();
      }
      setState(() {
        _needCategory = true;
      });
    } else {
      // 收入：不需要分类
      mainCategories = [];
      setState(() {
        _needCategory = false;
        _selectedMainCategory = null;
        _selectedSubCategory = null;
        _subCategories = [];
      });
    }

    setState(() {
      _accounts = accounts;
      _mainCategories = mainCategories;
      _isLoadingCategories = false;
      _emptyReason = emptyReason;
      if (accounts.isNotEmpty) {
        _selectedAccountId = accounts.first.id;
      }
      if (mainCategories.isNotEmpty) {
        _selectedMainCategory = mainCategories.first.name;
        _loadSubCategories(mainCategories.first.name);
      } else {
        _selectedMainCategory = null;
        _selectedSubCategory = null;
        _subCategories = [];
      }
    });
  }

  Future<void> _loadSubCategories(String parentName) async {
    final subCategories = await DatabaseHelper.instance.getSubCategoriesByParentAndType(
      parentName,
      _isExpense ? 'expense' : 'income',
    );
    setState(() {
      _subCategories = subCategories;
      _selectedSubCategory = subCategories.isNotEmpty ? subCategories.first.name : null;
    });
  }

  Future<void> _onMainCategoryChanged(String name) async {
    setState(() {
      _selectedMainCategory = name;
    });
    await _loadSubCategories(name);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
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
      case 'payments':
        return Icons.payments;
      case 'account_balance':
        return Icons.account_balance;
      case 'savings':
        return Icons.savings;
      case 'trending_up':
        return Icons.trending_up;
      case 'add_circle':
        return Icons.add_circle;
      case 'restore':
        return Icons.restore;
      case 'work':
        return Icons.work;
      case 'access_time':
        return Icons.access_time;
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
      case '工资':
        return Colors.teal;
      case '投资理财':
        return Colors.indigoAccent;
      case '其他收入':
        return Colors.lime;
      default:
        return Colors.teal;
    }
  }

  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入金额')),
      );
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择账户')),
      );
      return;
    }

    if (_needCategory && _selectedMainCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择分类')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效金额')),
      );
      return;
    }

    // 支出为负数，收入为正数
    final finalAmount = _isExpense ? -amount : amount;

    // 收入时分类可为空，使用默认值
    final category = _isExpense ? (_selectedMainCategory ?? '') : (_selectedMainCategory ?? '其他收入');

    final transaction = model.Transaction(
      accountId: _selectedAccountId!,
      amount: finalAmount,
      category: category,
      subcategory: _selectedSubCategory,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      transactionDate: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await DatabaseHelper.instance.insertTransaction(transaction);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _isExpense ? Colors.red : Colors.green;
    final typeLabel = _isExpense ? '支出金额' : '收入金额';

    return Scaffold(
      appBar: AppBar(
        title: const Text('记账'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 支出/收入切换
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_isExpense) return;
                          setState(() => _isExpense = true);
                          _loadData();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _isExpense ? Colors.red : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '支出',
                              style: TextStyle(
                                color: _isExpense ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!_isExpense) return;
                          setState(() => _isExpense = false);
                          _loadData();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: !_isExpense ? Colors.green : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '收入',
                              style: TextStyle(
                                color: !_isExpense ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 金额输入
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      typeLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        prefixText: '¥ ',
                        prefixStyle: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                        border: InputBorder.none,
                        hintText: '0.00',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 选择账户
            const Text(
              '选择账户',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _accounts.map((account) {
                  final isSelected = _selectedAccountId == account.id;
                  final isWechat = account.name == '微信';
                  final color = isWechat ? const Color(0xFF07C160) : const Color(0xFF1677FF);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAccountId = account.id;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? color : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? color : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            isWechat ? Icons.chat : Icons.account_balance_wallet,
                            color: isSelected ? Colors.white : color,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            account.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // 选择一级分类（仅支出显示）
            if (_needCategory) ...[
              Text(
                '选择分类',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _isLoadingCategories ? Colors.grey : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoadingCategories)
                const Center(child: CircularProgressIndicator())
              else if (_emptyReason != null)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.category_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _emptyReason!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CategoryBudgetScreen()),
                            );
                            if (result == true) {
                              _loadData(); // 重新加载分类
                            }
                          },
                          icon: const Icon(Icons.tune),
                          label: const Text('去设置预算'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _mainCategories.map((category) {
                  final isSelected = _selectedMainCategory == category.name;
                  final color = _getCategoryColor(category.name);

                  return GestureDetector(
                    onTap: () => _onMainCategoryChanged(category.name),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? color : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? color : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(category.icon),
                            color: isSelected ? Colors.white : color,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            category.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 选择二级分类
              if (_subCategories.isNotEmpty) ...[
                const Text(
                  '选择子分类',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _subCategories.map((subCat) {
                    final isSelected = _selectedSubCategory == subCat.name;
                    final color = _getCategoryColor(_selectedMainCategory ?? '');

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSubCategory = subCat.name;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? color : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? color : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCategoryIcon(subCat.icon),
                              color: isSelected ? Colors.white : color,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              subCat.name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ] else ...[
              const SizedBox(height: 20),
            ],

            // 备注
            const Text(
              '备注',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '输入备注（可选）',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 确认按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: typeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '确认记账',
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
}
