import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_dashboard/screens/payment/StudentsListScreen.dart';
import '../../cubit/auth/auth_cubit.dart';
import '../../cubit/auth/auth_state.dart';
import '../../cubit/school_info/school_info_cubit.dart';
import '../../cubit/school_info/school_info_state.dart';
import '../../cubit/student/student_cubit.dart';



class FeesManagementScreen extends StatefulWidget {
  final String? schoolId;

  const FeesManagementScreen({this.schoolId});

  @override
  _FeesManagementScreenState createState() => _FeesManagementScreenState();
}

class _FeesManagementScreenState extends State<FeesManagementScreen> {
  String? selectedSchoolId;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      if (authState.role == 'school') {
        // إذا كان المستخدم مدرسة، استخدم uid كـ schoolId
        selectedSchoolId = widget.schoolId ?? authState.uid;
        context.read<StudentCubit>().streamStudents(schoolId: selectedSchoolId!);
      } else if (authState.role == 'admin') {
        // إذا كان المستخدم admin، جلب جميع المدارس وجميع الطلاب
        context.read<SchoolCubit>().fetchSchools(authState.uid, authState.role);
        context.read<StudentCubit>().streamAllStudents();
      } else if (authState.role == 'employee') {
        // إذا كان المستخدم موظفًا، استخدم schoolId من حالة المصادقة
        selectedSchoolId = authState.schoolId;
        if (selectedSchoolId != null) {
          context.read<StudentCubit>().streamStudents(schoolId: selectedSchoolId!);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('يرجى تسجيل الدخول')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المصاريف / Gestion des frais', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (authState.role == 'admin')
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 5,
                        blurRadius: 7,
                      ),
                    ],
                  ),
                  child: BlocBuilder<SchoolCubit, SchoolState>(
                    builder: (context, schoolState) {
                      if (schoolState is SchoolsLoaded) {
                        if (selectedSchoolId == null && schoolState.schools.isNotEmpty) {
                          selectedSchoolId = schoolState.schools.first.schoolId;
                          context.read<StudentCubit>().streamStudents(schoolId: selectedSchoolId!);
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('اختيار المدرسة / Choisir l’école'),
                            DropdownButtonFormField<String>(
                              decoration: _buildInputDecoration('المدرسة / École'),
                              value: selectedSchoolId,
                              items: schoolState.schools.map((school) {
                                return DropdownMenuItem(
                                  value: school.schoolId,
                                  child: Text('${school.schoolName['ar'] ?? ''} / ${school.schoolName['fr'] ?? ''}'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedSchoolId = value;
                                  if (value != null) {
                                    context.read<StudentCubit>().streamStudents(schoolId: value);
                                  }
                                });
                              },
                              validator: (value) => value == null ? 'مطلوب' : null,
                            ),
                          ],
                        );
                      } else if (schoolState is SchoolError) {
                        return Center(child: Text(schoolState.message));
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              const SizedBox(height: 24),
              if (selectedSchoolId != null) StudentsListScreen(schoolId: selectedSchoolId!),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }
}