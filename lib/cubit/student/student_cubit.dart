import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_dashboard/firebase_services/student_firebase_services.dart';
import '../../models/student_model.dart';
import 'student_state.dart';
import 'dart:async';

class StudentCubit extends Cubit<StudentState> {
  final StudentFirebaseServices _firebaseServices;
  StreamSubscription? _studentsSubscription;

  StudentCubit(this._firebaseServices) : super(StudentInitial());

  void addStudent({
    required String firstNameAr,
    required String firstNameFr,
    required String lastNameAr,
    required String lastNameFr,
    required String gradeAr,
    required String gradeFr,
    required String sectionAr,
    required String sectionFr,
    String? categoryAr,
    String? categoryFr,
    required String birthDate,
    required String phone,
    String? email,
    required String addressAr,
    String? addressFr,
    required String schoolId,
    required String birthPlaceAr,
    String? birthPlaceFr,
    String? genderAr,
    String? genderFr,
    String? role,
    String? uid,
    required double feesDue,
    required double feesPaid,
    required String academicYear,
    required String ministryFileNumber,
    String? profileImage,
  }) async {
    emit(StudentLoading());
    try {
      final studentId = await _firebaseServices.generateStudentId(schoolId, academicYear);
      final student = Student(
        id: studentId,
        firstNameAr: firstNameAr,
        firstNameFr: firstNameFr,
        lastNameAr: lastNameAr,
        lastNameFr: lastNameFr,
        gradeAr: gradeAr,
        gradeFr: gradeFr,
        sectionAr: sectionAr,
        sectionFr: sectionFr,
        categoryAr: categoryAr,
        categoryFr: categoryFr,
        birthDate: birthDate,
        phone: phone,
        email: email,
        addressAr: addressAr,
        addressFr: addressFr,
        academicYear: academicYear,
        schoolId: role == 'admin' ? schoolId : uid!,
        admissionDate: DateTime.now().toString(),
        birthPlaceAr: birthPlaceAr,
        birthPlaceFr: birthPlaceFr,
        genderAr: genderAr,
        genderFr: genderFr,
        feesDue: feesDue,
        feesPaid: feesPaid,
        ministryFileNumber: ministryFileNumber,
        profileImage: profileImage,
      );
      await _firebaseServices.addStudent(student);
      emit(StudentAdded());
    } catch (e) {
      emit(StudentError('فشل في إضافة الطالب: $e'));
    }
  }

  void fetchStudents({required String schoolId, String? grade, String? section, String language = 'fr'}) async {
    emit(StudentLoading());
    try {
      final students = await _firebaseServices.getSchoolStudents(schoolId);
      emit(StudentsLoaded(students.where((student) {
        final matchesGrade = grade == null || (language == 'ar' ? student.gradeAr : student.gradeFr) == grade;
        final matchesSection = section == null || (language == 'ar' ? student.sectionAr : student.sectionFr) == section;
        return matchesGrade && matchesSection;
      }).toList()));
    } catch (e) {
      emit(StudentError('خطأ في جلب الطلاب: $e'));
    }
  }

  void streamStudents({required String schoolId, String? grade, String? section, String language = 'fr'}) {
    if (isClosed) return;
    emit(StudentLoading());

    _studentsSubscription?.cancel();
    _studentsSubscription = _firebaseServices.streamSchoolStudents(schoolId).listen(
          (students) {
        if (!isClosed) {
          emit(StudentsLoaded(students.where((student) {
            final matchesGrade = grade == null || (language == 'ar' ? student.gradeAr : student.gradeFr) == grade;
            final matchesSection = section == null || (language == 'ar' ? student.sectionAr : student.sectionFr) == section;
            return matchesGrade && matchesSection;
          }).toList()));
        }
      },
      onError: (e) {
        if (!isClosed) emit(StudentError('خطأ في جلب الطلاب: $e'));
      },
    );
  }

  void fetchAllStudents() async {
    emit(StudentLoading());
    try {
      final schoolsSnapshot = await FirebaseFirestore.instance.collection('schools').get();
      List<Student> allStudents = [];
      for (var schoolDoc in schoolsSnapshot.docs) {
        final students = await _firebaseServices.getSchoolStudents(schoolDoc.id);
        allStudents.addAll(students);
      }
      emit(StudentsLoaded(allStudents));
    } catch (e) {
      emit(StudentError('خطأ في جلب جميع الطلاب: $e'));
    }
  }

  void updateStudentAttendanceWithDate({
    required String schoolId,
    required String studentId,
    required String date,
    required String attendance,
  }) async {
    try {
      await _firebaseServices.updateStudentAttendance(
        schoolId: schoolId,
        studentId: studentId,
        date: date,
        attendance: attendance,
      );
    } catch (e) {
      emit(StudentError('خطأ في تحديث الحضور: $e'));
    }
  }

  void updateStudentFees({
    required String schoolId,
    required String studentId,
    required double feesDue,
    required double feesPaid,
  }) async {
    try {
      await _firebaseServices.updateStudentFees(
        schoolId: schoolId,
        studentId: studentId,
        feesDue: feesDue,
        feesPaid: feesPaid,
      );
    } catch (e) {
      emit(StudentError('خطأ في تحديث المصاريف: $e'));
    }
  }

  void updateStudent({
    required String schoolId,
    required String studentId,
    required Student student,
  }) async {
    emit(StudentLoading());
    try {
      await _firebaseServices.updateStudent(
        schoolId: schoolId,
        studentId: studentId,
        student: student,
      );
      emit(StudentUpdated());
    } catch (e) {
      emit(StudentError('خطأ في تحديث الطالب: $e'));
    }
  }

  void deleteStudent({
    required String schoolId,
    required String studentId,
  }) async {
    emit(StudentLoading());
    try {
      await _firebaseServices.deleteStudent(
        schoolId: schoolId,
        studentId: studentId,
      );
      emit(StudentDeleted());
    } catch (e) {
      emit(StudentError('خطأ في حذف الطالب: $e'));
    }
  }

  void getStudentById({
    required String schoolId,
    required String studentId,
  }) async {
    emit(StudentLoading());
    try {
      final student = await _firebaseServices.getStudentById(
        schoolId: schoolId,
        studentId: studentId,
      );
      emit(StudentLoaded(student));
    } catch (e) {
      emit(StudentError('خطأ في جلب الطالب: $e'));
    }
  }

  void fetchStudentDetails({
    required String schoolId,
    required String studentId,
  }) async {
    emit(StudentLoading());
    try {
      final student = await _firebaseServices.getStudentById(
        schoolId: schoolId,
        studentId: studentId,
      );
      emit(StudentLoaded(student));
    } catch (e) {
      emit(StudentError('خطأ في جلب تفاصيل الطالب: $e'));
    }
  }

  @override
  Future<void> close() {
    _studentsSubscription?.cancel();
    return super.close();
  }
}