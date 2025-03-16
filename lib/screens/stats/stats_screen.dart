import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:school_management_dashboard/cubit/auth/auth_state.dart';
import 'package:school_management_dashboard/cubit/stats/state_cubit.dart';
import 'package:school_management_dashboard/firebase_services/stats_firebase_services.dart';
import 'package:school_management_dashboard/widgets/stats_card.dart';
import '../../cubit/stats/stat_state.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/custom_drawer.dart';
import '../../cubit/auth/auth_cubit.dart';

class StatsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final String? userRole = authState is AuthAuthenticated ? authState.role : null;
    final String? uid = authState is AuthAuthenticated ? authState.uid : null;

    if (userRole == null || uid == null) {
      return Scaffold(body: Center(child: Text('يرجى تسجيل الدخول / Veuillez vous connecter')));
    }

    return BlocProvider(
      create: (context) => StatsCubit(StatsFirebaseServices())
        ..streamStats(schoolId: userRole == 'school' ? uid : null),
      child: Scaffold(
        appBar: CustomAppBar(title: 'الإحصائيات / Statistiques', showBackButton: false),
        drawer: CustomDrawer(role: userRole, uid: uid),
        body: BlocBuilder<StatsCubit, StatsState>(
          builder: (context, state) {
            if (state is StatsLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is StatsLoaded) {
              final stats = state.stats;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent.shade100, Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          StatsCard(
                            titleAr: 'إجمالي الطلاب',
                            titleFr: 'Total des étudiants',
                            value: stats.totalStudents,
                            icon: Icons.people,
                            gradient: LinearGradient(
                              colors: [Colors.blue, Colors.lightBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          if (userRole == 'admin') ...[
                            StatsCard(
                              titleAr: 'إجمالي المعلمين',
                              titleFr: 'Total des enseignants',
                              value: stats.totalTeachers,
                              icon: Icons.school,
                              gradient: LinearGradient(
                                colors: [Colors.green, Colors.lightGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            StatsCard(
                              titleAr: 'إجمالي المحاسبين',
                              titleFr: 'Total des comptables',
                              value: stats.totalAccountants,
                              icon: Icons.account_balance_wallet,
                              gradient: LinearGradient(
                                colors: [Colors.orange, Colors.deepOrange],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            StatsCard(
                              titleAr: 'عدد المدارس',
                              titleFr: 'Nombre d’écoles',
                              value: stats.totalSchools,
                              icon: Icons.business,
                              gradient: LinearGradient(
                                colors: [Colors.purple, Colors.deepPurple],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ],
                          StatsCard(
                            titleAr: 'نسبة الطلاب إلى المعلمين',
                            titleFr: 'Ratio étudiants/enseignants',
                            value: stats.studentToTeacherRatio.toStringAsFixed(2),
                            icon: Icons.analytics,
                            gradient: LinearGradient(
                              colors: [Colors.red, Colors.pink],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          StatsCard(
                            titleAr: 'الطلاب الحاضرون اليوم',
                            titleFr: 'Étudiants présents aujourd’hui',
                            value: stats.presentStudents ?? 0,
                            icon: Icons.check_circle,
                            gradient: LinearGradient(
                              colors: [Colors.teal, Colors.cyan],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          StatsCard(
                            titleAr: 'الطلاب الغائبون اليوم',
                            titleFr: 'Étudiants absents aujourd’hui',
                            value: stats.absentStudents ?? 0,
                            icon: Icons.cancel,
                            gradient: LinearGradient(
                              colors: [Colors.redAccent, Colors.red],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          StatsCard(
                            titleAr: 'إجمالي الرسوم المستحقة',
                            titleFr: 'Total des frais dus',
                            value: stats.totalFeesDue?.toStringAsFixed(2) ?? '0.00',
                            icon: Icons.money,
                            gradient: LinearGradient(
                              colors: [Colors.yellow, Colors.amber],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      if (userRole == 'admin') ...[
                        _buildSectionTitle('عدد الطلاب حسب المدرسة', 'Nombre d’étudiants par école'),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: stats.studentsPerSchool.entries.map((entry) {
                              final schoolNameMap = stats.schoolNames[entry.key] ?? {'ar': entry.key, 'fr': entry.key};
                              final arName = schoolNameMap['ar'] ?? entry.key;
                              final frName = schoolNameMap['fr'] ?? entry.key;
                              return ListTile(
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(arName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    Text(frName, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                  ],
                                ),
                                trailing: Text('${entry.value} طالب', style: TextStyle(fontSize: 16, color: Colors.blue)),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(height: 24),
                      ],
                      _buildSectionTitle('عدد الطلاب حسب الصف', 'Nombre d’étudiants par classe'),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: stats.studentsPerGrade.entries.map((entry) {
                            return ListTile(
                              title: Text('الصف ${entry.key}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              trailing: Text('${entry.value} طالب', style: TextStyle(fontSize: 16, color: Colors.blue)),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: 24),
                      _buildSectionTitle('توزيع الطلاب حسب الجنس', 'Répartition des étudiants par genre'),
                      SizedBox(height: 16),
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: (stats.maleStudents == 0 && stats.femaleStudents == 0)
                            ? Center(child: Text('لا توجد بيانات لتوزيع الجنس', style: TextStyle(fontSize: 16, color: Colors.grey)))
                            : PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: stats.maleStudents?.toDouble() ?? 0,
                                title: 'الذكور (${((stats.maleStudents ?? 0) / stats.totalStudents * 100).toStringAsFixed(1)}%)',
                                color: Colors.blue,
                                radius: 100,
                                titleStyle: TextStyle(fontSize: 14, color: Colors.white),
                              ),
                              PieChartSectionData(
                                value: stats.femaleStudents?.toDouble() ?? 0,
                                title: 'الإناث (${((stats.femaleStudents ?? 0) / stats.totalStudents * 100).toStringAsFixed(1)}%)',
                                color: Colors.pink,
                                radius: 100,
                                titleStyle: TextStyle(fontSize: 14, color: Colors.white),
                              ),
                            ],
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      _buildSectionTitle('توزيع الحضور اليومي', 'Répartition de la présence quotidienne'),
                      SizedBox(height: 16),
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: (stats.presentStudents == 0 && stats.absentStudents == 0)
                            ? Center(child: Text('لا توجد بيانات حضور اليوم', style: TextStyle(fontSize: 16, color: Colors.grey)))
                            : PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: stats.presentStudents?.toDouble() ?? 0,
                                title: 'حاضرون (${((stats.presentStudents ?? 0) / stats.totalStudents * 100).toStringAsFixed(1)}%)',
                                color: Colors.green,
                                radius: 100,
                                titleStyle: TextStyle(fontSize: 14, color: Colors.white),
                              ),
                              PieChartSectionData(
                                value: stats.absentStudents?.toDouble() ?? 0,
                                title: 'غائبون (${((stats.absentStudents ?? 0) / stats.totalStudents * 100).toStringAsFixed(1)}%)',
                                color: Colors.red,
                                radius: 100,
                                titleStyle: TextStyle(fontSize: 14, color: Colors.white),
                              ),
                            ],
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _buildSectionTitle('توزيع الطلاب حسب الصفوف', 'Répartition des étudiants par classes'),
                                SizedBox(height: 8),
                                Container(
                                  height: 300,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      barGroups: stats.studentsPerGrade.entries.map((entry) {
                                        int? grade = int.tryParse(entry.key);
                                        return BarChartGroupData(
                                          x: grade ?? 0,
                                          barRods: [
                                            BarChartRodData(toY: entry.value.toDouble(), color: Colors.blue),
                                          ],
                                        );
                                      }).toList(),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (double value, TitleMeta meta) {
                                              return Text('الصف ${value.toInt()}');
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (double value, TitleMeta meta) {
                                              return Text(value.toInt().toString());
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                _buildSectionTitle('نسب الطلاب حسب الصف', 'Pourcentages des étudiants par classe'),
                                SizedBox(height: 8),
                                Container(
                                  height: 300,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      PieChart(
                                        PieChartData(
                                          sections: stats.studentsPerGrade.entries.map((entry) {
                                            return PieChartSectionData(
                                              value: entry.value.toDouble(),
                                              title: 'الصف ${entry.key} (${((entry.value) / stats.totalStudents * 100).toStringAsFixed(1)}%)',
                                              color: Colors.primaries[entry.key.hashCode % Colors.primaries.length],
                                              radius: 100,
                                              titleStyle: TextStyle(fontSize: 12, color: Colors.white),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 16,
                                        left: 16,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: stats.studentsPerGrade.entries.map((entry) {
                                            return Row(
                                              children: [
                                                Container(
                                                  width: 12,
                                                  height: 12,
                                                  color: Colors.primaries[entry.key.hashCode % Colors.primaries.length],
                                                ),
                                                SizedBox(width: 8),
                                                Text('الصف ${entry.key}'),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            } else if (state is StatsError) {
              return Center(child: Text(state.message));
            }
            return Container();
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String titleAr, String titleFr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titleAr, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        Text(titleFr, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
      ],
    );
  }
}