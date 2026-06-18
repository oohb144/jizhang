import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../utils/chart_helpers.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _isLoading = true;
  Map<String, dynamic>? _monthSummary;
  List<Map<String, dynamic>> _monthlyTrend = [];
  List<Map<String, dynamic>> _monthTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final summary = await DatabaseHelper.instance.getMonthSummary(_selectedYear, _selectedMonth);
    final trend = await DatabaseHelper.instance.getMonthlyTrend(_selectedYear);
    final transactions = await DatabaseHelper.instance.getTransactionsByMonth(_selectedYear, _selectedMonth);

    // 按日期分组
    Map<String, List<dynamic>> grouped = {};
    for (final t in transactions) {
      final dateKey = DateFormat('MM-dd').format(t.transactionDate);
      grouped.putIfAbsent(dateKey, () => []).add(t);
    }

    setState(() {
      _monthSummary = summary;
      _monthlyTrend = trend;
      _monthTransactions = grouped.entries
          .map((e) => {'date': e.key, 'transactions': e.value})
          .toList()
        ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('历史记录'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 年月选择器
                  _buildDatePicker(),
                  const SizedBox(height: 16),

                  // 统计摘要卡片
                  _buildSummaryCard(),
                  const SizedBox(height: 16),

                  // 月度趋势柱状图
                  if (_monthlyTrend.length > 1) ...[
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '年度收支趋势',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _legendItem(Colors.red.shade400, '支出'),
                                const SizedBox(width: 16),
                                _legendItem(Colors.green.shade400, '收入'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            BarChartWidget(
                              monthlyData: _monthlyTrend,
                              height: 180,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 分类支出饼图
                  if ((_monthSummary!['spending_by_category'] as Map<String, dynamic>).isNotEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: PieChartWidget(
                          categoryData: _monthSummary!['spending_by_category'] as Map<String, double>,
                          title: '分类支出占比',
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // 当日交易列表
                  const Text(
                    '交易明细',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._monthTransactions.map((entry) => _buildDateGroup(entry)),
                ],
              ),
            ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 年份选择
            Expanded(
              child: _buildPickerSegment(
                label: '年',
                value: _selectedYear,
                min: 2020,
                max: DateTime.now().year + 1,
                onChanged: (val) {
                  setState(() => _selectedYear = val!);
                  _loadData();
                },
              ),
            ),
            const SizedBox(width: 12),
            // 月份选择
            Expanded(
              child: _buildPickerSegment(
                label: '月',
                value: _selectedMonth,
                min: 1,
                max: 12,
                onChanged: (val) {
                  setState(() => _selectedMonth = val!);
                  _loadData();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerSegment({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: List.generate(max - min + 1, (i) => min + i)
          .map((v) => DropdownMenuItem(value: v, child: Text('$v${label == '年' ? '年' : '月'}')))
          .toList(),
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
    );
  }

  Widget _buildSummaryCard() {
    final spending = _monthSummary?['total_spending'] ?? 0.0;
    final income = _monthSummary?['total_income'] ?? 0.0;
    final budgetTotal = _monthSummary?['budget_total'] ?? 0.0;
    final budgetRemaining = budgetTotal - spending;
    final isOverBudget = budgetTotal > 0 && budgetRemaining < 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_selectedYear}年${_selectedMonth.toString().padLeft(2, '0')}月 概览',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _summaryItem('总支出', spending, Colors.red),
                _summaryItem('总收入', income, Colors.green),
              ],
            ),
            if (budgetTotal > 0) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 4),
              Row(
                children: [
                  _summaryItem('预算总额', budgetTotal, const Color(0xFF2196F3)),
                  _summaryItem(
                    '预算剩余',
                    budgetRemaining,
                    isOverBudget ? Colors.red : Colors.green,
                  ),
                ],
              ),
              // 预算进度条
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: budgetTotal > 0 ? (spending / budgetTotal).clamp(0.0, 1.0) : 0,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverBudget ? Colors.red : const Color(0xFF2196F3),
                  ),
                  minHeight: 6,
                ),
              ),
              if (isOverBudget)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '超出预算 ¥${budgetRemaining.abs().toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.red, fontSize: 11),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, double value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            '¥${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateGroup(Map<String, dynamic> entry) {
    final date = entry['date'] as String;
    final transactions = entry['transactions'] as List;

    double dayExpense = 0;
    double dayIncome = 0;
    for (final t in transactions) {
      final amount = t.amount;
      if (amount < 0) dayExpense += amount.abs();
      if (amount > 0) dayIncome += amount;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ExpansionTile(
          title: Row(
            children: [
              Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (dayExpense > 0)
                Text('-¥${dayExpense.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontSize: 12)),
              if (dayExpense > 0 && dayIncome > 0) const SizedBox(width: 8),
              if (dayIncome > 0)
                Text('+¥${dayIncome.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontSize: 12)),
            ],
          ),
          children: transactions.map((t) => _buildTransactionItem(t)).toList(),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(dynamic t) {
    final amount = t.amount;
    final isExpense = amount < 0;
    final category = t.subcategory ?? t.category;
    final note = t.note;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: (isExpense ? Colors.red : Colors.green).withOpacity(0.1),
        child: Icon(
          isExpense ? Icons.arrow_downward : Icons.arrow_upward,
          size: 16,
          color: isExpense ? Colors.red : Colors.green,
        ),
      ),
      title: Text(
        category,
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: note != null && note.isNotEmpty ? Text(note, style: const TextStyle(fontSize: 11)) : null,
      trailing: Text(
        '${isExpense ? '-' : '+'}¥${amount.abs().toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isExpense ? Colors.red : Colors.green,
        ),
      ),
    );
  }
}
