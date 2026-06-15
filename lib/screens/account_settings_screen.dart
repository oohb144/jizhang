import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/account.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  List<Account> _accounts = [];
  Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await DatabaseHelper.instance.getAccounts();
    setState(() {
      _accounts = accounts;
      _controllers = {};
      for (final account in accounts) {
        _controllers[account.id!] = TextEditingController(
          text: account.balance.toStringAsFixed(2),
        );
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveBalances() async {
    for (final account in _accounts) {
      final controller = _controllers[account.id!];
      if (controller != null) {
        final balance = double.tryParse(controller.text) ?? 0;
        await DatabaseHelper.instance.setAccountBalance(account.id!, balance);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('余额已保存')),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _addNewAccount() async {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加账户'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '账户名称',
                hintText: '例如：银行卡、现金',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: '初始余额',
                prefixText: '¥ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final account = Account(
        name: nameController.text,
        balance: double.tryParse(balanceController.text) ?? 0,
        icon: 'wallet',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await DatabaseHelper.instance.insertAccount(account);
      _loadAccounts();
    }
  }

  IconData _getAccountIcon(String name) {
    switch (name) {
      case '微信':
        return Icons.chat;
      case '支付宝':
        return Icons.account_balance_wallet;
      case '银行卡':
        return Icons.credit_card;
      case '现金':
        return Icons.money;
      default:
        return Icons.account_balance;
    }
  }

  Color _getAccountColor(String name) {
    switch (name) {
      case '微信':
        return const Color(0xFF07C160);
      case '支付宝':
        return const Color(0xFF1677FF);
      case '银行卡':
        return const Color(0xFFE91E63);
      case '现金':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF9C27B0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('账户余额设置'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        Icon(Icons.account_balance_wallet, color: Color(0xFF2196F3)),
                        SizedBox(width: 8),
                        Text(
                          '设置各账户余额',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '请输入你当前各账户的实际余额',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._accounts.map((account) => _buildAccountField(account)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 添加新账户按钮
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addNewAccount,
                icon: const Icon(Icons.add),
                label: const Text('添加新账户'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveBalances,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '保存余额',
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

  Widget _buildAccountField(Account account) {
    final color = _getAccountColor(account.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getAccountIcon(account.name),
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _controllers[account.id!],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      prefixText: '¥ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
