import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_dashboard/firebase_services/employee_firebase_services.dart';
import 'package:school_management_dashboard/models/employee_model.dart';
import 'EmployeeState.dart';
import 'dart:developer' as developer;

class EmployeeCubit extends Cubit<EmployeeState> {
  final EmployeeFirebaseServices _firebaseServices;

  EmployeeCubit(this._firebaseServices) : super(EmployeeInitial());

  void addEmployee(Employee employee, String schoolId) async {
    emit(EmployeeLoading());
    try {
      await _firebaseServices.addEmployee(employee, schoolId);
      emit(EmployeeAdded());
    } catch (e) {
      emit(EmployeeError("خطأ في إضافة الموظف: $e"));
    }
  }

  void fetchEmployees({
    String? schoolId,
    bool isSuperAdmin = false,
    String? department,
    String? subDepartment,
  }) async {
    emit(EmployeeLoading());
    try {
      if (isSuperAdmin && schoolId == null) {
        final schoolsSnapshot = await _firebaseServices.getAllSchools();
        List<Employee> allEmployees = [];
        for (var schoolDoc in schoolsSnapshot.docs) {
          final employees = await _firebaseServices.getEmployees(schoolDoc.id);
          allEmployees.addAll(employees);
        }
        developer.log('Fetched ${allEmployees.length} employees for super admin');
        emit(EmployeeLoaded(allEmployees));
      } else if (schoolId != null) {
        final employees = await _firebaseServices.getEmployees(schoolId);
        developer.log('Fetched ${employees.length} employees for schoolId: $schoolId');
        emit(EmployeeLoaded(employees));
      } else {
        emit(EmployeeError("لم يتم تحديد مدرسة"));
      }
    } catch (e) {
      emit(EmployeeError("خطأ في تحميل الموظفين: $e"));
    }
  }

  void updateEmployee(Employee employee, String schoolId) async {
    emit(EmployeeLoading());
    try {
      await _firebaseServices.updateEmployee(employee, schoolId);
      emit(EmployeeUpdated());
    } catch (e) {
      emit(EmployeeError("خطأ في تحديث الموظف: $e"));
    }
  }

  void deleteEmployee(String employeeId, String schoolId) async {
    emit(EmployeeLoading());
    try {
      await _firebaseServices.deleteEmployee(employeeId, schoolId);
      emit(EmployeeDeleted());
    } catch (e) {
      emit(EmployeeError("خطأ في حذف الموظف: $e"));
    }
  }
}