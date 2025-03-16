import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_dashboard/cubit/student/student_cubit.dart';
import 'package:school_management_dashboard/firebase_services/school_info_firebase_services.dart';
import 'package:school_management_dashboard/firebase_services/stats_firebase_services.dart';
import 'package:school_management_dashboard/firebase_services/student_firebase_services.dart';
import 'package:school_management_dashboard/screens/school_info/AddSchoolScreen.dart';
import 'package:school_management_dashboard/screens/school_info/school_info_screen.dart';
import 'package:school_management_dashboard/screens/stats/stats_screen.dart';
import 'package:school_management_dashboard/screens/student/add_student_screen.dart';
import 'package:school_management_dashboard/cubit/school_info/school_info_cubit.dart';
import 'package:school_management_dashboard/cubit/stats/state_cubit.dart';
import 'package:school_management_dashboard/cubit/auth/auth_cubit.dart';
import 'package:school_management_dashboard/screens/auth/login_screen.dart';
import 'cubit/auth/auth_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAY3N3Ekmj_drw3P2QlsyyWiW1OPkG0jxU",
      authDomain: "forrent-b4654.firebaseapp.com",
      projectId: "forrent-b4654",
      storageBucket: "forrent-b4654.appspot.com",
      messagingSenderId: "603917507536",
      appId: "1:603917507536:web:a5cea742df6380029237d5",
      measurementId: "G-8XP91P1R4E",
    ),
  );

  // تهيئة مدير النوافذ
  await windowManager.ensureInitialized();

  runApp(MyApp());

  // ضبط حجم النافذة بعد تشغيل التطبيق
  await Future.delayed(const Duration(milliseconds: 500));
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      fullScreen: false, // تشغيل التطبيق بوضع ملء الشاشة
      title: 'نظام إدارة المدرسة',
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
    ),
        () async {
      await windowManager.maximize(); // فرض وضع ملء الشاشة
      await windowManager.show();
    },
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthCubit(FirebaseAuth.instance, FirebaseFirestore.instance)),
        BlocProvider(create: (context) => StatsCubit(StatsFirebaseServices())),
        BlocProvider(create: (context) => StudentCubit(StudentFirebaseServices())),
        BlocProvider(create: (context) => SchoolCubit(SchoolFirebaseServices())),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Système de gestion scolaire',
        theme: ThemeData(scaffoldBackgroundColor: Colors.white),
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              return StatsScreen();
            }
            return LoginScreen();
          },
        ),
        routes: {
          '/stats': (context) => StatsScreen(),
          '/add_student': (context) => AddStudentScreen(
            role: (context.read<AuthCubit>().state as AuthAuthenticated).role,
            uid: (context.read<AuthCubit>().state as AuthAuthenticated).uid,
          ),
          '/school_info': (context) => SchoolInfoScreen(),
          '/login': (context) => LoginScreen(),
          '/signup': (context) => AddSchoolScreen(),
        },
      ),
    );
  }
}
