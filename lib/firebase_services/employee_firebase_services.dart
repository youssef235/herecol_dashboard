import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee_model.dart';

class EmployeeFirebaseServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Map<String, List<String>> defaultPermissions = {
    'finance': [
      'AccountingManagementScreen',
      'FeesManagementScreen',
      'LatePaymentsScreen',
      'EmployeeList',
      'SchoolInfoScreen',
    ],
    'teacher': [
      'StudentListScreen',
      'AddStudentScreen',
      'AttendanceManagementScreen',
      'SchoolInfoScreen',
    ],
    'school': [],
    'admin': [],
  };

  Future<void> addEmployee(Employee employee, String schoolId) async {
    final permissions = employee.permissions.isEmpty
        ? defaultPermissions[employee.role] ?? []
        : employee.permissions;

    await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('employees')
        .doc(employee.id)
        .set({
      ...employee.toMap(),
      'permissions': permissions,
      'salaryCategoryId': employee.salaryCategoryId,
    });
  }

  Future<List<Employee>> getEmployees(String schoolId, {String? role}) async {
    try {
      Query query = _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('employees');

      if (role != null) {
        query = query.where('role', isEqualTo: role);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        return Employee.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception("خطأ في تحميل الموظفين: $e");
    }
  }

  Future<void> updateEmployee(Employee employee, String schoolId) async {
    await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('employees')
        .doc(employee.id)
        .update(employee.toMap());
  }

  Future<void> deleteEmployee(String employeeId, String schoolId) async {
    await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('employees')
        .doc(employeeId)
        .delete();
  }

  Future<QuerySnapshot> getAllSchools() async {
    return await _firestore.collection('schools').get();
  }
}