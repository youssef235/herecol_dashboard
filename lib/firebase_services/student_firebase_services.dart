import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';

class StudentFirebaseServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<void> addStudent(Student student) async {
    await _firestore
        .collection('schools')
        .doc(student.schoolId)
        .collection('students')
        .doc(student.id)
        .set(student.toFirestore());
  }

  Future<List<Student>> getSchoolStudents(String schoolId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .get();
      return snapshot.docs.map((doc) {
        return Student.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception("خطأ في تحميل الطلاب: $e");
    }
  }

  // دالة جديدة لتدفق الطلاب في الوقت الفعلي
  Stream<List<Student>> streamSchoolStudents(String schoolId) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      return Student.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }).toList());
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

  Future<void> updateStudentFees({
    required String schoolId,
    required String studentId,
    required double feesDue,
    required double feesPaid,
  }) async {
    try {
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .doc(studentId)
          .update({
        'feesDue': feesDue,
        'feesPaid': feesPaid,
      });
    } catch (e) {
      throw Exception("خطأ في تحديث المصاريف: $e");
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
        return Student.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
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
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .doc(studentId)
          .delete();
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
}