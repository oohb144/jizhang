import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 手绘柱状图 - 每月收支对比
class BarChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyData;
  final double height;

  const BarChartWidget({
    super.key,
    required this.monthlyData,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return Center(
        child: Text('暂无数据', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
      );
    }

    final maxVal = monthlyData
        .expand((m) => [m['spending'] as double, m['income'] as double])
        .reduce((a, b) => a > b ? a : b);

    return CustomPaint(
      size: Size(double.infinity, height),
      painter: _BarChartPainter(
        data: monthlyData,
        maxVal: maxVal,
        barWidth: (double.infinity - 40) / (monthlyData.length * 2 + (monthlyData.length - 1)),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double maxVal;
  final double barWidth;

  _BarChartPainter({
    required this.data,
    required this.maxVal,
    required this.barWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (maxVal <= 0) return;

    final paintSpending = Paint()
      ..color = Colors.red.shade400
      ..style = PaintingStyle.fill;
    final paintIncome = Paint()
      ..color = Colors.green.shade400
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final chartHeight = size.height - 40;
    final double gap = barWidth * 0.2;
    final double groupWidth = barWidth * 2 + gap;
    final double startX = 40;

    // Y轴刻度线
    for (int i = 0; i <= 3; i++) {
      final y = chartHeight - (chartHeight * i / 3);
      canvas.drawLine(
        Offset(startX - 5, y),
        Offset(startX, y),
        Paint()..color = Colors.grey.shade300,
      );
      textPainter.text = TextSpan(
        text: '¥${(maxVal * i / 3).toInt()}',
        style: const TextStyle(fontSize: 9, color: Colors.grey),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 5));
    }

    for (int i = 0; i < data.length; i++) {
      final entry = data[i];
      final spending = entry['spending'] as double;
      final income = entry['income'] as double;
      final x = startX + i * (groupWidth + 10);

      // 支出柱
      final spendingHeight = maxVal > 0 ? (spending / maxVal) * chartHeight : 0;
      canvas.drawRect(
        Rect.fromLTWH(x, chartHeight - spendingHeight, barWidth, spendingHeight.toDouble()),
        paintSpending,
      );

      // 收入柱
      final incomeHeight = maxVal > 0 ? (income / maxVal) * chartHeight : 0;
      canvas.drawRect(
        Rect.fromLTWH(x + barWidth + gap, chartHeight - incomeHeight, barWidth, incomeHeight.toDouble()),
        paintIncome,
      );

      // 月份标签
      final month = entry['month'] as int;
      textPainter.text = TextSpan(
        text: '$month月',
        style: const TextStyle(fontSize: 10, color: Colors.black54),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x, chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.maxVal != maxVal;
  }
}

/// 手绘饼图 - 分类占比
class PieChartWidget extends StatelessWidget {
  final Map<String, double> categoryData;
  final String title;
  final Color defaultColor;

  const PieChartWidget({
    super.key,
    required this.categoryData,
    this.title = '分类占比',
    this.defaultColor = const Color(0xFF2196F3),
  });

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) {
      return Center(
        child: Text('暂无数据', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: Row(
            children: [
              // 饼图
              SizedBox(
                width: 160,
                child: LayoutBuilder(
                  builder: (context, constraints) => CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxWidth),
                    painter: _PieChartPainter(data: categoryData, color: defaultColor),
                  ),
                ),
              ),
              // 图例
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: categoryData.entries
                        .where((e) => e.value > 0)
                        .map((e) => _buildLegendItem(e.key, e.value, defaultColor))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, double value, Color defaultColor) {
    final color = _getCategoryColor(label, defaultColor);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '¥${value.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String name, Color defaultColor) {
    switch (name) {
      case '餐饮':
      case '早餐':
      case '午餐':
      case '晚餐':
      case '零食/夜宵':
        return Colors.orange;
      case '交通':
      case '公交/地铁':
      case '打车':
      case '加油/停车':
        return Colors.blue;
      case '生活':
      case '房租/房贷':
      case '水电燃气':
      case '通讯费':
      case '日用品':
        return Colors.green;
      case '饮料酒水':
      case '奶茶/咖啡':
      case '饮料':
      case '酒水':
        return Colors.purple;
      case '娱乐':
      case '电影/演出':
      case '游戏':
      case '运动健身':
        return Colors.pink;
      case '购物':
      case '衣物':
      case '电子产品':
      case '其他购物':
        return Colors.indigo;
      case '比赛/活动':
        return Colors.amber;
      case '其他':
        return Colors.grey;
      default:
        return defaultColor;
    }
  }
}

class _PieChartPainter extends CustomPainter {
  final Map<String, double> data;
  final Color color;

  _PieChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final total = data.values.reduce((a, b) => a + b);

    if (total <= 0) return;

    double startAngle = -math.pi / 2;

    for (final entry in data.entries) {
      if (entry.value <= 0) continue;
      final sweepAngle = (entry.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = _getColor(entry.key)
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }

    // 中间白色圆，做成甜甜圈效果
    canvas.drawCircle(
      center,
      radius * 0.55,
      Paint()..color = Colors.white,
    );
  }

  Color _getColor(String name) {
    switch (name) {
      case '餐饮':
      case '早餐':
      case '午餐':
      case '晚餐':
      case '零食/夜宵':
        return Colors.orange;
      case '交通':
      case '公交/地铁':
      case '打车':
      case '加油/停车':
        return Colors.blue;
      case '生活':
      case '房租/房贷':
      case '水电燃气':
      case '通讯费':
      case '日用品':
        return Colors.green;
      case '饮料酒水':
      case '奶茶/咖啡':
      case '饮料':
      case '酒水':
        return Colors.purple;
      case '娱乐':
      case '电影/演出':
      case '游戏':
      case '运动健身':
        return Colors.pink;
      case '购物':
      case '衣物':
      case '电子产品':
      case '其他购物':
        return Colors.indigo;
      case '比赛/活动':
        return Colors.amber;
      case '其他':
      case '医疗':
      case '教育':
      case '社交/礼物':
        return Colors.grey;
      default:
        return color;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
