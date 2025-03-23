import 'package:equatable/equatable.dart';
import '../../models/parent_model.dart';

abstract class ParentState extends Equatable {
  @override
  List<Object> get props => [];
}

class ParentInitial extends ParentState {}

class ParentLoading extends ParentState {}

class ParentAdded extends ParentState {}

class ParentUpdated extends ParentState {}

class ParentDeleted extends ParentState {}

class ParentsLoaded extends ParentState {
  final List<Parent> parents;

  ParentsLoaded(this.parents);

  @override
  List<Object> get props => [parents];
}

class ParentError extends ParentState {
  final String message;

  ParentError(this.message);

  @override
  List<Object> get props => [message];
}