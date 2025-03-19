class FeeStructure {
  final String id;
  final String gradeAr; // الصف بالعربية
  final String gradeFr; // الصف بالفرنسية
  final List<Installment> installments; // قائمة الأقساط
  final int installmentCount; // عدد الأقساط

  FeeStructure({
    required this.id,
    required this.gradeAr,
    required this.gradeFr,
    required this.installments,
    required this.installmentCount,
  });

  factory FeeStructure.fromFirestore(Map<String, dynamic> data, String id) {
    return FeeStructure(
      id: id,
      gradeAr: data['gradeAr'] ?? '',
      gradeFr: data['gradeFr'] ?? '',
      installments: (data['installments'] as List<dynamic>?)
          ?.map((item) => Installment.fromMap(item as Map<String, dynamic>))
          .toList() ??
          [],
      installmentCount: data['installmentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'gradeAr': gradeAr,
      'gradeFr': gradeFr,
      'installments': installments.map((i) => i.toMap()).toList(),
      'installmentCount': installmentCount,
    };
  }
}

class Installment {
  final String id;
  final double amount;
  final DateTime dueDate;

  Installment({
    required this.id,
    required this.amount,
    required this.dueDate,
  });

  factory Installment.fromMap(Map<String, dynamic> data) {
    return Installment(
      id: data['id'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: DateTime.parse(data['dueDate'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
    };
  }
}