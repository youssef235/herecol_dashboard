import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:school_management_dashboard/cubit/salary/salary_state.dart';
import '../../firebase_services/SalaryFirebaseServices.dart';
import '../../models/SalaryCategory.dart';
import '../../models/SalaryPayment.dart';

class SalaryCubit extends Cubit<SalaryState> {
  final SalaryFirebaseServices _firebaseServices;
  StreamSubscription? _subscription;

  SalaryCubit(this._firebaseServices) : super(SalaryInitial());

  void addSalaryCategory(SalaryCategory category, String schoolId) async {
    emit(SalaryLoading());
    try {
      await _firebaseServices.addSalaryCategory(category, schoolId);
      emit(SalaryCategoryAdded());
      fetchSalaryCategories(schoolId);
    } catch (e) {
      emit(SalaryError("خطأ في إضافة فئة الراتب: $e"));
    }
  }

  void updateSalaryCategory(SalaryCategory category, String schoolId) async {
    emit(SalaryLoading());
    try {
      await _firebaseServices.updateSalaryCategory(category, schoolId);
      emit(SalaryCategoryUpdated());
      fetchSalaryCategories(schoolId);
    } catch (e) {
      emit(SalaryError("خطأ في تعديل فئة الراتب: $e"));
    }
  }

  void deleteSalaryCategory(String categoryId, String schoolId) async {
    emit(SalaryLoading());
    try {
      await _firebaseServices.deleteSalaryCategory(categoryId, schoolId);
      emit(SalaryCategoryDeleted());
      fetchSalaryCategories(schoolId);
    } catch (e) {
      emit(SalaryError("خطأ في حذف فئة الراتب: $e"));
    }
  }

  void fetchSalaryCategories(String? schoolId) {
    if (schoolId == null) {
      emit(SalaryInitial());
      _subscription?.cancel();
      return;
    }

    emit(SalaryLoading());
    _subscription?.cancel();
    _subscription = _firebaseServices.getSalaryCategories(schoolId).listen(
          (categories) {
        emit(SalaryCategoriesLoaded(categories));
      },
      onError: (e) {
        emit(SalaryError("خطأ في تحميل فئات الرواتب: $e"));
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  void fetchSalaryCategory(String schoolId, String categoryId) async {
    emit(SalaryLoading());
    try {
      final category = await _firebaseServices.getSalaryCategory(schoolId, categoryId);
      emit(SalaryCategoryLoaded(category));
    } catch (e) {
      emit(SalaryError("خطأ في تحميل فئة الراتب: $e"));
    }
  }

  Future<SalaryCategory> fetchSalaryCategorySync(String schoolId, String categoryId) async {
    return await _firebaseServices.getSalaryCategory(schoolId, categoryId);
  }

  void paySalary(SalaryPayment payment, String schoolId) async {
    emit(SalaryLoading());
    try {
      await _firebaseServices.paySalary(payment, schoolId);
      emit(SalaryPaid());
      fetchSalaryPayments(schoolId, payment.month);
    } catch (e) {
      emit(SalaryError("خطأ في دفع الراتب: $e"));
    }
  }

  void fetchSalaryPayments(String schoolId, String month) async {
    emit(SalaryLoading());
    try {
      final payments = await _firebaseServices.getSalaryPayments(schoolId, month);
      emit(SalaryPaymentsLoaded(payments));
    } catch (e) {
      emit(SalaryError("خطأ في تحميل دفعات الرواتب: $e"));
    }
  }

  void updatePaymentStatus(String schoolId, String paymentId, PaymentStatus newStatus) async {
    emit(SalaryLoading());
    try {
      await _firebaseServices.updatePaymentStatus(schoolId, paymentId, newStatus);
      final month = '${DateTime.now().month}-${DateTime.now().year}'; // يمكن تعديل هذا ليتناسب مع الشهر المحدد
      fetchSalaryPayments(schoolId, month);
    } catch (e) {
      emit(SalaryError("خطأ في تحديث حالة الدفع: $e"));
    }
  }
}