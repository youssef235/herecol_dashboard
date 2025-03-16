import 'package:bloc/bloc.dart';
import 'package:school_management_dashboard/models/stats_model.dart';
import '../../firebase_services/stats_firebase_services.dart';
import 'stat_state.dart';
import 'dart:async';

class StatsCubit extends Cubit<StatsState> {
  final StatsFirebaseServices _firebaseServices;
  StreamSubscription? _statsSubscription;

  StatsCubit(this._firebaseServices) : super(StatsInitial());

  void fetchStats({String? schoolId}) async {
    if (isClosed) return;
    emit(StatsLoading());
    try {
      final stats = await _firebaseServices.getStats(schoolId: schoolId);
      if (!isClosed) emit(StatsLoaded(stats));
    } catch (e) {
      if (!isClosed) emit(StatsError("خطأ في تحميل الإحصائيات: $e"));
    }
  }

  void streamStats({String? schoolId}) {
    if (isClosed) return;
    emit(StatsLoading());

    _statsSubscription?.cancel(); // إلغاء الاشتراك السابق إن وجد
    _statsSubscription = _firebaseServices.streamStats(schoolId: schoolId).listen(
          (stats) {
        if (!isClosed) emit(StatsLoaded(stats));
      },
      onError: (e) {
        if (!isClosed) emit(StatsError("خطأ في تحميل الإحصائيات: $e"));
      },
    );
  }

  @override
  Future<void> close() {
    _statsSubscription?.cancel();
    return super.close();
  }
}