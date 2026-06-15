import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/budget.dart';

class BudgetSettingsScreen extends StatefulWidget {
  const BudgetSettingsScreen({super.key});

  @override
  State<BudgetSettingsScreen> createState() => _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends State<BudgetSettingsScreen> {
  final _budgetController = TextEditingController();
  Budget? _currentBudget;
  double _dailyBudget = 0;
  int _daysInMonth = 0;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    final now = DateTime.now();
    final month = DateFormat('yyyy-MM').format(now);
    final budget = await DatabaseHelper.instance.getBudgetByMonth(month);

    setState(() {
      _currentBudget = budget;
      if (budget != null) {
        _budgetController.text = budget.totalAmount.toStringAsFixed(2);
        _calculateDailyBudget(budget.totalAmount);
      } else {
        _calculateDailyBudget(0);
      }
    });
  }

  void _calculateDailyBudget(double totalBudget) {
    final now = DateTime.now();
    _daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = _daysInMonth - now.day + 1;

    setState(() {
      _dailyBudget = remainingDays > 0 ? totalBudget / remainingDays : 0;
    });
  }

  Future<void> _saveBudget() async {
    if (_budgetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入预算金额')),
      );
      return;
    }

    final totalBudget = double.tryParse(_budgetController.text);
    if (totalBudget == null || totalBudget < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效金额')),
      );
      return;
    }

    final now = DateTime.now();
    final month = DateFormat('yyyy-MM').format(now);

    final budget = Budget(
      id: _currentBudget?.id,
      month: month,
      totalAmount: totalBudget,
      dailyAmount: _dailyBudget,
      createdAt: _currentBudget?.createdAt ?? DateTime.now(),
    );

    if (_currentBudget != null) {
      await DatabaseHelper.instance.updateBudget(budget);
    } else {
      await DatabaseHelper.instance.insertBudget(budget);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('预算已保存')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = DateFormat('yyyy年M月').format(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('预算设置'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 月度总预算
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
                        const Icon(Icons.calendar_month, color: Color(0xFF2196F3)),
                        const SizedBox(width: 8),
                        Text(
                          '$month 预算',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _budgetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onChanged: (value) {
                        final budget = double.tryParse(value) ?? 0;
                        _calculateDailyBudget(budget);
                      },
                      decoration: InputDecoration(
                        labelText: '月度总预算',
                        prefixText: '¥ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 预算分配详情
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.pie_chart_outline, color: Color(0xFFFF9800)),
                        SizedBox(width: 8),
                        Text(
                          '预算分配',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('本月', '$month'),
                    const Divider(),
                    _buildInfoRow('本月天数', '$_daysInMonth 天'),
                    const Divider(),
                    _buildInfoRow('今日日期', DateFormat('yyyy-MM-dd').format(now)),
                    const Divider(),
                    _buildInfoRow('剩余天数', '${_daysInMonth - now.day + 1} 天'),
                    const Divider(),
                    _buildInfoRow(
                      '每日预算',
                      '¥${_dailyBudget.toStringAsFixed(2)}',
                      valueColor: const Color(0xFF2196F3),
                      valueFontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 提示信息
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF2196F3)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '系统会自动将月度预算平均分配到剩余天数，帮助你合理控制每日开支。',
                        style: TextStyle(
                          color: Color(0xFF2196F3),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveBudget,
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

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    FontWeight? valueFontWeight,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor,
              fontWeight: valueFontWeight,
            ),
          ),
        ],
      ),
    );
  }
}
