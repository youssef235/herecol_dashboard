import 'package:equatable/equatable.dart';
import '../../models/school_info_model.dart';

abstract class SchoolState extends Equatable {
  @override
  List<Object> get props => [];
}

class SchoolInitial extends SchoolState {}

class SchoolLoading extends SchoolState {}

class SchoolsLoading extends SchoolState {} // حالة جديدة لتحميل قائمة المدارس

class SchoolLoaded extends SchoolState {
  final Schoolinfo schoolInfo;
  SchoolLoaded(this.schoolInfo);

  @override
  List<Object> get props => [schoolInfo];
}

class SchoolError extends SchoolState {
  final String message;
  SchoolError(this.message);

  @override
  List<Object> get props => [message];
}

class SchoolAdded extends SchoolState {}

class SchoolsLoaded extends SchoolState {
  final List<Schoolinfo> schools;
  SchoolsLoaded(this.schools);

  @override
  List<Object> get props => [schools];
}