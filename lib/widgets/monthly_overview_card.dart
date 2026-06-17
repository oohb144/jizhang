import 'package:flutter/material.dart';

class MonthlyOverviewCard extends StatelessWidget {
  final double monthlySpending;
  final double monthlyBudget;
  final double monthlyIncome;

  const MonthlyOverviewCard({
    super.key,
    required this.monthlySpending,
    required this.monthlyBudget,
    this.monthlyIncome = 0,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = monthlyBudget - monthlySpending;
    final isOverBudget = remaining < 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart, color: Color(0xFFFF9800)),
                SizedBox(width: 8),
                Text(
                  '本月概览',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    '总支出',
                    '¥${monthlySpending.toStringAsFixed(2)}',
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    '总收入',
                    '¥${monthlyIncome.toStringAsFixed(2)}',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    '预算剩余',
                    '¥${remaining.toStringAsFixed(2)}',
                    isOverBudget ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
