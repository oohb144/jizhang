import 'package:flutter/material.dart';

class BudgetCard extends StatelessWidget {
  final double dailyBudget;
  final double todaySpending;

  const BudgetCard({
    super.key,
    required this.dailyBudget,
    required this.todaySpending,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = dailyBudget - todaySpending;
    final progress = dailyBudget > 0 ? (todaySpending / dailyBudget).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = remaining < 0;

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
                const Icon(Icons.calendar_today, color: Color(0xFF2196F3)),
                const SizedBox(width: 8),
                const Text(
                  '今日预算',
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
                    isOverBudget ? '超支' : '正常',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('预算', '¥${dailyBudget.toStringAsFixed(2)}'),
                _buildInfoItem('已用', '¥${todaySpending.toStringAsFixed(2)}'),
                _buildInfoItem(
                  '剩余',
                  '¥${remaining.toStringAsFixed(2)}',
                  valueColor: isOverBudget ? Colors.red : Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget ? Colors.red : const Color(0xFF2196F3),
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
