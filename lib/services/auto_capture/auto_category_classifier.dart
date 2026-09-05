class AutoCategoryClassifier {
  const AutoCategoryClassifier();

  String classify(String? merchant, {required bool income}) {
    if (income) return '其他收入';
    final text = (merchant ?? '').toLowerCase();
    if (text.isEmpty) return '其他';

    if (_containsAny(text, const [
      '麦当劳', '肯德基', '美团', '饿了么', '餐厅', '饭店', '食堂', '早餐', '面馆', '烧烤', '外卖'
    ])) {
      return '餐饮';
    }
    if (_containsAny(text, const [
      '蜜雪冰城', '瑞幸', '星巴克', '茶百道', '霸王茶姬', '咖啡', '奶茶'
    ])) {
      return '奶茶/咖啡';
    }
    if (_containsAny(text, const [
      '滴滴', '高德打车', '铁路', '12306', '地铁', '公交', '加油', '停车'
    ])) {
      return '交通';
    }
    if (_containsAny(text, const [
      '淘宝', '天猫', '京东', '拼多多', '超市', '便利店', '商场'
    ])) {
      return '购物';
    }
    if (_containsAny(text, const ['医院', '药房', '大药房', '诊所'])) {
      return '医疗';
    }
    if (_containsAny(text, const ['学校', '大学', '培训', '书店', '教育'])) {
      return '教育';
    }
    return '其他';
  }

  bool _containsAny(String value, List<String> keywords) {
    return keywords.any(value.contains);
  }
}
