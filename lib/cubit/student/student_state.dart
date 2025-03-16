import 'package:equatable/equatable.dart';
import '../../models/student_model.dart';

abstract class StudentState extends Equatable {
  const StudentState();

  @override
  List<Object> get props => [];
}

class StudentInitial extends StudentState {}

class StudentLoading extends StudentState {}

class StudentAdded extends StudentState {}

class StudentUpdated extends StudentState {}

class StudentDeleted extends StudentState {}

class StudentFeesUpdated extends StudentState {} // يمكن استخدامها للإشعارات ولكن ليست ضرورية مع التدفق

class StudentAttendanceUpdated extends StudentState {}

class StudentsLoaded extends StudentState {
  final List<Student> students;

  const StudentsLoaded(this.students);

  @override
  List<Object> get props => [students];
}

class StudentLoaded extends StudentState {
  final Student student;

  const StudentLoaded(this.student);

  @override
  List<Object> get props => [student];
}

class StudentError extends StudentState {
  final String message;

  const StudentError(this.message);

  @override
  List<Object> get props => [message];
}