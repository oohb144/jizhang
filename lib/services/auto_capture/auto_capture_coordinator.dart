import 'package:sqflite/sqflite.dart' hide Transaction;

import '../../database/database_helper.dart';
import '../../database/v2/pending_capture_repository.dart';
import '../../models/pending_capture.dart';
import '../../models/transaction.dart';
import 'account_matcher.dart';
import 'auto_category_classifier.dart';
import 'native_capture_bridge.dart';

class AutoCaptureCoordinator {
  final NativeCaptureBridge bridge;
  final DatabaseHelper legacyDatabase;
  final Database? pendingDatabase;
  final AccountMatcher accountMatcher;
  final AutoCategoryClassifier classifier;

  AutoCaptureCoordinator({
    this.bridge = const NativeCaptureBridge(),
    DatabaseHelper? legacyDatabase,
    this.pendingDatabase,
    this.accountMatcher = const AccountMatcher(),
    this.classifier = const AutoCategoryClassifier(),
  }) : legacyDatabase = legacyDatabase ?? DatabaseHelper.instance;

  Future<int> processPendingNativeCaptures() async {
    List<PendingCapture> captures;
    try {
      captures = await bridge.drainCandidates();
    } catch (_) {
      return 0;
    }
    if (captures.isEmpty) return 0;

    final accounts = await legacyDatabase.getAccounts();
    var posted = 0;
    final batchKeys = <String>{};

    for (final capture in captures) {
      final coarseKey = _coarseDedupKey(capture);
      if (!batchKeys.add(coarseKey)) continue;

      final account = accountMatcher.match(accounts, capture.channel);
      if (account?.id == null || capture.confidence < 0.90) {
        await _savePending(capture);
        continue;
      }

      final isIncome = capture.isIncome;
      final signedAmount = isIncome ? capture.amount.abs() : -capture.amount.abs();
      final category = classifier.classify(capture.merchant, income: isIncome);
      final merchantText = capture.merchant?.trim();
      final noteParts = <String>['自动识别', _channelLabel(capture.channel)];
      if (merchantText != null && merchantText.isNotEmpty) noteParts.add(merchantText);

      await legacyDatabase.insertTransaction(Transaction(
        accountId: account!.id!,
        amount: signedAmount,
        type: isIncome ? TransactionType.income : TransactionType.expense,
        category: category,
        merchant: merchantText,
        paymentChannel: capture.channel,
        note: noteParts.join(' · '),
        source: TransactionSource.notification,
        autoDetected: true,
        confidence: capture.confidence,
        sourceFingerprint: capture.sourceFingerprint,
        transactionDate: capture.receivedAt,
        createdAt: DateTime.now(),
      ));
      posted++;
    }
    return posted;
  }

  Future<void> _savePending(PendingCapture capture) async {
    final db = pendingDatabase;
    if (db == null) return;
    await PendingCaptureRepository(db).insertIfAbsent(capture);
  }

  String _coarseDedupKey(PendingCapture capture) {
    final twentySecondBucket = capture.receivedAt.millisecondsSinceEpoch ~/ 20000;
    final merchant = (capture.merchant ?? '').trim().toLowerCase();
    return '${capture.direction}|${capture.amount.toStringAsFixed(2)}|$merchant|$twentySecondBucket';
  }

  String _channelLabel(String channel) {
    switch (channel) {
      case 'wechat':
        return '微信';
      case 'alipay':
        return '支付宝';
      case 'unionpay':
        return '云闪付';
      case 'bank':
        return '银行卡';
      default:
        return channel;
    }
  }
}
