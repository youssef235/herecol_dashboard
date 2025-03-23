import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/parent_model.dart';

class ParentFirebaseServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addParent(String schoolId, Parent parent) async {
    await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('parents')
        .doc(parent.id)
        .set(parent.toFirestore());
  }

  Future<List<Parent>> getParents(String schoolId) async {
    try {
      print('Querying Firestore for parents in schoolId: $schoolId');
      final snapshot = await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('parents')
          .get();
      print('Firestore returned ${snapshot.docs.length} parent documents');
      return snapshot.docs.map((doc) => Parent.fromFirestore(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Firestore error: $e');
      throw Exception('خطأ في جلب أولياء الأمور: $e');
    }
  }

  Future<List<Parent>> getAllParents() async {
    try {
      print('Querying Firestore for all parents');
      final schoolsSnapshot = await _firestore.collection('schools').get();
      List<Parent> allParents = [];
      for (var schoolDoc in schoolsSnapshot.docs) {
        final parentsSnapshot = await _firestore
            .collection('schools')
            .doc(schoolDoc.id)
            .collection('parents')
            .get();
        allParents.addAll(parentsSnapshot.docs.map((doc) => Parent.fromFirestore(doc.data(), doc.id)));
      }
      print('Firestore returned ${allParents.length} parents across all schools');
      return allParents;
    } catch (e) {
      print('Firestore error: $e');
      throw Exception('خطأ في جلب جميع أولياء الأمور: $e');
    }
  }

  Future<void> updateParent({
    required String schoolId,
    required String parentId,
    required List<String> studentIds,
  }) async {
    try {
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('parents')
          .doc(parentId)
          .update({'studentIds': studentIds});
    } catch (e) {
      throw Exception('خطأ في تحديث ولي الأمر: $e');
    }
  }

  Future<void> updateParentFull({
    required String schoolId,
    required String parentId,
    required Parent updatedParent,
  }) async {
    try {
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('parents')
          .doc(parentId)
          .update(updatedParent.toFirestore());
    } catch (e) {
      throw Exception('خطأ في تحديث بيانات ولي الأمر: $e');
    }
  }


  Future<void> deleteParent(String schoolId, String parentId) async {
    try {
      // حذف ولي الأمر من Firestore
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('parents')
          .doc(parentId)
          .delete();

      // تحديث الطلاب المرتبطين بإزالة parentId
      final studentsSnapshot = await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .where('parentId', isEqualTo: parentId)
          .get();

      for (var doc in studentsSnapshot.docs) {
        await doc.reference.update({'parentId': null});
      }
    } catch (e) {
      throw Exception('خطأ في حذف ولي الأمر: $e');
    }
  }
}