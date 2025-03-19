import 'package:cloud_firestore/cloud_firestore.dart';

class SalaryPayment {
  final String id;
  final String employeeId;
  final double baseSalary;
  final double overtimeSalary;
  final double totalSalary;
  final int overtimeHours;
  final String month;
  final DateTime paymentDate;
  final bool isPaid;
  final String? notes; // جديد

  SalaryPayment({
    required this.id,
    required this.employeeId,
    required this.baseSalary,
    required this.overtimeSalary,
    required this.totalSalary,
    required this.overtimeHours,
    required this.month,
    required this.paymentDate,
    required this.isPaid,
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
      'isPaid': isPaid,
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
      isPaid: map['isPaid'],
      notes: map['notes'],
    );
  }
}