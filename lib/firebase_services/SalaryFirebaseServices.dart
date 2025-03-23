import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/SalaryCategory.dart';
import '../models/SalaryPayment.dart';

class SalaryFirebaseServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addSalaryCategory(SalaryCategory category, String schoolId) async {
    final existing = await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('salaryCategories')
        .where('categoryName', isEqualTo: category.categoryName)
        .where('isActive', isEqualTo: true)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('فئة الراتب موجودة بالفعل');
    }
    await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('salaryCategories')
        .doc(category.id)
        .set(category.toMap());
  }

  Future<void> updateSalaryCategory(SalaryCategory category, String schoolId) async {
    await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('salaryCategories')
        .doc(category.id)
        .update(category.toMap());
  }

  Future<void> deleteSalaryCategory(String categoryId, String schoolId) async {
    await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('salaryCategories')
        .doc(categoryId)
        .update({'isActive': false}); // حذف ناعم بتعيين isActive إلى false
  }

  Stream<List<SalaryCategory>> getSalaryCategories(String schoolId) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('salaryCategories')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => SalaryCategory.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<SalaryCategory> getSalaryCategory(String schoolId, String categoryId) async {
    DocumentSnapshot doc = await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('salaryCategories')
        .doc(categoryId)
        .get();
    return SalaryCategory.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<void> paySalary(SalaryPayment payment, String schoolId) async {
    await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('salaryPayments')
        .doc(payment.id)
        .set(payment.toMap());
  }

  Future<List<SalaryPayment>> getSalaryPayments(String schoolId, String month) async {
    QuerySnapshot snapshot = await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('salaryPayments')
        .where('month', isEqualTo: month)
        .get();
    return snapshot.docs
        .map((doc) => SalaryPayment.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<void> updatePaymentStatus(String schoolId, String paymentId, PaymentStatus status) async {
    await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('salaryPayments')
        .doc(paymentId)
        .update({
      'status': status.toString().split('.').last, // تحويل enum إلى string
    });
  }
}