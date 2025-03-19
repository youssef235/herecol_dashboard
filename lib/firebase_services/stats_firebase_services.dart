import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/stats_model.dart';
import 'dart:developer' as developer;

class StatsFirebaseServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Stats> getStats({String? schoolId}) async {
    try {
      Map<String, int> studentsPerGrade = {};
      Map<String, int> studentsPerSchool = {};
      Map<String, int> employeesPerDepartment = {};
      Map<String, int> employeesPerSubDepartment = {};
      Map<String, int> employeesPerSchool = {};
      int totalStudents = 0;
      int totalEmployees = 0;
      int totalTeachers = 0;
      int totalAccountants = 0;
      int totalSchools = 0;
      int presentStudents = 0;
      int absentStudents = 0;
      double totalFeesDue = 0.0;
      int maleStudents = 0;
      int femaleStudents = 0;
      Map<String, Map<String, String>> schoolNames = {};

      if (schoolId != null) {
        // إحصائيات لمدرسة محددة
        final schoolDoc = await _firestore.collection('schools').doc(schoolId).get();
        if (!schoolDoc.exists) throw Exception('المدرسة غير موجودة');

        // جلب بيانات الطلاب
        final studentsSnapshot = await _firestore
            .collection('schools')
            .doc(schoolId)
            .collection('students')
            .get();
        totalStudents = studentsSnapshot.size;
        studentsPerSchool[schoolId] = totalStudents;

        for (var studentDoc in studentsSnapshot.docs) {
          final gradeAr = studentDoc.get('gradeAr') as String? ?? 'غير محدد';
          final genderAr = studentDoc.get('genderAr') as String? ?? 'غير محدد';
          final attendanceMap = studentDoc.get('attendanceHistory') as Map<String, dynamic>?;
          final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final attendance = attendanceMap?[today] ?? 'غير محدد';
          final feesDue = studentDoc.get('feesDue') as double? ?? 0.0;

          studentsPerGrade[gradeAr] = (studentsPerGrade[gradeAr] ?? 0) + 1;
          totalFeesDue += feesDue;

          if (genderAr.trim().toLowerCase() == 'ذكر') maleStudents++;
          else if (genderAr.trim().toLowerCase() == 'أنثى') femaleStudents++;

          if (attendance.trim().toLowerCase() == 'حاضر') presentStudents++;
          else if (attendance.trim().toLowerCase() == 'غائب') absentStudents++;
        }

        // جلب بيانات الموظفين
        final employeesSnapshot = await _firestore
            .collection('schools')
            .doc(schoolId)
            .collection('employees')
            .get();
        totalEmployees = employeesSnapshot.size;
        employeesPerSchool[schoolId] = totalEmployees;

        for (var employeeDoc in employeesSnapshot.docs) {
          final role = employeeDoc.get('role') as String? ?? 'unknown';
          final departmentAr = employeeDoc.get('departmentAr') as String? ?? 'غير محدد';
          final subDepartmentAr = employeeDoc.get('subDepartmentAr') as String? ?? 'غير محدد';

          employeesPerDepartment[departmentAr] = (employeesPerDepartment[departmentAr] ?? 0) + 1;
          employeesPerSubDepartment[subDepartmentAr] = (employeesPerSubDepartment[subDepartmentAr] ?? 0) + 1;

          if (role.trim().toLowerCase() == 'teacher') totalTeachers++;
          else if (role.trim().toLowerCase() == 'accounting') totalAccountants++;
        }

        final schoolNameMap = schoolDoc.get('schoolName') as Map<String, dynamic>? ?? {'ar': 'مدرسة بدون اسم', 'fr': 'École sans nom'};
        schoolNames[schoolId] = {
          'ar': schoolNameMap['ar'] as String? ?? 'مدرسة بدون اسم',
          'fr': schoolNameMap['fr'] as String? ?? 'École sans nom',
        };

        totalSchools = 1;
      } else {
        // إحصائيات لجميع المدارس (للأدمن)
        final schoolsSnapshot = await _firestore.collection('schools').get();
        totalSchools = schoolsSnapshot.size;

        for (var schoolDoc in schoolsSnapshot.docs) {
          final currentSchoolId = schoolDoc.id;

          // جلب بيانات الطلاب
          final studentsSnapshot = await _firestore
              .collection('schools')
              .doc(currentSchoolId)
              .collection('students')
              .get();
          int schoolStudents = studentsSnapshot.size;
          totalStudents += schoolStudents;
          studentsPerSchool[currentSchoolId] = schoolStudents;

          for (var studentDoc in studentsSnapshot.docs) {
            final gradeAr = studentDoc.get('gradeAr') as String? ?? 'غير محدد';
            final genderAr = studentDoc.get('genderAr') as String? ?? 'غير محدد';
            final attendanceMap = studentDoc.get('attendanceHistory') as Map<String, dynamic>?;
            final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
            final attendance = attendanceMap?[today] ?? 'غير محدد';
            final feesDue = studentDoc.get('feesDue') as double? ?? 0.0;

            studentsPerGrade[gradeAr] = (studentsPerGrade[gradeAr] ?? 0) + 1;
            totalFeesDue += feesDue;

            if (genderAr.trim().toLowerCase() == 'ذكر') maleStudents++;
            else if (genderAr.trim().toLowerCase() == 'أنثى') femaleStudents++;

            if (attendance.trim().toLowerCase() == 'حاضر') presentStudents++;
            else if (attendance.trim().toLowerCase() == 'غائب') absentStudents++;
          }

          // جلب بيانات الموظفين
          final employeesSnapshot = await _firestore
              .collection('schools')
              .doc(currentSchoolId)
              .collection('employees')
              .get();
          int schoolEmployees = employeesSnapshot.size;
          totalEmployees += schoolEmployees;
          employeesPerSchool[currentSchoolId] = (employeesPerSchool[currentSchoolId] ?? 0) + schoolEmployees;

          for (var employeeDoc in employeesSnapshot.docs) {
            final role = employeeDoc.get('role') as String? ?? 'unknown';
            final departmentAr = employeeDoc.get('departmentAr') as String? ?? 'غير محدد';
            final subDepartmentAr = employeeDoc.get('subDepartmentAr') as String? ?? 'غير محدد';

            employeesPerDepartment[departmentAr] = (employeesPerDepartment[departmentAr] ?? 0) + 1;
            employeesPerSubDepartment[subDepartmentAr] = (employeesPerSubDepartment[subDepartmentAr] ?? 0) + 1;

            if (role.trim().toLowerCase() == 'teacher') totalTeachers++;
            else if (role.trim().toLowerCase() == 'accounting') totalAccountants++;
          }

          final schoolNameMap = schoolDoc.get('schoolName') as Map<String, dynamic>? ?? {'ar': 'مدرسة بدون اسم', 'fr': 'École sans nom'};
          schoolNames[currentSchoolId] = {
            'ar': schoolNameMap['ar'] as String? ?? 'مدرسة بدون اسم',
            'fr': schoolNameMap['fr'] as String? ?? 'École sans nom',
          };
        }
      }

      return Stats(
        totalStudents: totalStudents,
        totalTeachers: totalTeachers,
        totalAccountants: totalAccountants,
        totalEmployees: totalEmployees,
        totalSchools: totalSchools,
        studentsPerGrade: studentsPerGrade,
        studentsPerSchool: studentsPerSchool,
        employeesPerSchool: employeesPerSchool,
        employeesPerDepartment: employeesPerDepartment,
        employeesPerSubDepartment: employeesPerSubDepartment,
        presentStudents: presentStudents,
        absentStudents: absentStudents,
        totalFeesDue: totalFeesDue,
        maleStudents: maleStudents,
        femaleStudents: femaleStudents,
        schoolNames: schoolNames,
      );
    } catch (e) {
      developer.log('Error fetching stats: $e');
      throw Exception('خطأ في جلب الإحصائيات: $e');
    }
  }

  Stream<Stats> streamStats({String? schoolId}) {
    if (schoolId != null) {
      return _firestore.collection('schools').doc(schoolId).snapshots().asyncMap((schoolDoc) async {
        if (!schoolDoc.exists) throw Exception('المدرسة غير موجودة');

        final studentsSnapshot = await _firestore
            .collection('schools')
            .doc(schoolId)
            .collection('students')
            .get();
        final employeesSnapshot = await _firestore
            .collection('schools')
            .doc(schoolId)
            .collection('employees')
            .get();

        return _buildStatsFromSnapshot(
          schoolId: schoolId,
          schoolDoc: schoolDoc,
          studentsSnapshot: studentsSnapshot,
          employeesSnapshot: employeesSnapshot,
        );
      });
    } else {
      return _firestore.collection('schools').snapshots().asyncMap((schoolsSnapshot) async {
        Map<String, int> studentsPerGrade = {};
        Map<String, int> studentsPerSchool = {};
        Map<String, int> employeesPerDepartment = {};
        Map<String, int> employeesPerSubDepartment = {};
        Map<String, int> employeesPerSchool = {};
        int totalStudents = 0;
        int totalEmployees = 0;
        int totalTeachers = 0;
        int totalAccountants = 0;
        int presentStudents = 0;
        int absentStudents = 0;
        double totalFeesDue = 0.0;
        int maleStudents = 0;
        int femaleStudents = 0;
        Map<String, Map<String, String>> schoolNames = {};

        for (var schoolDoc in schoolsSnapshot.docs) {
          final currentSchoolId = schoolDoc.id;

          final studentsSnapshot = await _firestore
              .collection('schools')
              .doc(currentSchoolId)
              .collection('students')
              .get();
          int schoolStudents = studentsSnapshot.size;
          totalStudents += schoolStudents;
          studentsPerSchool[currentSchoolId] = schoolStudents;

          for (var studentDoc in studentsSnapshot.docs) {
            final gradeAr = studentDoc.get('gradeAr') as String? ?? 'غير محدد';
            final genderAr = studentDoc.get('genderAr') as String? ?? 'غير محدد';
            final attendanceMap = studentDoc.get('attendanceHistory') as Map<String, dynamic>?;
            final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
            final attendance = attendanceMap?[today] ?? 'غير محدد';
            final feesDue = studentDoc.get('feesDue') as double? ?? 0.0;

            studentsPerGrade[gradeAr] = (studentsPerGrade[gradeAr] ?? 0) + 1;
            totalFeesDue += feesDue;

            if (genderAr.trim().toLowerCase() == 'ذكر') maleStudents++;
            else if (genderAr.trim().toLowerCase() == 'أنثى') femaleStudents++;

            if (attendance.trim().toLowerCase() == 'حاضر') presentStudents++;
            else if (attendance.trim().toLowerCase() == 'غائب') absentStudents++;
          }

          final employeesSnapshot = await _firestore
              .collection('schools')
              .doc(currentSchoolId)
              .collection('employees')
              .get();
          int schoolEmployees = employeesSnapshot.size;
          totalEmployees += schoolEmployees;
          employeesPerSchool[currentSchoolId] = (employeesPerSchool[currentSchoolId] ?? 0) + schoolEmployees;

          for (var employeeDoc in employeesSnapshot.docs) {
            final role = employeeDoc.get('role') as String? ?? 'unknown';
            final departmentAr = employeeDoc.get('departmentAr') as String? ?? 'غير محدد';
            final subDepartmentAr = employeeDoc.get('subDepartmentAr') as String? ?? 'غير محدد';

            employeesPerDepartment[departmentAr] = (employeesPerDepartment[departmentAr] ?? 0) + 1;
            employeesPerSubDepartment[subDepartmentAr] = (employeesPerSubDepartment[subDepartmentAr] ?? 0) + 1;

            if (role.trim().toLowerCase() == 'teacher') totalTeachers++;
            else if (role.trim().toLowerCase() == 'accounting') totalAccountants++;
          }

          schoolNames[currentSchoolId] = {
            'ar': schoolDoc.get('schoolName')?['ar'] ?? 'مدرسة بدون اسم',
            'fr': schoolDoc.get('schoolName')?['fr'] ?? 'École sans nom',
          };
        }

        return Stats(
          totalStudents: totalStudents,
          totalTeachers: totalTeachers,
          totalAccountants: totalAccountants,
          totalEmployees: totalEmployees,
          totalSchools: schoolsSnapshot.size,
          studentsPerGrade: studentsPerGrade,
          studentsPerSchool: studentsPerSchool,
          employeesPerSchool: employeesPerSchool,
          employeesPerDepartment: employeesPerDepartment,
          employeesPerSubDepartment: employeesPerSubDepartment,
          presentStudents: presentStudents,
          absentStudents: absentStudents,
          totalFeesDue: totalFeesDue,
          maleStudents: maleStudents,
          femaleStudents: femaleStudents,
          schoolNames: schoolNames,
        );
      });
    }
  }

  Stats _buildStatsFromSnapshot({
    required String schoolId,
    required DocumentSnapshot schoolDoc,
    required QuerySnapshot studentsSnapshot,
    required QuerySnapshot employeesSnapshot,
  }) {
    Map<String, int> studentsPerGrade = {};
    Map<String, int> employeesPerDepartment = {};
    Map<String, int> employeesPerSubDepartment = {};
    int totalTeachers = 0;
    int totalAccountants = 0;
    int presentStudents = 0;
    int absentStudents = 0;
    double totalFeesDue = 0.0;
    int maleStudents = 0;
    int femaleStudents = 0;

    // إحصائيات الطلاب
    for (var studentDoc in studentsSnapshot.docs) {
      final gradeAr = studentDoc.get('gradeAr') as String? ?? 'غير محدد';
      final genderAr = studentDoc.get('genderAr') as String? ?? 'غير محدد';
      final attendanceMap = studentDoc.get('attendanceHistory') as Map<String, dynamic>?;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final attendance = attendanceMap?[today] ?? 'غير محدد';
      final feesDue = studentDoc.get('feesDue') as double? ?? 0.0;

      studentsPerGrade[gradeAr] = (studentsPerGrade[gradeAr] ?? 0) + 1;
      totalFeesDue += feesDue;

      if (genderAr.trim().toLowerCase() == 'ذكر') maleStudents++;
      else if (genderAr.trim().toLowerCase() == 'أنثى') femaleStudents++;

      if (attendance.trim().toLowerCase() == 'حاضر') presentStudents++;
      else if (attendance.trim().toLowerCase() == 'غائب') absentStudents++;
    }

    // إحصائيات الموظفين
    for (var employeeDoc in employeesSnapshot.docs) {
      final role = employeeDoc.get('role') as String? ?? 'unknown';
      final departmentAr = employeeDoc.get('departmentAr') as String? ?? 'غير محدد';
      final subDepartmentAr = employeeDoc.get('subDepartmentAr') as String? ?? 'غير محدد';

      employeesPerDepartment[departmentAr] = (employeesPerDepartment[departmentAr] ?? 0) + 1;
      employeesPerSubDepartment[subDepartmentAr] = (employeesPerSubDepartment[subDepartmentAr] ?? 0) + 1;

      if (role.trim().toLowerCase() == 'teacher') totalTeachers++;
      else if (role.trim().toLowerCase() == 'accounting') totalAccountants++;
    }

    return Stats(
      totalStudents: studentsSnapshot.size,
      totalTeachers: totalTeachers,
      totalAccountants: totalAccountants,
      totalEmployees: employeesSnapshot.size,
      totalSchools: 1,
      studentsPerGrade: studentsPerGrade,
      studentsPerSchool: {schoolId: studentsSnapshot.size},
      employeesPerSchool: {schoolId: employeesSnapshot.size},
      employeesPerDepartment: employeesPerDepartment,
      employeesPerSubDepartment: employeesPerSubDepartment,
      presentStudents: presentStudents,
      absentStudents: absentStudents,
      totalFeesDue: totalFeesDue,
      maleStudents: maleStudents,
      femaleStudents: femaleStudents,
      schoolNames: {
        schoolId: {
          'ar': schoolDoc.get('schoolName')?['ar'] ?? 'مدرسة بدون اسم',
          'fr': schoolDoc.get('schoolName')?['fr'] ?? 'École sans nom',
        }
      },
    );
  }
}