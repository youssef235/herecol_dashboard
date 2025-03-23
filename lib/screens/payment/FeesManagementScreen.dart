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
  String selectedLanguage = 'ar'; // اللغة الافتراضية: العربية

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      if (authState.role == 'school') {
        selectedSchoolId = widget.schoolId ?? authState.uid;
        context.read<StudentCubit>().streamStudents(schoolId: selectedSchoolId!);
      } else if (authState.role == 'admin') {
        context.read<SchoolCubit>().fetchSchools(authState.uid, authState.role);
        context.read<StudentCubit>().streamAllStudents();
      } else if (authState.role == 'employee') {
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
      return Scaffold(
        body: Center(
          child: Text(
            selectedLanguage == 'ar' ? 'يرجى تسجيل الدخول' : 'Veuillez vous connecter',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedLanguage == 'ar' ? 'إدارة المصاريف' : 'Gestion des frais',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          // زر اختيار اللغة
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<String>(
              value: selectedLanguage,
              icon: const Icon(Icons.language, color: Colors.white),
              underline: const SizedBox(),
              dropdownColor: Colors.white,
              items: [
                DropdownMenuItem(
                  value: 'ar',
                  child: Text('العربية', style: const TextStyle(color: Colors.blueAccent)),
                ),
                DropdownMenuItem(
                  value: 'fr',
                  child: Text('Français', style: const TextStyle(color: Colors.blueAccent)),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedLanguage = value!;
                });
              },
            ),
          ),
        ],
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
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
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
                              _buildSectionTitle(
                                selectedLanguage == 'ar' ? 'اختيار المدرسة' : 'Choisir l’école',
                              ),
                              DropdownButtonFormField<String>(
                                decoration: _buildInputDecoration(
                                  selectedLanguage == 'ar' ? 'المدرسة' : 'École',
                                ),
                                value: selectedSchoolId,
                                items: schoolState.schools.map((school) {
                                  return DropdownMenuItem(
                                    value: school.schoolId,
                                    child: Text(
                                      selectedLanguage == 'ar'
                                          ? school.schoolName['ar'] ?? ''
                                          : school.schoolName['fr'] ?? '',
                                      style: const TextStyle(fontSize: 16),
                                    ),
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
                                validator: (value) => value == null
                                    ? (selectedLanguage == 'ar' ? 'مطلوب' : 'Requis')
                                    : null,
                              ),
                            ],
                          );
                        } else if (schoolState is SchoolError) {
                          return Center(
                            child: Text(
                              schoolState.message,
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              if (selectedSchoolId != null)
                StudentsListScreen(schoolId: selectedSchoolId!, language: selectedLanguage),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.blueAccent),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      prefixIcon: const Icon(Icons.school, color: Colors.blueAccent),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.bookmark, color: Colors.blueAccent, size: 28),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }
}