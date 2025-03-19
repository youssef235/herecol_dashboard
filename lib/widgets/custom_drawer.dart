import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:school_management_dashboard/cubit/auth/auth_cubit.dart';
import '../cubit/auth/auth_state.dart';
import '../screens/Employee/AddEmployeeScreen.dart';
import '../screens/Employee/EmployeeListWithFilterScreen.dart';
import '../screens/Employee/SalaryCategoriesScreen.dart';
import '../screens/Employee/SalaryTrackingScreen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/payment/AccountingManagementScreen.dart';
import '../screens/payment/FeesManagementScreen.dart';
import '../screens/payment/LatePaymentsScreen.dart';
import '../screens/school_info/AddSchoolScreen.dart';
import '../screens/school_info/school_info_screen.dart';
import '../screens/stats/stats_screen.dart';
import '../screens/student/AttendanceScreen.dart';
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

  static final Map<String, Map<String, dynamic>> screenGroups = {
    'إدارة عامة / Gestion générale': {
      'icon': Ionicons.settings_outline,
      'screens': {
        'StatsScreen': {
          'icon': Ionicons.analytics_outline,
          'titleFrench': 'Statistiques',
          'titleArabic': 'الإحصاءات',
          'widget': StatsScreen(),
        },
        'SchoolInfoScreen': {
          'icon': Ionicons.school_outline,
          'titleFrench': 'Informations sur l’école',
          'titleArabic': 'معلومات المدرسة',
          'widget': SchoolInfoScreen(),
        },
        'AddSchoolScreen': {
          'icon': Ionicons.add_circle_outline,
          'titleFrench': 'Ajouter une école',
          'titleArabic': 'إضافة مدرسة',
          'widget': AddSchoolScreen(),
        },
      },
    },
    'إدارة الطلاب / Gestion des étudiants': {
      'icon': Ionicons.person_outline,
      'screens': {
        'AddStudentScreen': {
          'icon': Ionicons.person_add_outline,
          'titleFrench': 'Ajouter un étudiant',
          'titleArabic': 'إضافة طالب',
        },
        'StudentListScreen': {
          'icon': Ionicons.list_outline,
          'titleFrench': 'Liste des étudiants',
          'titleArabic': 'قائمة الطلاب',
        },
        'AttendanceManagementScreen': {
          'icon': Ionicons.calendar_outline,
          'titleFrench': 'Gestion des présences et absences',
          'titleArabic': 'إدارة الحضور والغياب',
        },
      },
    },
    'إدارة المالية / Gestion financière': {
      'icon': Ionicons.cash_outline,
      'screens': {
        'FeesManagementScreen': {
          'icon': Ionicons.cash_outline,
          'titleFrench': 'Gestion des frais',
          'titleArabic': 'إدارة المصاريف',
        },
        'LatePaymentsScreen': {
          'icon': Ionicons.alarm_outline,
          'titleFrench': 'Étudiants en retard de paiement',
          'titleArabic': 'الطلاب المتأخرون عن الدفع',
        },
        'AccountingManagementScreen': {
          'icon': Ionicons.calculator_outline,
          'titleFrench': 'Gestion de la comptabilité',
          'titleArabic': 'إدارة المحاسبة',
        },
      },
    },
    'إدارة الموظفين / Gestion des employés': {
      'icon': Ionicons.people_outline,
      'screens': {
        'EmployeeListWithFilterScreen': {
          'icon': Ionicons.people_outline,
          'titleFrench': 'Liste des employés avec filtre',
          'titleArabic': 'قائمة الموظفين مع التصفية',
        },
        'AddEmployeeScreen': {
          'icon': Ionicons.person_add_outline,
          'titleFrench': 'Ajouter un employé',
          'titleArabic': 'إضافة موظف',
        },
        'SalaryCategoriesScreen': {
          'icon': Ionicons.wallet_outline,
          'titleFrench': 'Catégories de salaires',
          'titleArabic': 'فئات الرواتب',
        },
        'SalaryTrackingScreen': {
          'icon': Ionicons.time_outline,
          'titleFrench': 'Suivi des paiements de salaires',
          'titleArabic': 'تتبع دفع الرواتب',
        },
      },
    },
  };

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const SizedBox.shrink();
    }

    final permissions = authState.permissions ?? [];
    final schoolId = authState.schoolId ?? uid;

    // إذا كان المستخدم admin أو school، يحصل على جميع الشاشات، وإلا يعتمد على الصلاحيات
    final allowedScreens = (role == 'admin' || role == 'school')
        ? screenGroups.values.expand((group) => group['screens'].keys).toList()
        : permissions;

    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.white,
        dividerColor: Colors.grey[300],
      ),
      child: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              _buildDrawerHeader(context),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 10),
                    ...screenGroups.entries.map((groupEntry) {
                      final groupTitle = groupEntry.key;
                      final groupIcon = groupEntry.value['icon'] as IconData;
                      final screens = groupEntry.value['screens'] as Map<String, Map<String, dynamic>>;

                      final filteredScreens = screens.entries
                          .where((screenEntry) => allowedScreens.contains(screenEntry.key))
                          .toList();

                      if (filteredScreens.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      if (groupTitle.contains('إدارة عامة') && role != 'admin') {
                        filteredScreens.removeWhere((entry) => entry.key == 'AddSchoolScreen');
                        if (filteredScreens.isEmpty) return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(groupIcon, color: Colors.blue[700], size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            groupTitle.split('/')[1].trim(), // الفرنسية أولاً
                                            style: GoogleFonts.cairo(
                                              color: Colors.blue[800], // لون أغمق للفرنسية
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold, // سمك موحد
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            groupTitle.split('/')[0].trim(), // العربية ثانياً
                                            style: GoogleFonts.cairo(
                                              color: Colors.blue[600], // لون أفتح للعربية
                                              fontSize: 16, // نفس الحجم للوضوح
                                              fontWeight: FontWeight.bold, // سمك موحد
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
                            collapsedBackgroundColor: Colors.blue[50],
                            backgroundColor: Colors.blue[100],
                            leading: const SizedBox.shrink(),
                            title: const SizedBox.shrink(),
                            children: filteredScreens.map((screenEntry) {
                              final screenKey = screenEntry.key;
                              final screenData = screenEntry.value;
                              Widget screenWidget;

                              switch (screenKey) {
                                case 'AddStudentScreen':
                                  screenWidget = AddStudentScreen(role: role, uid: uid);
                                  break;
                                case 'StudentListScreen':
                                  screenWidget = StudentListScreen(
                                      schoolId: role == 'school' ? uid : schoolId);
                                  break;
                                case 'AttendanceManagementScreen':
                                  screenWidget = BlocProvider.value(
                                    value: context.read<AuthCubit>(),
                                    child: AttendanceManagementScreen(
                                        schoolId: role == 'school' ? uid : schoolId),
                                  );
                                  break;
                                case 'FeesManagementScreen':
                                  screenWidget = FeesManagementScreen(
                                      schoolId: role == ' dialogsSchool' ? uid : schoolId);
                                  break;
                                case 'LatePaymentsScreen':
                                  screenWidget = LatePaymentsScreen(
                                    schoolId: role == 'school' ? uid : schoolId,
                                    role: role,
                                  );
                                  break;
                                case 'AccountingManagementScreen':
                                  screenWidget = AccountingManagementScreen(
                                      schoolId: role == 'school' ? uid : schoolId);
                                  break;
                                case 'EmployeeListWithFilterScreen':
                                  screenWidget = EmployeeListWithFilterScreen(
                                      schoolId: role == 'school' ? uid : schoolId);
                                  break;
                                case 'AddEmployeeScreen':
                                  screenWidget = AddEmployeeScreen(
                                      schoolId: role == 'school' ? uid : schoolId);
                                  break;
                                case 'SalaryCategoriesScreen':
                                  screenWidget = SalaryCategoriesScreen(
                                      schoolId: role == 'school' ? uid : schoolId);
                                  break;
                                case 'SalaryTrackingScreen':
                                  screenWidget = SalaryTrackingScreen(
                                      schoolId: role == 'school' ? uid : schoolId);
                                  break;
                                default:
                                  screenWidget = screenData['widget'] as Widget;
                              }

                              return _buildDrawerItem(
                                context,
                                icon: screenData['icon'] as IconData,
                                titleFrench: screenData['titleFrench'] as String,
                                titleArabic: screenData['titleArabic'] as String,
                                screen: screenWidget,
                              );
                            }).toList(),
                          ),
                          const Divider(color: Colors.grey, thickness: 1),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
              _buildLogoutSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(
            role == 'admin'
            ? 'Tableau de bord Super Admin'
                : role == 'school'
            ? 'Tableau de bord de l’école'
              : 'Tableau de bord des employés',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              role == 'admin'
                  ? 'لوحة تحكم المشرف العام'
                  : role == 'school'
                  ? 'لوحة تحكم المدرسة'
                  : 'لوحة تحكم الموظفين',
              style: GoogleFonts.cairo(
                color: Colors.white70,
                fontSize: 14,
              ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
    IconButton(
    icon: const Icon(Ionicons.close, color: Colors.white),
    onPressed: () => Navigator.pop(context),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.blue[700], size: 24),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleFrench,
                style: GoogleFonts.cairo(
                  color: Colors.blue[800], // لون أغمق قليلاً للفرنسية
                  fontSize: 14,
                  fontWeight: FontWeight.w600, // نفس السمك لكلا اللغتين
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                titleArabic,
                style: GoogleFonts.cairo(
                  color: Colors.blue[600], // لون أفتح قليلاً للعربية
                  fontSize: 14, // نفس الحجم لتوحيد الوضوح
                  fontWeight: FontWeight.w600, // نفس السمك لكلا اللغتين
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => screen),
            );
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          hoverColor: Colors.blue[100],
          selectedTileColor: Colors.blue[50],
        ),
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('تأكيد تسجيل الخروج', style: GoogleFonts.cairo()),
              content: Text('هل أنت متأكد أنك تريد تسجيل الخروج؟', style: GoogleFonts.cairo()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إلغاء', style: GoogleFonts.cairo()),
                ),
                TextButton(
                  onPressed: () {
                    context.read<AuthCubit>().logout();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text('تسجيل الخروج', style: GoogleFonts.cairo(color: Colors.red)),
                ),
              ],
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Ionicons.log_out_outline, color: Colors.red[700], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Déconnexion',
                      style: GoogleFonts.cairo(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}