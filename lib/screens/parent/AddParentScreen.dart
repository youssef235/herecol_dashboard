import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/auth/auth_cubit.dart';
import '../../cubit/auth/auth_state.dart';
import '../../cubit/parent/parent_cubit.dart';
import '../../cubit/parent/parent_state.dart';
import '../../cubit/school_info/school_info_cubit.dart';
import '../../cubit/school_info/school_info_state.dart';
import '../../cubit/student/student_cubit.dart';
import '../../cubit/student/student_state.dart';
import '../../models/student_model.dart';

class AddParentScreen extends StatefulWidget {
  final String role;
  final String uid;

  const AddParentScreen({required this.role, required this.uid});

  @override
  _AddParentScreenState createState() => _AddParentScreenState();
}

class _AddParentScreenState extends State<AddParentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameArController = TextEditingController();
  final _nameFrController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressArController = TextEditingController();
  final _addressFrController = TextEditingController();
  List<String> _selectedStudentIds = [];
  String? _schoolId;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      if (widget.role == 'admin') {
        context.read<SchoolCubit>().fetchSchools(widget.uid, widget.role);
        _schoolId = null;
      } else if (widget.role == 'school') {
        _schoolId = widget.uid;
        context.read<SchoolCubit>().fetchSchools(_schoolId!, widget.role);
        context.read<StudentCubit>().fetchStudents(schoolId: _schoolId!);
      } else if (widget.role == 'employee') {
        _schoolId = authState.schoolId;
        if (_schoolId != null) {
          context.read<SchoolCubit>().fetchSchools(_schoolId!, 'school');
          context.read<StudentCubit>().fetchStudents(schoolId: _schoolId!);
        }
      }
    }
  }

  void _saveParent() {
    if (_formKey.currentState!.validate()) {
      if (widget.role == 'admin' && _schoolId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار مدرسة')),
        );
        return;
      }
      if (_selectedStudentIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار طالب واحد على الأقل')),
        );
        return;
      }

      context.read<ParentCubit>().addParent(
        schoolId: widget.role == 'admin' ? _schoolId! : widget.uid,
        nameAr: _nameArController.text,
        nameFr: _nameFrController.text,
        phone: _phoneController.text,
        emergencyPhone: _emergencyPhoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        addressAr: _addressArController.text,
        addressFr: _addressFrController.text.isEmpty ? null : _addressFrController.text,
        studentIds: _selectedStudentIds,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة ولي أمر / Ajouter un parent', style: TextStyle(color: Colors.white)),
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
        child: BlocListener<ParentCubit, ParentState>(
          listener: (context, state) {
            if (state is ParentAdded) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إضافة ولي الأمر بنجاح')),
              );
              Navigator.pop(context);
            } else if (state is ParentError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('خطأ: ${state.message}')),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 5, blurRadius: 7),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('معلومات ولي الأمر / Informations du parent'),
                        if (widget.role == 'admin') ...[
                          BlocBuilder<SchoolCubit, SchoolState>(
                            builder: (context, schoolState) {
                              if (schoolState is SchoolsLoaded) {
                                return DropdownButtonFormField<String>(
                                  decoration: _buildInputDecoration('المدرسة / École'),
                                  value: _schoolId,
                                  items: schoolState.schools.map((school) {
                                    return DropdownMenuItem(
                                      value: school.schoolId,
                                      child: Text('${school.schoolName['ar'] ?? 'غير متوفر'} / ${school.schoolName['fr'] ?? 'Non disponible'}'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _schoolId = value;
                                      if (_schoolId != null) {
                                        context.read<StudentCubit>().fetchStudents(schoolId: _schoolId!);
                                      }
                                    });
                                  },
                                  validator: (value) => value == null ? 'مطلوب' : null,
                                );
                              } else if (schoolState is SchoolError) {
                                return Text('خطأ: ${schoolState.message}');
                              }
                              return const Center(child: CircularProgressIndicator());
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                        _buildTextField(
                          label: 'رقم الهاتف / Numéro de téléphone',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          label: 'رقم هاتف الطوارئ / Numéro d’urgence',
                          controller: _emergencyPhoneController,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          label: 'البريد الإلكتروني / E-mail (اختياري)',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          isRequired: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 5, blurRadius: 7),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('معلومات بالعربية'),
                              _buildTextField(
                                label: 'الاسم / Nom',
                                controller: _nameArController,
                                textDirection: TextDirection.rtl,
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                label: 'العنوان / Adresse',
                                controller: _addressArController,
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 5, blurRadius: 7),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Informations en français'),
                              _buildTextField(
                                label: 'Nom',
                                controller: _nameFrController,
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                label: 'Adresse',
                                controller: _addressFrController,
                                isRequired: false,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 5, blurRadius: 7),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('الطلاب المرتبطون / Étudiants associés'),
                        BlocBuilder<StudentCubit, StudentState>(
                          builder: (context, studentState) {
                            if (widget.role == 'admin' && _schoolId == null) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  'يرجى اختيار مدرسة لعرض قائمة الطلاب',
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              );
                            }
                            if (studentState is StudentLoading) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (studentState is StudentsLoaded) {
                              final students = studentState.students;
                              if (students.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                    'لا يوجد طلاب متاحون في هذه المدرسة',
                                    style: TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                );
                              }
                              return SizedBox(
                                height: 300, // Fixed height for scrollable list
                                child: ListView.builder(
                                  itemCount: students.length,
                                  itemBuilder: (context, index) {
                                    final student = students[index];
                                    final isSelected = _selectedStudentIds.contains(student.id);
                                    return Card(
                                      elevation: 2,
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.blueAccent.withOpacity(0.1),
                                          child: Text(
                                            student.firstNameAr[0],
                                            style: const TextStyle(color: Colors.blueAccent),
                                          ),
                                        ),
                                        title: Text(
                                          '${student.firstNameAr} ${student.lastNameAr} / ${student.firstNameFr} ${student.lastNameFr}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          'الصف: ${student.gradeAr} / ${student.gradeFr}',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                        trailing: Checkbox(
                                          value: isSelected,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              if (value == true) {
                                                _selectedStudentIds.add(student.id);
                                              } else {
                                                _selectedStudentIds.remove(student.id);
                                              }
                                            });
                                          },
                                          activeColor: Colors.blueAccent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                        ),
                                        tileColor: isSelected ? Colors.blueAccent.withOpacity(0.05) : null,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                    );
                                  },
                                ),
                              );
                            } else if (studentState is StudentError) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  'خطأ: ${studentState.message}',
                                  style: const TextStyle(color: Colors.red, fontSize: 16),
                                ),
                              );
                            }
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'جارٍ التحميل...',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveParent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 5,
                      ),
                      child: const Text(
                        'حفظ / Enregistrer',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextDirection textDirection = TextDirection.ltr,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      textDirection: textDirection,
      keyboardType: keyboardType,
      decoration: _buildInputDecoration(label),
      validator: isRequired
          ? (value) => value!.isEmpty
          ? (textDirection == TextDirection.rtl ? 'مطلوب' : 'Requis')
          : null
          : null,
    );
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameFrController.dispose();
    _phoneController.dispose();
    _emergencyPhoneController.dispose();
    _emailController.dispose();
    _addressArController.dispose();
    _addressFrController.dispose();
    super.dispose();
  }
}