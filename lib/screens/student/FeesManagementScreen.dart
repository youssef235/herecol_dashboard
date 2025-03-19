// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../cubit/auth/auth_cubit.dart';
// import '../../cubit/auth/auth_state.dart';
// import '../../cubit/school_info/school_info_cubit.dart';
// import '../../cubit/school_info/school_info_state.dart';
// import '../../cubit/student/student_cubit.dart';
// import '../../cubit/student/student_state.dart';
//
// class FeesManagementScreen extends StatefulWidget {
//   final String? schoolId;
//
//   const FeesManagementScreen({this.schoolId});
//
//   @override
//   _FeesManagementScreenState createState() => _FeesManagementScreenState();
// }
//
// class _FeesManagementScreenState extends State<FeesManagementScreen> {
//   String? selectedSchoolId;
//   Map<String, double> feesDueUpdates = {};
//   Map<String, double> feesPaidUpdates = {};
//   Map<String, TextEditingController> feesDueControllers = {};
//   Map<String, TextEditingController> feesPaidControllers = {};
//   bool isSaving = false;
//
//   @override
//   void initState() {
//     super.initState();
//     final authState = context.read<AuthCubit>().state;
//     if (authState is AuthAuthenticated) {
//       if (authState.role == 'school') {
//         selectedSchoolId = widget.schoolId ?? authState.uid;
//         print('Selected School ID (school role): $selectedSchoolId'); // للتتبع
//         context.read<StudentCubit>().streamStudents(schoolId: selectedSchoolId!);
//       } else {
//         context.read<SchoolCubit>().fetchSchools(authState.uid, authState.role);
//       }
//     }
//   }
//
//   void _updateFees() async {
//     setState(() {
//       isSaving = true;
//     });
//
//     final authState = context.read<AuthCubit>().state as AuthAuthenticated;
//     try {
//       for (var studentId in feesDueUpdates.keys) {
//         print('Updating $studentId: Due=${feesDueUpdates[studentId]}, Paid=${feesPaidUpdates[studentId]}');
//          context.read<StudentCubit>().updateStudentFees(
//           schoolId: selectedSchoolId ?? authState.uid,
//           studentId: studentId,
//           feesDue: feesDueUpdates[studentId]!,
//           feesPaid: feesPaidUpdates[studentId]!,
//         );
//         feesDueControllers[studentId]?.text = feesDueUpdates[studentId]!.toString();
//         feesPaidControllers[studentId]?.text = feesPaidUpdates[studentId]!.toString();
//       }
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('تم حفظ المصاريف بنجاح')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('فشل في حفظ المصاريف: $e')),
//       );
//     } finally {
//       setState(() {
//         isSaving = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final authState = context.read<AuthCubit>().state;
//     if (authState is! AuthAuthenticated) {
//       return const Scaffold(body: Center(child: Text('يرجى تسجيل الدخول / Veuillez vous connecter')));
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('إدارة المصاريف / Gestion des frais', style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.blueAccent,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: isSaving
//                 ? const SizedBox(
//               width: 24,
//               height: 24,
//               child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
//             )
//                 : const Icon(Icons.save, color: Colors.white),
//             onPressed: isSaving ? null : _updateFees,
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.blueAccent.shade100, Colors.white],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               if (authState.role == 'admin')
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.9),
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [
//                       BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 5, blurRadius: 7),
//                     ],
//                   ),
//                   child: BlocBuilder<SchoolCubit, SchoolState>(
//                     builder: (context, schoolState) {
//                       if (schoolState is SchoolsLoaded) {
//                         // التأكد من أن selectedSchoolId يتم تعيينه بشكل صحيح
//                         if (selectedSchoolId == null && schoolState.schools.isNotEmpty) {
//                           selectedSchoolId = schoolState.schools.first.schoolId;
//                           print('Selected School ID (admin role): $selectedSchoolId'); // للتتبع
//                           context.read<StudentCubit>().streamStudents(schoolId: selectedSchoolId!);
//                         }
//                         return Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             _buildSectionTitle('اختيار المدرسة / Sélectionner l’école'),
//                             DropdownButtonFormField<String>(
//                               decoration: _buildInputDecoration('المدرسة / École'),
//                               value: selectedSchoolId,
//                               items: schoolState.schools.map((school) {
//                                 return DropdownMenuItem(
//                                   value: school.schoolId,
//                                   child: Text(school.schoolName['ar'] ?? ''),
//                                 );
//                               }).toList(),
//                               onChanged: (value) {
//                                 setState(() {
//                                   selectedSchoolId = value;
//                                   print('Selected School ID (dropdown): $selectedSchoolId'); // للتتبع
//                                   if (value != null) {
//                                     context.read<StudentCubit>().streamStudents(schoolId: value);
//                                   }
//                                 });
//                               },
//                               validator: (value) => value == null ? 'مطلوب' : null,
//                             ),
//                           ],
//                         );
//                       }
//                       return const SizedBox.shrink();
//                     },
//                   ),
//                 ),
//               const SizedBox(height: 24),
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.9),
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 5, blurRadius: 7),
//                   ],
//                 ),
//                 child: BlocBuilder<StudentCubit, StudentState>(
//                   builder: (context, state) {
//                     if (state is StudentLoading) {
//                       return const Center(child: CircularProgressIndicator());
//                     } else if (state is StudentsLoaded) {
//                       final students = state.students;
//                       if (students.isEmpty) {
//                         return const Center(child: Text('لا يوجد طلاب / Aucun étudiant'));
//                       }
//                       return Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           _buildSectionTitle('قائمة الطلاب / Liste des étudiants'),
//                           ListView.builder(
//                             shrinkWrap: true,
//                             physics: const NeverScrollableScrollPhysics(),
//                             itemCount: students.length,
//                             itemBuilder: (context, index) {
//                               final student = students[index];
//                               feesDueUpdates[student.id] ??= student.feesDue ?? 0.0;
//                               feesPaidUpdates[student.id] ??= student.feesPaid ?? 0.0;
//                               feesDueControllers[student.id] ??= TextEditingController(
//                                   text: feesDueUpdates[student.id]?.toString() ?? '0.0');
//                               feesPaidControllers[student.id] ??= TextEditingController(
//                                   text: feesPaidUpdates[student.id]?.toString() ?? '0.0');
//                               final remainingFees =
//                                   feesDueUpdates[student.id]! - feesPaidUpdates[student.id]!;
//                               final isFullyPaid = remainingFees <= 0;
//
//                               return Card(
//                                 elevation: 4,
//                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//                                 margin: const EdgeInsets.symmetric(vertical: 8),
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(16),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         children: [
//                                           CircleAvatar(
//                                             radius: 30,
//                                             backgroundColor: Colors.blueAccent.shade100,
//                                             child: student.profileImage != null
//                                                 ? ClipOval(
//                                                 child: Image.network(student.profileImage!,
//                                                     width: 60, height: 60, fit: BoxFit.cover))
//                                                 : const Icon(Icons.person,
//                                                 size: 30, color: Colors.blueAccent),
//                                           ),
//                                           const SizedBox(width: 16),
//                                           Expanded(
//                                             child: Column(
//                                               crossAxisAlignment: CrossAxisAlignment.start,
//                                               children: [
//                                                 Text('${student.firstNameAr} ${student.lastNameAr}',
//                                                     style: const TextStyle(
//                                                         fontSize: 18,
//                                                         fontWeight: FontWeight.bold,
//                                                         color: Colors.blueAccent)),
//                                                 Text('ID: ${student.id}',
//                                                     style: TextStyle(color: Colors.grey.shade700)),
//                                                 Text(
//                                                     'السنة الدراسية: ${student.academicYear} / Année: ${student.academicYear}',
//                                                     style: const TextStyle(color: Colors.black87)),
//                                               ],
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 12),
//                                       Row(
//                                         children: [
//                                           Expanded(
//                                             child: TextFormField(
//                                               decoration:
//                                               _buildInputDecoration('المصاريف المستحقة / Frais dus'),
//                                               keyboardType: TextInputType.number,
//                                               controller: feesDueControllers[student.id],
//                                               onChanged: (value) {
//                                                 setState(() {
//                                                   feesDueUpdates[student.id] =
//                                                       double.tryParse(value) ?? 0.0;
//                                                 });
//                                               },
//                                             ),
//                                           ),
//                                           const SizedBox(width: 12),
//                                           Expanded(
//                                             child: TextFormField(
//                                               decoration:
//                                               _buildInputDecoration('المصاريف المدفوعة / Frais payés'),
//                                               keyboardType: TextInputType.number,
//                                               controller: feesPaidControllers[student.id],
//                                               onChanged: (value) {
//                                                 setState(() {
//                                                   feesPaidUpdates[student.id] =
//                                                       double.tryParse(value) ?? 0.0;
//                                                 });
//                                               },
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 12),
//                                       Text('المتبقي: $remainingFees / Restant: $remainingFees',
//                                           style: const TextStyle(
//                                               fontWeight: FontWeight.bold, color: Colors.black87)),
//                                       if (isFullyPaid)
//                                         const Text('مدفوع بالكامل / Payé en totalité',
//                                             style: TextStyle(
//                                                 color: Colors.green, fontWeight: FontWeight.bold)),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ],
//                       );
//                     } else if (state is StudentError) {
//                       return Center(child: Text(state.message));
//                     }
//                     return const Center(child: Text('اختر مدرسة / Choisissez une école'));
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   InputDecoration _buildInputDecoration(String label) {
//     return InputDecoration(
//       labelText: label,
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//       filled: true,
//       fillColor: Colors.white,
//       contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
//     );
//   }
//
//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Text(
//         title,
//         style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     feesDueControllers.forEach((_, controller) => controller.dispose());
//     feesPaidControllers.forEach((_, controller) => controller.dispose());
//     super.dispose();
//   }
// }