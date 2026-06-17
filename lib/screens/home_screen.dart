import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/account.dart';
import '../models/transaction.dart' as model;
import '../models/budget.dart';
import '../models/category_budget.dart';
import '../widgets/account_card.dart';
import '../widgets/budget_card.dart';
import '../widgets/monthly_overview_card.dart';
import '../widgets/transaction_list.dart';
import 'add_transaction_screen.dart';
import 'account_settings_screen.dart';
import 'category_budget_screen.dart';
import 'transaction_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Account> _accounts = [];
  List<model.Transaction> _transactions = [];
  Budget? _budget;
  double _todaySpending = 0;
  double _monthSpending = 0;
  double _monthIncome = 0;
  double _dailyBudget = 0;
  Map<String, double> _categorySpending = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final accounts = await DatabaseHelper.instance.getAccounts();
    final transactions = await DatabaseHelper.instance.getTransactions(limit: 10);
    final now = DateTime.now();
    final month = DateFormat('yyyy-MM').format(now);
    final budget = await DatabaseHelper.instance.getBudgetByMonth(month);
    final todaySpending = await DatabaseHelper.instance.getTodaySpending();
    final monthSpending = await DatabaseHelper.instance.getMonthSpending(now.year, now.month);
    final monthIncome = await DatabaseHelper.instance.getMonthIncome(now.year, now.month);
    final categorySpending = await DatabaseHelper.instance.getCategorySpending(now.year, now.month);

    double dailyBudget = 0;
    if (budget != null) {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final remainingDays = daysInMonth - now.day + 1;
      dailyBudget = remainingDays > 0 ? budget.totalAmount / remainingDays : 0;
    }

    setState(() {
      _accounts = accounts;
      _transactions = transactions;
      _budget = budget;
      _todaySpending = todaySpending;
      _monthSpending = monthSpending;
      _monthIncome = monthIncome;
      _dailyBudget = dailyBudget;
      _categorySpending = categorySpending;
    });
  }

  double get _totalBalance {
    return _accounts.fold(0, (sum, account) => sum + account.balance);
  }

  Future<void> _navigateToAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _navigateToAccountSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AccountSettingsScreen()),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _navigateToCategoryBudget() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoryBudgetScreen()),
    );
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('记账本'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: _navigateToAccountSettings,
            tooltip: '账户设置',
          ),
          IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: _navigateToCategoryBudget,
            tooltip: '预算管理',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 总资产卡片
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '总资产',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: _navigateToAccountSettings,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    '设置余额',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¥${_totalBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 账户卡片
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _accounts.map((account) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: AccountCard(account: account),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // 今日预算卡片
              BudgetCard(
                dailyBudget: _dailyBudget,
                todaySpending: _todaySpending,
              ),
              const SizedBox(height: 16),

              // 本月概览
              MonthlyOverviewCard(
                monthlySpending: _monthSpending,
                monthlyBudget: _budget?.totalAmount ?? 0,
                monthlyIncome: _monthIncome,
              ),
              const SizedBox(height: 16),

              // 快捷操作
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickAction(
                        icon: Icons.account_balance_wallet,
                        label: '账户设置',
                        color: const Color(0xFF2196F3),
                        onTap: _navigateToAccountSettings,
                      ),
                      _buildQuickAction(
                        icon: Icons.pie_chart,
                        label: '预算管理',
                        color: const Color(0xFFFF9800),
                        onTap: _navigateToCategoryBudget,
                      ),
                      _buildQuickAction(
                        icon: Icons.history,
                        label: '交易记录',
                        color: const Color(0xFF4CAF50),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 最近交易
              TransactionList(transactions: _transactions),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddTransaction,
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          '记账',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
