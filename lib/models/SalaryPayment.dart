import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus { paid, unpaid, partiallyPaid }

class SalaryPayment {
  final String id;
  final String employeeId;
  final double baseSalary;
  final double overtimeSalary;
  final double totalSalary;
  final int overtimeHours;
  final String month;
  final DateTime paymentDate;
  final PaymentStatus status; // استبدال isPaid بـ enum
  final double? partialAmount; // المبلغ الجزئي المدفوع
  final String? notes;

  SalaryPayment({
    required this.id,
    required this.employeeId,
    required this.baseSalary,
    required this.overtimeSalary,
    required this.totalSalary,
    required this.overtimeHours,
    required this.month,
    required this.paymentDate,
    required this.status,
    this.partialAmount,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'baseSalary': baseSalary,
      'overtimeSalary': overtimeSalary,
      'totalSalary': totalSalary,
      'overtimeHours': overtimeHours,
      'month': month,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'status': status.toString().split('.').last, // حفظ كـ string في Firestore
      'partialAmount': partialAmount,
      'notes': notes,
    };
  }

  factory SalaryPayment.fromMap(Map<String, dynamic> map, String id) {
    return SalaryPayment(
      id: id,
      employeeId: map['employeeId'],
      baseSalary: map['baseSalary'],
      overtimeSalary: map['overtimeSalary'],
      totalSalary: map['totalSalary'],
      overtimeHours: map['overtimeHours'],
      month: map['month'],
      paymentDate: (map['paymentDate'] as Timestamp).toDate(),
      status: PaymentStatus.values.firstWhere(
            (e) => e.toString().split('.').last == map['status'],
        orElse: () => PaymentStatus.unpaid, // قيمة افتراضية إذا لم يتم العثور على حالة
      ),
      partialAmount: map['partialAmount'],
      notes: map['notes'],
    );
  }
}