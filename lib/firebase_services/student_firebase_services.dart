import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:school_management_dashboard/models/fee_structure_model.dart';
import '../models/Payment.dart';
import '../models/student_model.dart';

class StudentFirebaseServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> generateStudentId(String schoolId, String academicYear) async {
    final yearPrefix = academicYear.split('-')[0].substring(2);
    final snapshot = await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .where('academicYear', isEqualTo: academicYear)
        .get();
    final studentCount = snapshot.docs.length + 1;
    return '$yearPrefix${studentCount.toString().padLeft(4, '0')}'; // e.g., 250001
  }

  Future<void> updatePayment({
    required String schoolId,
    required String studentId,
    required Payment payment,
  }) async {
    try {
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .doc(studentId)
          .collection('payments')
          .doc(payment.id)
          .update(payment.toFirestore());
    } catch (e) {
      throw Exception("خطأ في تعديل الدفع: $e");
    }
  }

  Future<void> deletePayment({
    required String schoolId,
    required String studentId,
    required String paymentId,
  }) async {
    try {
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .doc(studentId)
          .collection('payments')
          .doc(paymentId)
          .delete();
    } catch (e) {
      throw Exception("خطأ في حذف الدفع: $e");
    }
  }

  Future<void> addStudent(Student student) async {
    // جلب FeeStructure بناءً على الصف
    final feeStructure = await getFeeStructureForStudent(student.schoolId, student.gradeAr);
    final totalFeesDue = feeStructure?.installments.fold<double>(0, (sum, i) => sum + i.amount) ?? 0.0;

    // إضافة totalFeesDue إلى بيانات الطالب
    final studentData = student.toFirestore();
    studentData['totalFeesDue'] = totalFeesDue;

    await _firestore
        .collection('schools')
        .doc(student.schoolId)
        .collection('students')
        .doc(student.id)
        .set(studentData);
  }

  Future<List<Student>> getSchoolStudents(String schoolId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .get();
      // Map each document to a Future<Student> and collect them into a List<Future<Student>>
      List<Future<Student>> studentFutures = snapshot.docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        final feeStructure = await getFeeStructureForStudent(schoolId, data['gradeAr']);
        return Student.fromFirestore(data, doc.id, feeStructure);
      }).toList();

      // Use Future.wait to wait for all futures to complete and return a List<Student>
      return await Future.wait(studentFutures);
    } catch (e) {
      throw Exception("خطأ في تحميل الطلاب: $e");
    }
  }
  Stream<List<Student>> streamSchoolStudents(String schoolId) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .snapshots()
        .asyncMap((snapshot) async {
      final students = <Student>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final feeStructure = await getFeeStructureForStudent(schoolId, data['gradeAr']);
        students.add(Student.fromFirestore(data, doc.id, feeStructure));
      }
      return students;
    });
  }

  Stream<List<Student>> streamAllStudents() {
    return _firestore.collectionGroup('students').snapshots().asyncMap((snapshot) async {
      final students = <Student>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final schoolId = data['schoolId'];
        final feeStructure = await getFeeStructureForStudent(schoolId, data['gradeAr']);
        students.add(Student.fromFirestore(data, doc.id, feeStructure));
      }
      return students;
    });
  }

  Future<FeeStructure?> getFeeStructureForStudent(String schoolId, String gradeAr) async {
    final snapshot = await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('feeStructures')
        .where('gradeAr', isEqualTo: gradeAr)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return FeeStructure.fromFirestore(snapshot.docs.first.data(), snapshot.docs.first.id);
    }
    return null;
  }

  Future<void> updateStudentFees({
    required String schoolId,
    required String studentId,
    required double totalFeesDue,
    required double feesPaid,
  }) async {
    try {
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .doc(studentId)
          .update({
        'totalFeesDue': totalFeesDue,
        'feesPaid': feesPaid,
      });
    } catch (e) {
      throw Exception("خطأ في تحديث المصاريف: $e");
    }
  }
  Future<void> updateStudentAttendance({
    required String schoolId,
    required String studentId,
    required String date,
    required String attendance,
  }) async {
    try {
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .doc(studentId)
          .update({
        'attendanceHistory.$date': attendance,
      });
    } catch (e) {
      throw Exception("خطأ في تحديث الحضور: $e");
    }
  }


  Future<Student> getStudentById({
    required String schoolId,
    required String studentId,
  }) async {
    try {
      final doc = await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .doc(studentId)
          .get();
      if (doc.exists) {
        final feeStructure = await getFeeStructureForStudent(schoolId, doc.data()!['gradeAr']);
        return Student.fromFirestore(doc.data() as Map<String, dynamic>, doc.id, feeStructure);
      } else {
        throw Exception("الطالب غير موجود");
      }
    } catch (e) {
      throw Exception("خطأ في تحميل بيانات الطالب: $e");
    }
  }

  Future<void> deleteStudent({
    required String schoolId,
    required String studentId,
  }) async {
    try {
      // جلب بيانات الطالب للحصول على رابط الصورة
      final studentDoc = await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .doc(studentId)
          .get();

      if (studentDoc.exists) {
        final studentData = studentDoc.data() as Map<String, dynamic>;
        final profileImageUrl = studentData['profileImage'] as String?;

        // حذف الصورة من Firebase Storage إذا كانت موجودة
        if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
          final storageRef = _storage.refFromURL(profileImageUrl);
          await storageRef.delete();
        }

        // حذف بيانات الطالب من Firestore
        await _firestore
            .collection('schools')
            .doc(schoolId)
            .collection('students')
            .doc(studentId)
            .delete();
      }
    } catch (e) {
      throw Exception("خطأ في حذف الطالب: $e");
    }
  }

  Future<void> updateStudent({
    required String schoolId,
    required String studentId,
    required Student student,
  }) async {
    try {
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .doc(studentId)
          .update(student.toFirestore());
    } catch (e) {
      throw Exception("خطأ في تحديث بيانات الطالب: $e");
    }
  }

  Future<void> addPayment({
    required String schoolId,
    required String studentId,
    required Payment payment,
  }) async {
    try {
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .doc(studentId)
          .collection('payments')
          .doc(payment.id)
          .set(payment.toFirestore());
    } catch (e) {
      throw Exception("خطأ في إضافة الدفع: $e");
    }
  }

  Future<List<Payment>> getPayments({
    required String schoolId,
    required String studentId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .doc(studentId)
          .collection('payments')
          .get();
      return snapshot.docs.map((doc) {
        return Payment.fromFirestore(doc.data());
      }).toList();
    } catch (e) {
      throw Exception("خطأ في جلب المدفوعات: $e");
    }
  }

  Future<void> addFeeStructure({
    required String schoolId,
    required FeeStructure feeStructure,
  }) async {
    try {
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('feeStructures')
          .doc(feeStructure.id)
          .set(feeStructure.toFirestore());
    } catch (e) {
      throw Exception("خطأ في إضافة هيكل المصاريف: $e");
    }
  }

  Future<List<FeeStructure>> getFeeStructures(String schoolId) async {
    try {
      final snapshot = await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('feeStructures')
          .get();
      return snapshot.docs.map((doc) {
        return FeeStructure.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception("خطأ في جلب هياكل المصاريف: $e");
    }
  }

  Future<void> updateFeeStructure({
    required String schoolId,
    required FeeStructure feeStructure,
  }) async {
    try {
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('feeStructures')
          .doc(feeStructure.id)
          .update(feeStructure.toFirestore());
    } catch (e) {
      throw Exception("خطأ في تحديث هيكل المصاريف: $e");
    }
  }
}