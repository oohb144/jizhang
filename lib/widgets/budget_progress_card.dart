import 'package:flutter/material.dart';

class BudgetProgressCard extends StatelessWidget {
  final List<Map<String, dynamic>> categoryBudgets;

  const BudgetProgressCard({
    super.key,
    required this.categoryBudgets,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryBudgets.isEmpty) {
      return const SizedBox.shrink();
    }

    // 计算总预算和总支出
    double totalBudget = 0;
    double totalSpent = 0;
    for (final main in categoryBudgets) {
      totalBudget += (main['main_budget'] as double);
      totalSpent += (main['main_spent'] as double);
    }

    final overallProgress = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    final totalRemaining = totalBudget - totalSpent;
    final isOverBudget = totalRemaining < 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Color(0xFFFF9800)),
                const SizedBox(width: 8),
                const Text(
                  '分类预算进度',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOverBudget ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOverBudget ? '已超支' : '预算中',
                    style: TextStyle(
                      color: isOverBudget ? Colors.red : Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 总体进度条
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: overallProgress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget ? Colors.red : const Color(0xFFFF9800),
                ),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '已用 ¥${totalSpent.toStringAsFixed(2)} / ¥${totalBudget.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '剩余 ¥${totalRemaining.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isOverBudget ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 各主分类（可展开）
            ...categoryBudgets.map((main) => _buildMainCategory(main)),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCategory(Map<String, dynamic> main) {
    final mainName = main['main_category'] as String;
    final mainBudget = main['main_budget'] as double;
    final mainSpent = main['main_spent'] as double;
    final mainRemaining = main['main_remaining'] as double;
    final mainProgress = main['main_progress'] as double;
    final isOver = mainSpent > mainBudget;
    final color = main['main_color'] as Color;
    final icon = main['main_icon'] as String;
    final subs = (main['subcategories'] as List).cast<Map<String, dynamic>>();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ExpansionTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_getIconData(icon), color: color, size: 20),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    mainName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: Text(
                    '¥${mainSpent.toStringAsFixed(2)}/¥${mainBudget.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: mainProgress,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOver ? Colors.red : color,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '剩 ¥${mainRemaining.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: mainRemaining < 0 ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: subs.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.only(left: 56, bottom: 8),
                  child: Text(
                    '暂无子分类预算',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ]
            : subs.map((sub) => _buildSubCategoryItem(sub, color)).toList(),
        initiallyExpanded: true,
      ),
    );
  }

  Widget _buildSubCategoryItem(Map<String, dynamic> sub, Color mainColor) {
    final name = sub['name'] as String;
    final budget = sub['budget'] as double;
    final spent = sub['spent'] as double;
    final progress = sub['progress'] as double;
    final remaining = budget - spent;
    final isOver = spent > budget;
    final subIcon = sub['icon'] as String?;

    return Padding(
      padding: const EdgeInsets.only(left: 56, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (subIcon != null)
                Icon(_getIconData(subIcon), size: 14, color: mainColor.withOpacity(0.7)),
              if (subIcon != null) const SizedBox(width: 2),
              Flexible(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                flex: 2,
                child: Text(
                  '¥${spent.toStringAsFixed(2)}/¥${budget.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isOver ? Colors.red : Colors.black87,
                    fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '剩¥${(budget - spent).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: (budget - spent) < 0 ? Colors.red : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver ? Colors.red : mainColor.withOpacity(0.7),
              ),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
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
}
