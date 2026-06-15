class CategoryBudget {
  final int? id;
  final String month;
  final String categoryName;
  final double budgetAmount;
  final double usedAmount;

  CategoryBudget({
    this.id,
    required this.month,
    required this.categoryName,
    required this.budgetAmount,
    this.usedAmount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'month': month,
      'category_name': categoryName,
      'budget_amount': budgetAmount,
      'used_amount': usedAmount,
    };
  }

  factory CategoryBudget.fromMap(Map<String, dynamic> map) {
    return CategoryBudget(
      id: map['id'] as int?,
      month: map['month'] as String,
      categoryName: map['category_name'] as String,
      budgetAmount: (map['budget_amount'] as num).toDouble(),
      usedAmount: (map['used_amount'] as num?)?.toDouble() ?? 0,
    );
  }
}
