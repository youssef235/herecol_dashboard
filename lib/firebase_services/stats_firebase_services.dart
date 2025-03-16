import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/stats_model.dart';
import 'dart:developer' as developer;

class StatsFirebaseServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // دالة لجلب البيانات مرة واحدة
  Future<Stats> getStats({String? schoolId}) async {
    try {
      Map<String, int> studentsPerGrade = {};
      Map<String, int> studentsPerSchool = {};
      int totalStudents = 0;
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
        // Fetch data for a specific school
        final schoolDoc = await _firestore.collection('schools').doc(schoolId).get();
        if (!schoolDoc.exists) throw Exception('المدرسة غير موجودة');

        final studentsSnapshot = await _firestore.collection('schools').doc(schoolId).collection('students').get();
        final teachersSnapshot = await _firestore.collection('teachers').where('schoolId', isEqualTo: schoolId).get();
        final accountantsSnapshot = await _firestore.collection('accountants').where('schoolId', isEqualTo: schoolId).get();
        final feesSnapshot = await _firestore.collection('schools').doc(schoolId).collection('fees').get();

        totalStudents = studentsSnapshot.size;
        totalTeachers = teachersSnapshot.size;
        totalAccountants = accountantsSnapshot.size;
        totalSchools = 1;

        studentsPerSchool[schoolId] = totalStudents;
        final schoolNameMap = schoolDoc.get('schoolName') as Map<String, dynamic>? ?? {'ar': 'مدرسة بدون اسم', 'fr': 'École sans nom'};
        schoolNames[schoolId] = {
          'ar': schoolNameMap['ar'] as String? ?? 'مدرسة بدون اسم',
          'fr': schoolNameMap['fr'] as String? ?? 'École sans nom',
        };

        for (var studentDoc in studentsSnapshot.docs) {
          final gradeAr = studentDoc.get('gradeAr') as String? ?? 'غير محدد';
          final genderAr = studentDoc.get('genderAr') as String? ?? 'غير محدد';
          final attendanceMap = studentDoc.get('attendanceHistory') as Map<String, dynamic>?;
          final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final attendance = attendanceMap != null && attendanceMap.containsKey(today)
              ? attendanceMap[today] as String? ?? 'غير محدد'
              : 'غير محدد';

          studentsPerGrade[gradeAr] = (studentsPerGrade[gradeAr] ?? 0) + 1;
          developer.log('Student Data: gradeAr=$gradeAr, genderAr=$genderAr, attendance=$attendance');

          if (genderAr.trim().toLowerCase() == 'ذكر') maleStudents++;
          else if (genderAr.trim().toLowerCase() == 'أنثى') femaleStudents++;

          if (attendance.trim().toLowerCase() == 'حاضر') presentStudents++;
          else if (attendance.trim().toLowerCase() == 'غائب') absentStudents++;
        }

        totalFeesDue = feesSnapshot.docs.fold(0, (sum, doc) => sum + (doc['amountDue'] as double? ?? 0));
      } else {
        // Fetch data for all schools (admin view)
        final schoolsSnapshot = await _firestore.collection('schools').get();
        final teachersSnapshot = await _firestore.collection('teachers').get();
        final accountantsSnapshot = await _firestore.collection('accountants').get();

        totalSchools = schoolsSnapshot.size;
        totalTeachers = teachersSnapshot.size;
        totalAccountants = accountantsSnapshot.size;

        for (var schoolDoc in schoolsSnapshot.docs) {
          final currentSchoolId = schoolDoc.id;
          final studentsSnapshot = await _firestore.collection('schools').doc(currentSchoolId).collection('students').get();
          final feesSnapshot = await _firestore.collection('schools').doc(currentSchoolId).collection('fees').get();

          int schoolStudents = studentsSnapshot.size;
          totalStudents += schoolStudents;
          studentsPerSchool[currentSchoolId] = schoolStudents;
          final schoolNameMap = schoolDoc.get('schoolName') as Map<String, dynamic>? ?? {'ar': 'مدرسة بدون اسم', 'fr': 'École sans nom'};
          schoolNames[currentSchoolId] = {
            'ar': schoolNameMap['ar'] as String? ?? 'مدرسة بدون اسم',
            'fr': schoolNameMap['fr'] as String? ?? 'École sans nom',
          };

          for (var studentDoc in studentsSnapshot.docs) {
            final gradeAr = studentDoc.get('gradeAr') as String? ?? 'غير محدد';
            final genderAr = studentDoc.get('genderAr') as String? ?? 'غير محدد';
            final attendanceMap = studentDoc.get('attendanceHistory') as Map<String, dynamic>?;
            final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
            final attendance = attendanceMap != null && attendanceMap.containsKey(today)
                ? attendanceMap[today] as String? ?? 'غير محدد'
                : 'غير محدد';

            studentsPerGrade[gradeAr] = (studentsPerGrade[gradeAr] ?? 0) + 1;
            developer.log('Student Data: gradeAr=$gradeAr, genderAr=$genderAr, attendance=$attendance');

            if (genderAr.trim().toLowerCase() == 'ذكر') maleStudents++;
            else if (genderAr.trim().toLowerCase() == 'أنثى') femaleStudents++;

            if (attendance.trim().toLowerCase() == 'حاضر') presentStudents++;
            else if (attendance.trim().toLowerCase() == 'غائب') absentStudents++;
          }

          totalFeesDue += feesSnapshot.docs.fold(0, (sum, doc) => sum + (doc['amountDue'] as double? ?? 0));
        }
      }

      return Stats(
        totalStudents: totalStudents,
        totalTeachers: totalTeachers,
        totalAccountants: totalAccountants,
        totalSchools: totalSchools,
        studentsPerSchool: studentsPerSchool,
        studentsPerGrade: studentsPerGrade,
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

  // دالة لتدفق البيانات في الوقت الفعلي
  Stream<Stats> streamStats({String? schoolId}) {
    if (schoolId != null) {
      // تدفق بيانات مدرسة محددة
      return _firestore.collection('schools').doc(schoolId).snapshots().asyncMap((schoolDoc) async {
        if (!schoolDoc.exists) throw Exception('المدرسة غير موجودة');

        final studentsSnapshot = await _firestore.collection('schools').doc(schoolId).collection('students').get();
        final teachersSnapshot = await _firestore.collection('teachers').where('schoolId', isEqualTo: schoolId).get();
        final accountantsSnapshot = await _firestore.collection('accountants').where('schoolId', isEqualTo: schoolId).get();
        final feesSnapshot = await _firestore.collection('schools').doc(schoolId).collection('fees').get();

        return _buildStatsFromSnapshots(
          schoolId: schoolId,
          studentsSnapshot: studentsSnapshot,
          teachersSnapshot: teachersSnapshot,
          accountantsSnapshot: accountantsSnapshot,
          feesSnapshot: feesSnapshot,
          schoolDoc: schoolDoc,
        );
      });
    } else {
      // تدفق بيانات جميع المدارس (للأدمن)
      return _firestore.collection('schools').snapshots().asyncMap((schoolsSnapshot) async {
        final teachersSnapshot = await _firestore.collection('teachers').get();
        final accountantsSnapshot = await _firestore.collection('accountants').get();

        Map<String, int> studentsPerSchool = {};
        Map<String, int> studentsPerGrade = {};
        Map<String, Map<String, String>> schoolNames = {};
        int totalStudents = 0;
        int presentStudents = 0;
        int absentStudents = 0;
        int maleStudents = 0;
        int femaleStudents = 0;
        double totalFeesDue = 0.0;

        for (var schoolDoc in schoolsSnapshot.docs) {
          final currentSchoolId = schoolDoc.id;
          final studentsSnapshot = await _firestore.collection('schools').doc(currentSchoolId).collection('students').get();
          final feesSnapshot = await _firestore.collection('schools').doc(currentSchoolId).collection('fees').get();

          int schoolStudents = studentsSnapshot.size;
          totalStudents += schoolStudents;
          studentsPerSchool[currentSchoolId] = schoolStudents;
          schoolNames[currentSchoolId] = {
            'ar': schoolDoc.get('schoolName')?['ar'] ?? 'مدرسة بدون اسم',
            'fr': schoolDoc.get('schoolName')?['fr'] ?? 'École sans nom',
          };

          for (var studentDoc in studentsSnapshot.docs) {
            final gradeAr = studentDoc.get('gradeAr') ?? 'غير محدد';
            final genderAr = studentDoc.get('genderAr') ?? 'غير محدد';
            final attendanceMap = studentDoc.get('attendanceHistory') as Map<String, dynamic>?;
            final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
            final attendance = attendanceMap?[today] ?? 'غير محدد';

            studentsPerGrade[gradeAr] = (studentsPerGrade[gradeAr] ?? 0) + 1;
            if (genderAr.trim().toLowerCase() == 'ذكر') maleStudents++;
            else if (genderAr.trim().toLowerCase() == 'أنثى') femaleStudents++;
            if (attendance.trim().toLowerCase() == 'حاضر') presentStudents++;
            else if (attendance.trim().toLowerCase() == 'غائب') absentStudents++;
          }

          totalFeesDue += feesSnapshot.docs.fold(0, (sum, doc) => sum + (doc['amountDue'] as double? ?? 0));
        }

        return Stats(
          totalStudents: totalStudents,
          totalTeachers: teachersSnapshot.size,
          totalAccountants: accountantsSnapshot.size,
          totalSchools: schoolsSnapshot.size,
          studentsPerSchool: studentsPerSchool,
          studentsPerGrade: studentsPerGrade,
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

  // دالة مساعدة لمعالجة البيانات
  Stats _buildStatsFromSnapshots({
    required String schoolId,
    required QuerySnapshot studentsSnapshot,
    required QuerySnapshot teachersSnapshot,
    required QuerySnapshot accountantsSnapshot,
    required QuerySnapshot feesSnapshot,
    required DocumentSnapshot schoolDoc,
  }) {
    Map<String, int> studentsPerGrade = {};
    Map<String, int> studentsPerSchool = {};
    int presentStudents = 0;
    int absentStudents = 0;
    int maleStudents = 0;
    int femaleStudents = 0;

    for (var studentDoc in studentsSnapshot.docs) {
      final gradeAr = studentDoc.get('gradeAr') ?? 'غير محدد';
      final genderAr = studentDoc.get('genderAr') ?? 'غير محدد';
      final attendanceMap = studentDoc.get('attendanceHistory') as Map<String, dynamic>?;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final attendance = attendanceMap?[today] ?? 'غير محدد';

      studentsPerGrade[gradeAr] = (studentsPerGrade[gradeAr] ?? 0) + 1;
      if (genderAr.trim().toLowerCase() == 'ذكر') maleStudents++;
      else if (genderAr.trim().toLowerCase() == 'أنثى') femaleStudents++;
      if (attendance.trim().toLowerCase() == 'حاضر') presentStudents++;
      else if (attendance.trim().toLowerCase() == 'غائب') absentStudents++;
    }

    studentsPerSchool[schoolId] = studentsSnapshot.size;

    return Stats(
      totalStudents: studentsSnapshot.size,
      totalTeachers: teachersSnapshot.size,
      totalAccountants: accountantsSnapshot.size,
      totalSchools: 1,
      studentsPerSchool: studentsPerSchool,
      studentsPerGrade: studentsPerGrade,
      presentStudents: presentStudents,
      absentStudents: absentStudents,
      totalFeesDue: feesSnapshot.docs.fold(0, (sum, doc) => sum + (doc['amountDue'] as double? ?? 0)),
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