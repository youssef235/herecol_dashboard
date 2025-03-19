import '../../models/SalaryCategory.dart';
import '../../models/SalaryPayment.dart';

abstract class SalaryState {}

class SalaryInitial extends SalaryState {}

class SalaryLoading extends SalaryState {}

class SalaryCategoriesLoaded extends SalaryState {
  final List<SalaryCategory> categories;
  SalaryCategoriesLoaded(this.categories);
}

class SalaryCategoryLoaded extends SalaryState {
  final SalaryCategory category;
  SalaryCategoryLoaded(this.category);
}

class SalaryPaymentsLoaded extends SalaryState {
  final List<SalaryPayment> payments;
  SalaryPaymentsLoaded(this.payments);
}

class SalaryPaid extends SalaryState {}

class SalaryCategoryAdded extends SalaryState {} // حالة جديدة

class SalaryError extends SalaryState {
  final String message;
  SalaryError(this.message);
}