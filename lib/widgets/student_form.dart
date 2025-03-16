// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:school_management_dashboard/cubit/school_info/school_info_cubit.dart';
// import 'package:school_management_dashboard/cubit/student/student_cubit.dart';
//
// import '../cubit/school_info/school_info_state.dart';
//
// class AddStudentForm extends StatefulWidget {
//   final String role;
//   final String uid;
//
//   const AddStudentForm({required this.role, required this.uid});
//
//   @override
//   _AddStudentFormState createState() => _AddStudentFormState();
// }
//
// class _AddStudentFormState extends State<AddStudentForm> {
//   final _formKey = GlobalKey<FormState>();
//   String? _schoolId;
//   final _firstNameArController = TextEditingController();
//   final _firstNameFrController = TextEditingController();
//   final _lastNameArController = TextEditingController();
//   final _lastNameFrController = TextEditingController();
//   final _gradeController = TextEditingController();
//   final _sectionController = TextEditingController();
//   final _birthDateController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _birthPlaceController = TextEditingController();
//
//   @override
//   void dispose() {
//     _firstNameArController.dispose();
//     _firstNameFrController.dispose();
//     _lastNameArController.dispose();
//     _lastNameFrController.dispose();
//     _gradeController.dispose();
//     _sectionController.dispose();
//     _birthDateController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _birthPlaceController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Form(
//       key: _formKey,
//       child: Column(
//         children: [
//           if (widget.role == 'admin')
//             BlocBuilder<SchoolCubit, SchoolState>(
//               builder: (context, state) {
//                 if (state is SchoolsLoaded) {
//                   return DropdownButtonFormField<String>(
//                     decoration: const InputDecoration(labelText: 'المدرسة'),
//                     items: state.schools.map((school) {
//                       return DropdownMenuItem(
//                         value: school.schoolId,
//                         child: Text(school.schoolName['ar'] ?? ''), // Use Arabic name
//                       );
//                     }).toList(),
//                     onChanged: (value) => _schoolId = value,
//                     validator: (value) => value == null ? 'يرجى اختيار مدرسة' : null,
//                   );
//                 }
//                 return const CircularProgressIndicator();
//               },
//             ),
//           TextFormField(
//             controller: _firstNameArController,
//             decoration: const InputDecoration(labelText: 'الاسم الأول (عربي)'),
//             validator: (value) => value!.isEmpty ? 'يرجى إدخال الاسم' : null,
//           ),
//           // ... (rest of the fields remain the same)
//           const SizedBox(height: 20),
//           ElevatedButton(
//             onPressed: () {
//               if (_formKey.currentState!.validate()) {
//                 context.read<StudentCubit>().addStudent(
//                   firstNameAr: _firstNameArController.text,
//                   firstNameFr: _firstNameFrController.text,
//                   lastNameAr: _lastNameArController.text,
//                   lastNameFr: _lastNameFrController.text,
//                   grade: _gradeController.text,
//                   section: _sectionController.text,
//                   birthDate: _birthDateController.text,
//                   phone: _phoneController.text,
//                   address: _addressController.text,
//                   schoolId: widget.role == 'admin' ? _schoolId! : widget.uid,
//                   birthPlace: _birthPlaceController.text,
//                   role: widget.role,
//                   uid: widget.uid,
//                 );
//               }
//             },
//             child: const Text('إضافة الطالب'),
//           ),
//         ],
//       ),
//     );
//   }
// }