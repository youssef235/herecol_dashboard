import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase_services/parent_firebase_services.dart';
import '../../models/parent_model.dart';
import 'parent_state.dart';

class ParentCubit extends Cubit<ParentState> {
  final ParentFirebaseServices _firebaseServices;

  ParentCubit(this._firebaseServices) : super(ParentInitial());

  void addParent({
    required String schoolId,
    required String nameAr,
    required String nameFr,
    required String phone,
    required String emergencyPhone,
    String? email,
    required String addressAr,
    String? addressFr,
    required List<String> studentIds,
  }) async {
    emit(ParentLoading());
    try {
      final parentId = FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('parents').doc().id;
      final parent = Parent(
        id: parentId,
        schoolId: schoolId,
        nameAr: nameAr,
        nameFr: nameFr,
        phone: phone,
        emergencyPhone: emergencyPhone,
        email: email,
        addressAr: addressAr,
        addressFr: addressFr,
        studentIds: studentIds,
      );
      await _firebaseServices.addParent(schoolId, parent);
      for (var studentId in studentIds) {
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('students')
            .doc(studentId)
            .update({'parentId': parentId});
      }
      emit(ParentAdded());
    } catch (e) {
      emit(ParentError('فشل في إضافة ولي الأمر: $e'));
    }
  }

  void fetchParents(String schoolId) async {
    emit(ParentLoading());
    try {
      print('Fetching parents for schoolId: $schoolId');
      final parents = await _firebaseServices.getParents(schoolId);
      print('Fetched ${parents.length} parents');
      emit(ParentsLoaded(parents));
    } catch (e) {
      print('Error fetching parents: $e');
      emit(ParentError('خطأ في جلب أولياء الأمور: $e'));
    }
  }

  void fetchAllParents() async {
    emit(ParentLoading());
    try {
      print('Fetching all parents');
      final parents = await _firebaseServices.getAllParents();
      print('Fetched ${parents.length} parents across all schools');
      emit(ParentsLoaded(parents));
    } catch (e) {
      print('Error fetching all parents: $e');
      emit(ParentError('خطأ في جلب جميع أولياء الأمور: $e'));
    }
  }

  void updateParent({
    required String schoolId,
    required String parentId,
    required List<String> studentIds,
  }) async {
    emit(ParentLoading());
    try {
      await _firebaseServices.updateParent(schoolId: schoolId, parentId: parentId, studentIds: studentIds);
      emit(ParentUpdated());
    } catch (e) {
      emit(ParentError('خطأ في تحديث ولي الأمر: $e'));
    }
  }

  void updateParentFull({
    required String schoolId,
    required String parentId,
    required Parent updatedParent,
  }) async {
    emit(ParentLoading());
    try {
      await _firebaseServices.updateParentFull(schoolId: schoolId, parentId: parentId, updatedParent: updatedParent);
      emit(ParentUpdated());
    } catch (e) {
      emit(ParentError('خطأ في تحديث بيانات ولي الأمر: $e'));
    }
  }


  void deleteParent(String schoolId, String parentId) async {
    emit(ParentLoading());
    try {
      await _firebaseServices.deleteParent(schoolId, parentId);
      emit(ParentDeleted());
      fetchParents(schoolId); // إعادة تحميل القائمة بعد الحذف
    } catch (e) {
      emit(ParentError('فشل في حذف ولي الأمر: $e'));
    }
  }
}