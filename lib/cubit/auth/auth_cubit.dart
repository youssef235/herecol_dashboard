import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/school_info_model.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  static const String superAdminEmail = "admin@xai.com";

  AuthCubit(this._firebaseAuth, this._firestore) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String role = email == superAdminEmail ? 'admin' : 'school';
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();

      if (userDoc.exists) {
        emit(AuthAuthenticated(
          role: role,
          uid: userCredential.user!.uid,
          email: userCredential.user!.email,
        ));
      } else {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'role': role,
          'schoolId': role == 'school' ? userCredential.user!.uid : null,
        });
        emit(AuthAuthenticated(
          role: role,
          uid: userCredential.user!.uid,
          email: email,
        ));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? "حدث خطأ أثناء تسجيل الدخول"));
    }
  }

  Future<void> signUp(String email, String password, Schoolinfo schoolInfo) async {
    emit(AuthLoading());
    try {
      print("Starting signUp with email: $email");
      final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String role = email == superAdminEmail ? 'admin' : 'school';
      String uid = userCredential.user!.uid;
      print("User created with UID: $uid");

      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'role': role,
        'schoolId': role == 'school' ? uid : null,
      });
      print("User data saved in 'users' collection");

      if (role == 'school') {
        schoolInfo.schoolId = uid;
        schoolInfo.ownerId = uid;
        await _firestore.collection('schools').doc(uid).set(schoolInfo.toMap());
        print("School data saved in 'schools' collection");
      }

      emit(AuthAuthenticated(role: role, uid: uid, email: email));
      print("SignUp completed successfully");
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.message}");
      emit(AuthError(e.message ?? "حدث خطأ أثناء إنشاء الحساب"));
    } catch (e) {
      print("Unexpected error: $e");
      emit(AuthError("حدث خطأ غير متوقع: $e"));
    }
  }

  // دالة جديدة لإضافة مدرسة دون تسجيل الدخول
  Future<void> addSchoolWithoutLogin(String email, String password, Schoolinfo schoolInfo) async {
    emit(AuthLoading());
    try {
      print("Adding school without login with email: $email");
      final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;
      print("School user created with UID: $uid");

      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'role': 'school',
        'schoolId': uid,
      });
      print("School user data saved in 'users' collection");

      schoolInfo.schoolId = uid;
      schoolInfo.ownerId = uid;
      await _firestore.collection('schools').doc(uid).set(schoolInfo.toMap());
      print("School data saved in 'schools' collection");

      // لا نُصدر حالة AuthAuthenticated، فقط ننهي العملية
      emit(state); // الحفاظ على الحالة الحالية
      print("School added successfully without login");
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.message}");
      emit(AuthError(e.message ?? "حدث خطأ أثناء إضافة المدرسة"));
    } catch (e) {
      print("Unexpected error: $e");
      emit(AuthError("حدث خطأ غير متوقع: $e"));
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    emit(AuthUnauthenticated());
  }

  Future<void> updateEmail({
    required String currentEmail,
    required String currentPassword,
    required String newEmail,
  }) async {
    emit(AuthLoading());
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception("لا يوجد مستخدم مسجل الدخول");

      final credential = EmailAuthProvider.credential(email: currentEmail, password: currentPassword);
      await user.reauthenticateWithCredential(credential);

      await user.updateEmail(newEmail);
      await _firestore.collection('users').doc(user.uid).update({'email': newEmail});

      emit(AuthAuthenticated(
        role: newEmail == superAdminEmail ? 'admin' : 'school',
        uid: user.uid,
        email: newEmail,
      ));
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? "حدث خطأ أثناء تحديث البريد الإلكتروني"));
    } catch (e) {
      emit(AuthError('خطأ: $e'));
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(AuthLoading());
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception("لا يوجد مستخدم مسجل الدخول");

      final credential = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPassword);

      emit(AuthAuthenticated(
        role: user.email == superAdminEmail ? 'admin' : 'school',
        uid: user.uid,
        email: user.email,
      ));
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? "حدث خطأ أثناء تحديث كلمة المرور"));
    } catch (e) {
      emit(AuthError('خطأ: $e'));
    }
  }
}