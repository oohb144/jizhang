import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart' as model;

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<model.Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final transactions = await DatabaseHelper.instance.getTransactions();
    setState(() {
      _transactions = transactions;
    });
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '餐饮':
        return Icons.restaurant;
      case '交通':
        return Icons.directions_car;
      case '生活':
        return Icons.home;
      case '饮料酒水':
        return Icons.local_bar;
      case '比赛/活动':
        return Icons.emoji_events;
      case '娱乐':
        return Icons.movie;
      case '购物':
        return Icons.shopping_bag;
      case '其他':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
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
    // 按日期分组
    Map<String, List<model.Transaction>> grouped = {};
    for (final t in _transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(t.transactionDate);
      grouped.putIfAbsent(dateKey, () => []).add(t);
    }
    final dateKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('交易记录'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: _transactions.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无交易记录', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dateKeys.length,
              itemBuilder: (context, index) {
                final dateKey = dateKeys[index];
                final items = grouped[dateKey]!;
                final dayTotal = items
                    .where((t) => t.amount < 0)
                    .fold<double>(0, (sum, t) => sum + t.amount);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateKey,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '支出 ¥${dayTotal.abs().toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final t = items[i];
                          final isExpense = t.amount < 0;
                          final icon = _getCategoryIcon(t.category);
                          final color = _getCategoryColor(t.category);

                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            title: Text(
                              t.subcategory ?? t.category,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              t.note ?? t.category,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isExpense ? '-' : '+'}¥${t.amount.abs().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isExpense ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  DateFormat('HH:mm').format(t.transactionDate),
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
    );
  }
}
