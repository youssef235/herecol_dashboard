class SalaryCategory {
  final String id;
  final String categoryName; // الاسم بالعربية
  final String categoryNameFr; // الاسم بالفرنسية
  final double fullTimeSalary;
  final double? halfTimeSalary; // اختياري
  final double? overtimeHourRate; // اختياري
  final String currency;
  final String? description;
  final bool isActive;

  SalaryCategory({
    required this.id,
    required this.categoryName,
    required this.categoryNameFr,
    required this.fullTimeSalary,
    this.halfTimeSalary, // اختياري
    this.overtimeHourRate, // اختياري
    this.currency = 'USD',
    this.description,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryName': categoryName,
      'categoryNameFr': categoryNameFr,
      'fullTimeSalary': fullTimeSalary,
      'halfTimeSalary': halfTimeSalary,
      'overtimeHourRate': overtimeHourRate,
      'currency': currency,
      'description': description,
      'isActive': isActive,
    };
  }

  factory SalaryCategory.fromMap(Map<String, dynamic> map, String id) {
    return SalaryCategory(
      id: id,
      categoryName: map['categoryName'] ?? '',
      categoryNameFr: map['categoryNameFr'] ?? '',
      fullTimeSalary: map['fullTimeSalary'] ?? 0.0,
      halfTimeSalary: map['halfTimeSalary'],
      overtimeHourRate: map['overtimeHourRate'],
      currency: map['currency'] ?? 'USD',
      description: map['description'],
      isActive: map['isActive'] ?? true,
    );
  }
}