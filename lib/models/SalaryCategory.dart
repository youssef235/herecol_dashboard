class SalaryCategory {
  final String id;
  final String categoryName;
  final double fullTimeSalary;
  final double halfTimeSalary;
  final double overtimeHourRate;
  final String currency; // جديد
  final String? description; // جديد
  final bool isActive; // جديد

  SalaryCategory({
    required this.id,
    required this.categoryName,
    required this.fullTimeSalary,
    required this.halfTimeSalary,
    required this.overtimeHourRate,
    this.currency = 'USD', // افتراضي
    this.description,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryName': categoryName,
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
      categoryName: map['categoryName'],
      fullTimeSalary: map['fullTimeSalary'],
      halfTimeSalary: map['halfTimeSalary'],
      overtimeHourRate: map['overtimeHourRate'],
      currency: map['currency'] ?? 'USD',
      description: map['description'],
      isActive: map['isActive'] ?? true,
    );
  }
}