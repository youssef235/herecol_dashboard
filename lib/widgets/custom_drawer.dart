import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:school_management_dashboard/cubit/auth/auth_cubit.dart';

import '../screens/auth/login_screen.dart';
import '../screens/school_info/AddSchoolScreen.dart';
import '../screens/school_info/school_info_screen.dart';
import '../screens/stats/stats_screen.dart';
import '../screens/student/AttendanceScreen.dart';
import '../screens/student/FeesManagementScreen.dart';
import '../screens/student/add_student_screen.dart';
import '../screens/student/student_list_screen.dart';

class CustomDrawer extends StatelessWidget {
  final String role;
  final String uid;

  const CustomDrawer({
    Key? key,
    required this.role,
    required this.uid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildDrawerHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Ionicons.analytics_outline,
                  titleFrench: 'Statistiques',
                  titleArabic: 'الإحصاءات',
                  screen: StatsScreen(),
                ),
                _buildDrawerItem(
                  context,
                  icon: Ionicons.school_outline,
                  titleFrench: 'Informations sur l’école',
                  titleArabic: 'معلومات المدرسة',
                  screen: SchoolInfoScreen(),
                ),
                _buildDrawerItem(
                  context,
                  icon: Ionicons.person_add_outline,
                  titleFrench: 'Ajouter un étudiant',
                  titleArabic: 'إضافة طالب',
                  screen: AddStudentScreen(
                    role: role,
                    uid: uid,
                  ),
                ),
                _buildDrawerItem(
                  context,
                  icon: Ionicons.list_outline,
                  titleFrench: 'Liste des étudiants',
                  titleArabic: 'قائمة الطلاب',
                  screen: StudentListScreen(
                    schoolId: role == 'school' ? uid : null,
                  ),
                ),
                _buildDrawerItem(
                  context,
                  icon: Ionicons.calendar_outline,
                  titleFrench: 'Gestion des présences et absences',
                  titleArabic: 'إدارة الحضور والغياب',
                  screen: BlocProvider.value(
                    value: context.read<AuthCubit>(),
                    child: AttendanceManagementScreen(
                      schoolId: role == 'school' ? uid : null,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  context,
                  icon: Ionicons.cash_outline,
                  titleFrench: 'Gestion des frais financiers',
                  titleArabic: 'إدارة الرسوم المالية',
                  screen: BlocProvider.value(
                    value: context.read<AuthCubit>(),
                    child: FeesManagementScreen(
                      schoolId: role == 'school' ? uid : null,
                    ),
                  ),
                ),
                if (role == 'admin')
                  _buildDrawerItem(
                    context,
                    icon: Ionicons.add_circle_outline,
                    titleFrench: 'Ajouter une école',
                    titleArabic: 'إضافة مدرسة',
                    screen: AddSchoolScreen(),
                  ),
              ],
            ),
          ),
          _buildLogoutSection(context),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      color: Colors.blue[600],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(
              role == 'admin' ? Ionicons.shield_checkmark : Ionicons.school,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            role == 'admin' ? 'Tableau de bord Super Admin' : 'Tableau de bord de l’école',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            role == 'admin' ? 'لوحة تحكم المشرف العام' : 'لوحة تحكم المدرسة',
            style: GoogleFonts.cairo(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String titleFrench,
        required String titleArabic,
        required Widget screen,
      }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[700]),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleFrench,
            style: GoogleFonts.cairo(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            titleArabic,
            style: GoogleFonts.cairo(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      hoverColor: Colors.blue.withOpacity(0.1),
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(Ionicons.log_out_outline, color: Colors.red),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Déconnexion',
              style: GoogleFonts.cairo(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'تسجيل الخروج',
              style: GoogleFonts.cairo(
                color: Colors.red[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () {
          context.read<AuthCubit>().logout();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        },
      ),
    );
  }
}