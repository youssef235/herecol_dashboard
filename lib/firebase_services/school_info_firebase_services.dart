import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/school_info_model.dart'; // Updated to correct file

class SchoolFirebaseServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addSchoolInfo(Schoolinfo schoolInfo) async {
    await _firestore.collection('schools').doc(schoolInfo.schoolId).set(schoolInfo.toMap());
  }

  Future<List<Schoolinfo>> getSchools() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('schools').get();
      return snapshot.docs.map((doc) {
        return Schoolinfo.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception("خطأ في تحميل المدارس: $e");
    }
  }

  Future<Schoolinfo?> getSchoolInfo(String schoolId) async {
    DocumentSnapshot doc = await _firestore.collection('schools').doc(schoolId).get();
    if (doc.exists) {
      return Schoolinfo.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }
}