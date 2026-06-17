import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart' as model;
import '../database/database_helper.dart';

class TransactionList extends StatelessWidget {
  final List<model.Transaction> transactions;

  const TransactionList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '暂无交易记录',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.history, color: Color(0xFF2196F3)),
                SizedBox(width: 8),
                Text(
                  '最近交易',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildTransactionItem(transaction);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(model.Transaction transaction) {
    final isExpense = transaction.amount < 0;
    final amountColor = isExpense ? Colors.red : Colors.green;
    final icon = _getCategoryIcon(transaction.category);
    final iconColor = _getCategoryColor(transaction.category);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        transaction.subcategory ?? transaction.category,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        transaction.note ?? transaction.category,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isExpense ? '-' : '+'}¥${transaction.amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color: amountColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            DateFormat('MM/dd HH:mm').format(transaction.transactionDate),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
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
      case '工资':
        return Icons.payments;
      case '投资理财':
        return Icons.trending_up;
      case '其他收入':
        return Icons.add_circle;
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
}
