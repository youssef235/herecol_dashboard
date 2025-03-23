import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_dashboard/screens/payment/StudentPaymentsScreen.dart';
import '../../cubit/student/student_cubit.dart';
import '../../cubit/student/student_state.dart';
import '../../models/student_model.dart';

class StudentsListScreen extends StatelessWidget {
  final String schoolId;
  final String language;

  const StudentsListScreen({required this.schoolId, required this.language});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.group, color: Colors.blueAccent, size: 28),
                const SizedBox(width: 8),
                Text(
                  language == 'ar' ? 'قائمة الطلاب' : 'Liste des étudiants',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
          BlocBuilder<StudentCubit, StudentState>(
            builder: (context, state) {
              if (state is StudentLoading) {
                return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
              } else if (state is StudentsLoaded) {
                final students = state.students;
                if (students.isEmpty) {
                  return Center(
                    child: Text(
                      language == 'ar' ? 'لا يوجد طلاب' : 'Aucun étudiant',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return _buildStudentCard(context, student);
                  },
                );
              } else if (state is StudentError) {
                return Center(
                  child: Text(
                    state.message,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, Student student) {
    final hasProfileImage = student.profileImage != null && student.profileImage!.isNotEmpty;

    return InkWell(
      onTap: (){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentPaymentsScreen(
              schoolId: schoolId,
              studentId: student.id,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // صورة الطالب
              CircleAvatar(
                radius: 30,
                backgroundImage: hasProfileImage ? NetworkImage(student.profileImage!) : null,
                onBackgroundImageError: hasProfileImage ? (exception, stackTrace) {} : null,
                child: !hasProfileImage
                    ? const Icon(Icons.person, size: 30, color: Colors.blueAccent)
                    : null,
              ),
              const SizedBox(width: 16),
              // معلومات الطالب
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language == 'ar'
                          ? '${student.firstNameAr} ${student.lastNameAr}'
                          : '${student.firstNameFr} ${student.lastNameFr}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ID: ${student.id}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      language == 'ar'
                          ? 'الصف: ${student.gradeAr ?? 'غير معروف'}'
                          : 'Classe: ${student.gradeFr ?? 'Inconnu'}',
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      language == 'ar'
                          ? 'المستحق: ${student.totalFeesDue ?? 0} | المدفوع: ${student.feesPaid ?? 0}'
                          : 'Dû: ${student.totalFeesDue ?? 0} | Payé: ${student.feesPaid ?? 0}',
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              // زر الانتقال إلى صفحة المدفوعات
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.blueAccent, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentPaymentsScreen(
                        schoolId: schoolId,
                        studentId: student.id,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}