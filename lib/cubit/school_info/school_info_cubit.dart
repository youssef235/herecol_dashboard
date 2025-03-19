import 'package:bloc/bloc.dart';
import 'package:school_management_dashboard/cubit/school_info/school_info_state.dart';
import 'package:school_management_dashboard/firebase_services/school_info_firebase_services.dart';
import '../../models/school_info_model.dart';
import 'dart:developer' as developer;

class SchoolCubit extends Cubit<SchoolState> {
  final SchoolFirebaseServices _firebaseServices;

  SchoolCubit(this._firebaseServices) : super(SchoolInitial());

  void addSchool(Schoolinfo schoolInfo, String uid, String role) async {
    emit(SchoolLoading());
    try {
      if (role == 'admin') {
        await _firebaseServices.addSchoolInfo(schoolInfo);
      } else {
        schoolInfo.ownerId = uid;
        schoolInfo.schoolId = uid;
        await _firebaseServices.addSchoolInfo(schoolInfo);
      }
      emit(SchoolAdded());
      fetchSchools(uid, role); // إعادة جلب البيانات بعد الإضافة
    } catch (e) {
      developer.log('Error adding school: $e');
      emit(SchoolError(e.toString()));
    }
  }

  void fetchSchoolInfo(String schoolId, String uid, String role) async {
    emit(SchoolLoading());
    try {
      if (role == 'admin') {
        final schoolInfo = await _firebaseServices.getSchoolInfo(schoolId);
        if (schoolInfo != null) {
          emit(SchoolLoaded(schoolInfo));
        } else {
          emit(SchoolError("المدرسة غير موجودة"));
        }
      } else if (schoolId == uid) {
        final schoolInfo = await _firebaseServices.getSchoolInfo(schoolId);
        if (schoolInfo != null) {
          emit(SchoolLoaded(schoolInfo));
        } else {
          emit(SchoolError("المدرسة غير موجودة"));
        }
      } else {
        emit(SchoolError("غير مصرح لك برؤية هذه المدرسة"));
      }
    } catch (e) {
      developer.log('Error fetching school info: $e');
      emit(SchoolError("خطأ في تحميل بيانات المدرسة: $e"));
    }
  }

  void fetchSchools(String uid, String role) async {
    emit(SchoolsLoading());
    try {
      if (role == 'admin') {
        final schools = await _firebaseServices.getSchools();
        developer.log('Admin fetched schools: ${schools.length}');
        if (schools.isNotEmpty) {
          emit(SchoolsLoaded(schools));
        } else {
          emit(SchoolError("لم يتم العثور على مدارس"));
        }
      } else {
        final school = await _firebaseServices.getSchoolInfo(uid);
        developer.log('School fetch result: ${school != null ? school.schoolName : 'null'}');
        if (school != null) {
          emit(SchoolsLoaded([school]));
        } else {
          emit(SchoolError("لم يتم العثور على مدرستك"));
        }
      }
    } catch (e) {
      developer.log('Error fetching schools: $e');
      emit(SchoolError("خطأ في تحميل المدارس: $e"));
    }
  }
}