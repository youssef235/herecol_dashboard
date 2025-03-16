import 'package:equatable/equatable.dart';
import '../../models/stats_model.dart';

abstract class StatsState extends Equatable {
  @override
  List<Object> get props => [];
}

class StatsInitial extends StatsState {}

class StatsLoading extends StatsState {}

class StatsLoaded extends StatsState {
  final Stats stats;

  StatsLoaded(this.stats);

  @override
  List<Object> get props => [stats];
}

class StatsError extends StatsState {
  final String message;

  StatsError(this.message);

  @override
  List<Object> get props => [message];
}