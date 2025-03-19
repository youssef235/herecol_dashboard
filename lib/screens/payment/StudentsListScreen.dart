import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_dashboard/screens/payment/StudentPaymentsScreen.dart';
import '../../cubit/student/student_cubit.dart';
import '../../cubit/student/student_state.dart';
import '../../models/student_model.dart';

class StudentsListScreen extends StatelessWidget {
  final String schoolId;

  const StudentsListScreen({required this.schoolId});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'قائمة الطلاب / Liste des étudiants',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ),
          BlocBuilder<StudentCubit, StudentState>(
            builder: (context, state) {
              if (state is StudentLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is StudentsLoaded) {
                final students = state.students;
                if (students.isEmpty) {
                  return const Center(child: Text('لا يوجد طلاب / Aucun étudiant'));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return _buildStudentCard(context, student); // تم تمرير context هنا
                  },
                );
              } else if (state is StudentError) {
                return Center(child: Text(state.message));
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, Student student) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
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
              backgroundImage: NetworkImage(student.profileImage ?? ''),
              onBackgroundImageError: (exception, stackTrace) {
                // يمكنك وضع صورة افتراضية في حالة عدم وجود صورة
              },
              child: student.profileImage == null
                  ? const Icon(Icons.person, size: 30)
                  : null,
            ),
            const SizedBox(width: 16),
            // معلومات الطالب
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${student.firstNameAr} ${student.lastNameAr}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${student.id}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الصف: ${student.gradeAr ?? 'غير معروف'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'المستحق: ${student.feesDue ?? 0} | المدفوع: ${student.feesPaid ?? 0}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            // زر الانتقال إلى صفحة المدفوعات
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.blueAccent),
              onPressed: () {
                Navigator.push(
                  context, // تم استخدام context هنا
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
    );
  }
}