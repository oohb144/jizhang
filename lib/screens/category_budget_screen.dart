import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  List<Category> _mainCategories = [];
  Map<String, List<Category>> _subCategories = {};
  Map<String, TextEditingController> _budgetControllers = {};
  List<CategoryBudget> _categoryBudgets = [];
  String _currentMonth = '';
  Budget? _currentBudget;

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

    final categoryBudgets = await DatabaseHelper.instance.getCategoryBudgets(_currentMonth);
    final budget = await DatabaseHelper.instance.getBudgetByMonth(_currentMonth);

    setState(() {
      _mainCategories = mainCategories;
      _subCategories = subCategories;
      _categoryBudgets = categoryBudgets;
      _currentBudget = budget;

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
    for (final controller in _budgetControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// 计算主分类预算（子分类预算之和）
  double _calculateMainCategoryBudget(String mainName) {
    double total = 0;
    final subs = _subCategories[mainName] ?? [];
    for (final sub in subs) {
      total += double.tryParse(_budgetControllers[sub.name]?.text ?? '0') ?? 0;
    }
    return total;
  }

  /// 计算所有主分类预算总和（即总预算）
  double _calculateTotalBudget() {
    double total = 0;
    for (final mainCat in _mainCategories) {
      total += _calculateMainCategoryBudget(mainCat.name);
    }
    return total;
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

  Future<double> _getCategoryUsed(String categoryName) async {
    return await DatabaseHelper.instance.getCategorySpendingForName(categoryName);
  }

  // ========== 自定义分类添加 ==========
  void _showAddCustomCategoryDialog() {
    final mainNameCtrl = TextEditingController();
    final subCountCtrl = TextEditingController(text: '0');
    final List<TextEditingController> subNameCtrls = [];
    final List<FocusNode> subFocusNodes = [];
    IconData selectedIcon = Icons.category;

    final icons = [
      Icons.restaurant, Icons.directions_car, Icons.home, Icons.shopping_bag,
      Icons.movie, Icons.local_bar, Icons.emoji_events, Icons.more_horiz,
      Icons.local_hospital, Icons.school, Icons.card_giftcard, Icons.shopping_basket,
      Icons.travel_explore, Icons.pets, Icons.local_florist, Icons.spa,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加自定义分类'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('主分类名称', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                TextField(
                  controller: mainNameCtrl,
                  decoration: const InputDecoration(
                    hintText: '例如：旅行、宠物',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('选择图标', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: icons.map((ic) {
                    final isSelected = selectedIcon == ic;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = ic),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2196F3).withOpacity(0.15) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2196F3) : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Icon(ic, color: isSelected ? const Color(0xFF2196F3) : Colors.grey, size: 22),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('子分类数量', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                TextField(
                  controller: subCountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: '输入数量',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final count = int.tryParse(value) ?? 0;
                    // 调整子分类输入框列表
                    while (subNameCtrls.length < count) {
                      subNameCtrls.add(TextEditingController());
                      subFocusNodes.add(FocusNode());
                    }
                    while (subNameCtrls.length > count) {
                      subNameCtrls.last.dispose();
                      subNameCtrls.removeLast();
                      subFocusNodes.last.dispose();
                      subFocusNodes.removeLast();
                    }
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 12),
                ...subNameCtrls.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final ctrl = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      focusNode: subFocusNodes[idx],
                      controller: ctrl,
                      decoration: InputDecoration(
                        hintText: '子分类 ${idx + 1}',
                        border: const OutlineInputBorder(),
                        prefixText: '${idx + 1}. ',
                        prefixStyle: TextStyle(color: Colors.grey.shade400),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final mainName = mainNameCtrl.text.trim();
                if (mainName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入主分类名称')),
                  );
                  return;
                }

                // 检查子分类名称
                final subNames = subNameCtrls
                    .map((c) => c.text.trim())
                    .where((n) => n.isNotEmpty)
                    .toList();

                if (subNames.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请至少添加一个子分类名称')),
                  );
                  return;
                }

                // 检查重复
                final existingNames = _subCategories.entries
                    .expand((e) => e.value.map((s) => s.name))
                    .toList();
                for (final name in subNames) {
                  if (existingNames.contains(name)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('子分类 "$name" 已存在')),
                    );
                    return;
                  }
                }

                Navigator.pop(context); // 关闭对话框
                _addCustomCategory(mainName, selectedIcon, subNames);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3)),
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCustomCategory(String mainName, IconData icon, List<String> subNames) async {
    String iconStr = _iconDataToString(icon);

    // 1. 插入主分类
    await DatabaseHelper.instance.insertCustomMainCategory(mainName, iconStr);

    // 2. 插入子分类
    for (final subName in subNames) {
      await DatabaseHelper.instance.insertCustomSubCategory(mainName, subName, iconStr);
    }

    // 3. 刷新数据
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已添加分类 "$mainName" 及其 ${subNames.length} 个子分类')),
      );
    }
  }

  String _iconDataToString(IconData icon) {
    final fontFamily = icon.fontFamily;
    final codePoint = icon.codePoint;

    // Material Icons 字体
    if (fontFamily == 'MaterialIcons' || fontFamily == null || fontFamily.isEmpty) {
      const iconMap = <int, String>{
        0xe57f: 'category',
        0xe573: 'restaurant',
        0xe568: 'free_breakfast',
        0xf028e: 'lunch_dining',
        0xf058e: 'dinner_dining',
        0xe576: 'fastfood',
        0xe9ba: 'directions_car',
        0xe9bb: 'directions_bus',
        0xe9be: 'local_taxi',
        0xe9c1: 'local_gas_station',
        0xe8b8: 'home',
        0xe8b9: 'house',
        0xe193: 'bolt',
        0xe0cd: 'phone',
        0xe354: 'shopping_basket',
        0xeef0: 'local_bar',
        0xeef1: 'local_cafe',
        0xeef2: 'local_drink',
        0xeef3: 'wine_bar',
        0xe803: 'emoji_events',
        0xe8e7: 'how_to_reg',
        0xe428: 'sports',
        0xe405: 'flight',
        0xe02a: 'movie',
        0xe02b: 'theaters',
        0xe5d7: 'sports_esports',
        0xe20c: 'fitness_center',
        0xe8a8: 'shopping_bag',
        0xe306: 'checkroom',
        0xe325: 'devices',
        0xe195: 'add_shopping_cart',
        0xe56f: 'more_horiz',
        0xeac3: 'local_hospital',
        0xe80a: 'school',
        0xe168: 'card_giftcard',
        0xef68: 'travel_explore',
        0xea75: 'pets',
        0xe30e: 'local_florist',
        0xe53f: 'sports_basketball',
        0xe3eb: 'hvac',
        0xe8fa: 'science',
        0xe473: 'toys',
        0xe552: 'spa',
        0xe945: 'self_improvement',
        0xe3e7: 'kitchen',
      };
      return iconMap[codePoint] ?? 'category';
    }

    return 'category';
  }

  Future<void> _saveBudgets() async {
    // 先保存分类预算
    for (final entry in _budgetControllers.entries) {
      final amount = double.tryParse(entry.value.text) ?? 0;
      await DatabaseHelper.instance.saveCategoryBudget(_currentMonth, entry.key, amount);
    }

    // 再保存总预算（供首页读取）
    final totalBudget = _calculateTotalBudget();
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('预算已保存')),
      );
      Navigator.pop(context, true);
    }
  }

  // ========== 图标映射 ==========
  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'restaurant': return Icons.restaurant;
      case 'free_breakfast': return Icons.free_breakfast;
      case 'lunch_dining': return Icons.lunch_dining;
      case 'dinner_dining': return Icons.dinner_dining;
      case 'fastfood': return Icons.fastfood;
      case 'directions_car': return Icons.directions_car;
      case 'directions_bus': return Icons.directions_bus;
      case 'local_taxi': return Icons.local_taxi;
      case 'local_gas_station': return Icons.local_gas_station;
      case 'home': return Icons.home;
      case 'house': return Icons.house;
      case 'bolt': return Icons.bolt;
      case 'phone': return Icons.phone;
      case 'shopping_basket': return Icons.shopping_basket;
      case 'local_bar': return Icons.local_bar;
      case 'local_cafe': return Icons.local_cafe;
      case 'local_drink': return Icons.local_drink;
      case 'wine_bar': return Icons.wine_bar;
      case 'emoji_events': return Icons.emoji_events;
      case 'how_to_reg': return Icons.how_to_reg;
      case 'sports': return Icons.sports;
      case 'flight': return Icons.flight;
      case 'movie': return Icons.movie;
      case 'theaters': return Icons.theaters;
      case 'sports_esports': return Icons.sports_esports;
      case 'fitness_center': return Icons.fitness_center;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'checkroom': return Icons.checkroom;
      case 'devices': return Icons.devices;
      case 'add_shopping_cart': return Icons.add_shopping_cart;
      case 'more_horiz': return Icons.more_horiz;
      case 'local_hospital': return Icons.local_hospital;
      case 'school': return Icons.school;
      case 'card_giftcard': return Icons.card_giftcard;
      case 'category': return Icons.category;
      case 'travel_explore': return Icons.travel_explore;
      case 'pets': return Icons.pets;
      case 'local_florist': return Icons.local_florist;
      case 'sports_basketball': return Icons.sports_basketball;
      case 'cooking': return Icons.kitchen;
      case 'hvac': return Icons.hvac;
      case 'science': return Icons.science;
      case 'toys': return Icons.toys;
      case 'spa': return Icons.spa;
      case 'self_improvement': return Icons.self_improvement;
      default: return Icons.category;
    }
  }

  IconData _getCategoryIconForName(String name) {
    for (final cat in _data['categories']!) {
      final c = Category.fromMap(cat);
      if (c.name == name) return _getCategoryIcon(c.icon);
    }
    return Icons.category;
  }

  Color _getCategoryColor(String name) {
    switch (name) {
      case '餐饮': return Colors.orange;
      case '交通': return Colors.blue;
      case '生活': return Colors.green;
      case '饮料酒水': return Colors.purple;
      case '比赛/活动': return Colors.amber;
      case '娱乐': return Colors.pink;
      case '购物': return Colors.indigo;
      case '其他': return Colors.grey;
      default: return Colors.teal;
    }
  }

  Map<String, List<Map<String, dynamic>>> get _data => DatabaseHelper.instance.data;

  // ========== UI 构建 ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('预算管理'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: '添加自定义分类',
            onPressed: _showAddCustomCategoryDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 总预算
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
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        prefixText: '¥ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                      ),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2196F3)),
                      controller: TextEditingController(text: _calculateTotalBudget().toStringAsFixed(2)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '总预算 = 各分类预算之和，自动计算',
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 分类预算设置
            Row(
              children: [
                const Text('分类预算设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showAddCategoryDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加已有分类'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF2196F3)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              '为每个子分类设置预算额度\n主分类预算 = 子分类预算之和，自动计算',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),

            ..._mainCategories.map((mainCat) => _buildCategorySection(mainCat)),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveBudgets,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('保存预算', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 从已有分类中添加预算
  void _showAddCategoryDialog() {
    Map<String, List<Category>> availableByParent = {};
    for (final mainCat in _mainCategories) {
      final subs = _subCategories[mainCat.name] ?? [];
      final available = subs.where((sub) {
        return !_categoryBudgets.any((cb) => cb.categoryName == sub.name);
      }).toList();
      if (available.isNotEmpty) {
        availableByParent[mainCat.name] = available;
      }
    }

    if (availableByParent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有子分类都已添加预算')),
      );
      return;
    }

    Category? selectedCat;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加预算分类'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: availableByParent.entries.map((entry) {
                final mainName = entry.key;
                final subs = entry.value;
                final color = _getCategoryColor(mainName);
                return ExpansionTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_getCategoryIconForName(mainName), color: color, size: 18),
                  ),
                  title: Text(mainName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: subs.map((subCat) {
                    return ListTile(
                      dense: true,
                      leading: Icon(_getCategoryIconForName(subCat.icon), size: 20, color: color.withOpacity(0.7)),
                      title: Text(subCat.name),
                      selected: selectedCat?.name == subCat.name,
                      selectedTileColor: color.withOpacity(0.1),
                      onTap: () => setDialogState(() => selectedCat = subCat),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: selectedCat != null
                  ? () {
                      setState(() {
                        _budgetControllers[selectedCat!.name] = TextEditingController(text: '0.00');
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已添加分类 "${selectedCat!.name}" 的预算')),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3)),
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(Category mainCat) {
    final color = _getCategoryColor(mainCat.name);
    final subCats = _subCategories[mainCat.name] ?? [];
    final mainBudget = _calculateMainCategoryBudget(mainCat.name);
    final hasBudget = mainBudget > 0;

    Future<double> mainUsedFuture = Future.sync(() async {
      double total = 0;
      for (final sub in subCats) {
        total += await DatabaseHelper.instance.getCategorySpendingForName(sub.name);
      }
      return total;
    });

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_getCategoryIconForName(mainCat.name), color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            mainCat.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          if (hasBudget)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(Icons.calculate, size: 16, color: Colors.blue),
                            ),
                        ],
                      ),
                      if (hasBudget)
                        Text(
                          '自动汇总 = 子分类预算之和',
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                        ),
                      if (mainBudget > 0)
                        FutureBuilder<double>(
                          future: mainUsedFuture,
                          builder: (context, snapshot) {
                            final spent = snapshot.data ?? 0;
                            return Text(
                              '已用 ¥${spent.toStringAsFixed(2)} / ¥${mainBudget.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: spent > mainBudget ? Colors.red : Colors.grey,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '¥${mainBudget.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (subCats.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...subCats.map((subCat) => _buildSubCategoryItem(subCat, color)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubCategoryItem(Category subCat, Color mainColor) {
    final budget = _getCategoryBudget(subCat.name);
    final used = _getCategoryUsed(subCat.name);

    if (!_budgetControllers.containsKey(subCat.name)) {
      _budgetControllers[subCat.name] = TextEditingController(
        text: budget > 0 ? budget.toStringAsFixed(2) : '',
      );
    }

    return FutureBuilder<double>(
      future: used,
      builder: (context, snapshot) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // 左侧：删除按钮已移除
              const SizedBox(width: 8),
              Icon(
                _getCategoryIconForName(subCat.name),
                color: mainColor.withOpacity(0.7),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subCat.name,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              // 保存后才显示勾选标记
              if (budget > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.check_circle, size: 14, color: Colors.green),
                ),
              SizedBox(
                width: 100,
                height: 32,
                child: TextField(
                  onTapOutside: (_) {},
                  controller: _budgetControllers[subCat.name],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixText: '¥ ',
                    hintText: '0',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
