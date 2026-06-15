class Category {
  final int? id;
  final String name;
  final String? parentName; // 一级分类名称，null表示是一级分类
  final String icon;
  final int sortOrder;

  Category({
    this.id,
    required this.name,
    this.parentName,
    required this.icon,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parent_name': parentName,
      'icon': icon,
      'sort_order': sortOrder,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      parentName: map['parent_name'] as String?,
      icon: map['icon'] as String,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }
}
