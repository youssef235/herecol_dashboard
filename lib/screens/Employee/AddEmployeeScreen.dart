import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:school_management_dashboard/cubit/Employee/EmployeeCubit.dart';
import 'package:school_management_dashboard/cubit/auth/auth_cubit.dart';
import 'package:school_management_dashboard/cubit/salary/salary_cubit.dart';
import 'package:school_management_dashboard/cubit/salary/salary_state.dart';
import 'package:school_management_dashboard/cubit/school_info/school_info_cubit.dart';
import 'package:school_management_dashboard/cubit/school_info/school_info_state.dart';
import 'package:school_management_dashboard/firebase_services/employee_firebase_services.dart';
import 'package:school_management_dashboard/firebase_services/school_info_firebase_services.dart';
import 'package:school_management_dashboard/models/employee_model.dart';
import '../../cubit/auth/auth_state.dart';
import '../../firebase_services/SalaryFirebaseServices.dart';

class AddEmployeeScreen extends StatelessWidget {
  final String? schoolId;

  const AddEmployeeScreen({Key? key, this.schoolId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إضافة موظف جديد / Ajouter un nouvel employé',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => EmployeeCubit(EmployeeFirebaseServices()),
          ),
          BlocProvider(
            create: (context) => SchoolCubit(SchoolFirebaseServices()),
          ),
          BlocProvider(
            create: (context) => SalaryCubit(SalaryFirebaseServices()),
          ),
        ],
        child: AddEmployeeForm(schoolId: schoolId),
      ),
    );
  }
}

class AddEmployeeForm extends StatefulWidget {
  final String? schoolId;

  const AddEmployeeForm({Key? key, required this.schoolId}) : super(key: key);

  @override
  _AddEmployeeFormState createState() => _AddEmployeeFormState();
}

class _AddEmployeeFormState extends State<AddEmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Controllers
  final _fullNameArController = TextEditingController();
  final _addressArController = TextEditingController();
  final _fullNameFrController = TextEditingController();
  final _addressFrController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _secondaryPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _profileImageUrl;
  String? _selectedSchoolId;
  String? _selectedDepartmentAr;
  String? _selectedSubDepartmentAr;
  String? _selectedDepartmentFr;
  String? _selectedSubDepartmentFr;
  String? _selectedGenderAr;
  String? _selectedGenderFr;
  String? _selectedSalaryCategoryId;
  List<String> _selectedPermissions = [];

  final Map<String, String> _genders = {
    'ذكر': 'Masculin',
    'أنثى': 'Féminin',
  };

  // قائمة الصلاحيات تتطابق مع CustomDrawer
  static const Map<String, String> availablePermissions = {
    'StatsScreen': 'الإحصائيات / Statistiques',
    'SchoolInfoScreen': 'معلومات المدرسة / Informations sur l’école',
    'AddSchoolScreen': 'إضافة مدرسة / Ajouter une école',
    'AddStudentScreen': 'إضافة طالب / Ajouter un étudiant',
    'StudentListScreen': 'قائمة الطلاب / Liste des étudiants',
    'AttendanceManagementScreen': 'إدارة الحضور والغياب / Gestion des présences',
    'FeesManagementScreen': 'إدارة المصاريف / Gestion des frais',
    'LatePaymentsScreen': 'الطلاب المتأخرون عن الدفع / Étudiants en retard',
    'AccountingManagementScreen': 'إدارة المحاسبة / Gestion de la comptabilité',
    'EmployeeListWithFilterScreen': 'قائمة الموظفين / Liste des employés',
    'AddEmployeeScreen': 'إضافة موظف / Ajouter un employé',
    'SalaryCategoriesScreen': 'فئات الرواتب / Catégories de salaires',
    'SalaryTrackingScreen': 'تتبع دفع الرواتب / Suivi des paiements de salaire',
  };

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      if (authState.role == 'admin') {
        context.read<SchoolCubit>().fetchSchools(authState.uid, 'admin');
      } else if (authState.role == 'school' && widget.schoolId != null) {
        _selectedSchoolId = widget.schoolId;
        context.read<SchoolCubit>().fetchSchools(widget.schoolId!, 'school');
        context.read<SalaryCubit>().fetchSalaryCategories(widget.schoolId!);
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final File file = File(image.path);
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance.ref().child('employee_profiles/$fileName');
      try {
        await storageRef.putFile(file);
        final String downloadURL = await storageRef.getDownloadURL();
        setState(() {
          _profileImageUrl = downloadURL;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفع الصورة بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في رفع الصورة: $e')),
        );
      }
    }
  }

  Future<void> _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSchoolId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار المدرسة')),
        );
        return;
      }
      if (_selectedDepartmentAr == null || _selectedSubDepartmentAr == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار القسم الرئيسي والفرعي')),
        );
        return;
      }
      if (_selectedSalaryCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار فئة الراتب')),
        );
        return;
      }

      try {
        UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // تعيين الـ role بناءً على القسم الرئيسي
        String employeeRole = _selectedDepartmentAr == 'المحاسبة' ? 'finance' : 'teacher';

        // إذا لم يتم اختيار صلاحيات يدويًا، استخدم القيم الافتراضية بناءً على الـ role
        if (_selectedPermissions.isEmpty) {
          _selectedPermissions = EmployeeFirebaseServices.defaultPermissions[employeeRole] ?? [];
        }

        final employee = Employee(
          id: userCredential.user!.uid,
          fullNameAr: _fullNameArController.text,
          fullNameFr: _fullNameFrController.text,
          genderAr: _selectedGenderAr!,
          genderFr: _selectedGenderFr!,
          birthDate: _birthDateController.text,
          phone: _phoneController.text,
          secondaryPhone: _secondaryPhoneController.text.isEmpty ? null : _secondaryPhoneController.text,
          email: _emailController.text,
          addressAr: _addressArController.text,
          addressFr: _addressFrController.text,
          profileImage: _profileImageUrl,
          departmentAr: _selectedDepartmentAr!,
          subDepartmentAr: _selectedSubDepartmentAr!,
          departmentFr: _selectedDepartmentFr!,
          subDepartmentFr: _selectedSubDepartmentFr!,
          role: employeeRole,
          permissions: _selectedPermissions,
          salaryCategoryId: _selectedSalaryCategoryId,
          schoolId: _selectedSchoolId!,
        );

        context.read<EmployeeCubit>().addEmployee(employee, _selectedSchoolId!);

        // حفظ بيانات المستخدم في مجموعة 'users' مع الـ role و schoolId والصلاحيات
        await FirebaseFirestore.instance.collection('users').doc(employee.id).set({
          'email': employee.email,
          'role': 'employee',
          'schoolId': _selectedSchoolId,
          'permissions': _selectedPermissions,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة الموظف بنجاح')),
        );
        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إنشاء الحساب: ${e.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isSuperAdmin = authState is AuthAuthenticated && authState.role == 'admin';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent.shade100, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
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
                      if (schoolState.schools.isEmpty) {
                        return const Center(child: Text('لا توجد مدارس متاحة حاليًا'));
                      }

                      final uniqueSchools = schoolState.schools.toSet().toList();

                      if (_selectedSchoolId != null && !uniqueSchools.any((school) => school.schoolId == _selectedSchoolId)) {
                        _selectedSchoolId = null;
                      }

                      if (isSuperAdmin && _selectedSchoolId == null && uniqueSchools.isNotEmpty) {
                        _selectedSchoolId = uniqueSchools.first.schoolId;
                        context.read<SalaryCubit>().fetchSalaryCategories(_selectedSchoolId!);
                      }

                      final school = uniqueSchools.firstWhere(
                            (s) => s.schoolId == _selectedSchoolId,
                        orElse: () => uniqueSchools.first,
                      );

                      final mainSectionsAr = (school.mainSections['ar'] as List<dynamic>?)
                          ?.map((e) => e as String)
                          .toList() ??
                          [];
                      final subSectionsAr = (school.subSections['ar'] as Map<String, dynamic>?)
                          ?.map((key, value) => MapEntry(key, (value as List<dynamic>).map((e) => e as String).toList())) ??
                          {};
                      final mainSectionsFr = (school.mainSections['fr'] as List<dynamic>?)
                          ?.map((e) => e as String)
                          .toList() ??
                          [];
                      final subSectionsFr = (school.subSections['fr'] as Map<String, dynamic>?)
                          ?.map((key, value) => MapEntry(key, (value as List<dynamic>).map((e) => e as String).toList())) ??
                          {};

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: _buildImagePicker(
                              label: 'صورة الموظف / Photo de l’employé',
                              imageUrl: _profileImageUrl,
                              onTap: _pickImage,
                              size: 200,
                            ),
                          ),
                          _buildSectionTitle('معلومات مشتركة / Informations communes'),
                          if (isSuperAdmin) ...[
                            DropdownButtonFormField<String>(
                              decoration: _buildInputDecoration('المدرسة / École'),
                              value: _selectedSchoolId,
                              items: uniqueSchools.map((school) {
                                return DropdownMenuItem(
                                  value: school.schoolId,
                                  child: Text('${school.schoolName['ar'] ?? 'غير متوفر'} / ${school.schoolName['fr'] ?? 'Non disponible'}'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSchoolId = value;
                                  _selectedDepartmentAr = null;
                                  _selectedSubDepartmentAr = null;
                                  _selectedDepartmentFr = null;
                                  _selectedSubDepartmentFr = null;
                                  if (value != null) {
                                    context.read<SalaryCubit>().fetchSalaryCategories(value);
                                  }
                                });
                              },
                              validator: (value) => value == null ? 'مطلوب' : null,
                            ),
                            const SizedBox(height: 12),
                          ],
                          _buildTextField(
                            label: 'رقم الهاتف / Numéro de téléphone',
                            controller: _phoneController,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            label: 'رقم هاتف احتياطي / Numéro de téléphone secondaire',
                            controller: _secondaryPhoneController,
                            isRequired: false,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            label: 'البريد الإلكتروني / E-mail',
                            controller: _emailController,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            label: 'كلمة المرور / Mot de passe',
                            controller: _passwordController,
                            obscureText: true,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _birthDateController,
                            readOnly: true,
                            decoration: _buildInputDecoration('تاريخ الميلاد / Date de naissance').copyWith(
                              suffixIcon: const Icon(Icons.calendar_today),
                            ),
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  _birthDateController.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                                });
                              }
                            },
                            validator: (value) => value!.isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: 12),
                          _buildSalaryCategoryDropdown(),
                          const SizedBox(height: 12),
                          _buildPermissionsSelector(),
                        ],
                      );
                    } else if (schoolState is SchoolError) {
                      return Center(child: Text('خطأ: ${schoolState.message}'));
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
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
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 5,
                            blurRadius: 7,
                          ),
                        ],
                      ),
                      child: BlocBuilder<SchoolCubit, SchoolState>(
                        builder: (context, state) {
                          if (state is SchoolsLoaded) {
                            final uniqueSchools = state.schools.toSet().toList();
                            final school = uniqueSchools.firstWhere(
                                  (s) => s.schoolId == _selectedSchoolId,
                              orElse: () => uniqueSchools.first,
                            );

                            final mainSectionsAr = (school.mainSections['ar'] as List<dynamic>?)
                                ?.map((e) => e as String)
                                .toList() ??
                                [];
                            final subSectionsAr = (school.subSections['ar'] as Map<String, dynamic>?)
                                ?.map((key, value) => MapEntry(key, (value as List<dynamic>).map((e) => e as String).toList())) ??
                                {};

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('معلومات بالعربية'),
                                _buildTextField(label: 'الاسم الكامل', controller: _fullNameArController, textDirection: TextDirection.rtl),
                                const SizedBox(height: 12),
                                _buildTextField(label: 'العنوان', controller: _addressArController, textDirection: TextDirection.rtl),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  decoration: _buildInputDecoration('الجنس'),
                                  value: _selectedGenderAr,
                                  items: _genders.keys.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGenderAr = value;
                                      _selectedGenderFr = _genders[value];
                                    });
                                  },
                                  validator: (value) => value == null ? 'مطلوب' : null,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  decoration: _buildInputDecoration('القسم الرئيسي'),
                                  value: _selectedDepartmentAr,
                                  items: mainSectionsAr.map((department) => DropdownMenuItem(value: department, child: Text(department))).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedDepartmentAr = value;
                                      _selectedSubDepartmentAr = null;
                                      final index = mainSectionsAr.indexOf(value!);
                                      _selectedDepartmentFr = (school.mainSections['fr'] as List<dynamic>?)?[index] as String? ?? '';
                                    });
                                  },
                                  validator: (value) => value == null ? 'مطلوب' : null,
                                ),
                                const SizedBox(height: 12),
                                if (_selectedDepartmentAr != null && subSectionsAr[_selectedDepartmentAr] != null)
                                  DropdownButtonFormField<String>(
                                    decoration: _buildInputDecoration('القسم الفرعي'),
                                    value: _selectedSubDepartmentAr,
                                    items: subSectionsAr[_selectedDepartmentAr]!.map((subDepartment) => DropdownMenuItem(value: subDepartment, child: Text(subDepartment))).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedSubDepartmentAr = value;
                                        final index = subSectionsAr[_selectedDepartmentAr]!.indexOf(value!);
                                        _selectedSubDepartmentFr = (school.subSections['fr'] as Map<String, dynamic>?)?[_selectedDepartmentFr]?[index] as String?;
                                      });
                                    },
                                    validator: (value) => value == null ? 'مطلوب' : null,
                                  ),
                              ],
                            );
                          }
                          return const SizedBox();
                        },
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
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 5,
                            blurRadius: 7,
                          ),
                        ],
                      ),
                      child: BlocBuilder<SchoolCubit, SchoolState>(
                        builder: (context, state) {
                          if (state is SchoolsLoaded) {
                            final uniqueSchools = state.schools.toSet().toList();
                            final school = uniqueSchools.firstWhere(
                                  (s) => s.schoolId == _selectedSchoolId,
                              orElse: () => uniqueSchools.first,
                            );

                            final mainSectionsFr = (school.mainSections['fr'] as List<dynamic>?)
                                ?.map((e) => e as String)
                                .toList() ??
                                [];
                            final subSectionsFr = (school.subSections['fr'] as Map<String, dynamic>?)
                                ?.map((key, value) => MapEntry(key, (value as List<dynamic>).map((e) => e as String).toList())) ??
                                {};

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Informations en français'),
                                _buildTextField(label: 'Nom complet', controller: _fullNameFrController),
                                const SizedBox(height: 12),
                                _buildTextField(label: 'Adresse', controller: _addressFrController),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  decoration: _buildInputDecoration('Genre'),
                                  value: _selectedGenderFr,
                                  items: _genders.values.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGenderFr = value;
                                      _selectedGenderAr = _genders.keys.firstWhere((k) => _genders[k] == value);
                                    });
                                  },
                                  validator: (value) => value == null ? 'Requis' : null,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  decoration: _buildInputDecoration('Département principal'),
                                  value: _selectedDepartmentFr,
                                  items: mainSectionsFr.map((department) => DropdownMenuItem(value: department, child: Text(department))).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedDepartmentFr = value;
                                      _selectedSubDepartmentFr = null;
                                      final index = mainSectionsFr.indexOf(value!);
                                      _selectedDepartmentAr = (school.mainSections['ar'] as List<dynamic>?)?[index] as String? ?? '';
                                    });
                                  },
                                  validator: (value) => value == null ? 'Requis' : null,
                                ),
                                const SizedBox(height: 12),
                                if (_selectedDepartmentFr != null && subSectionsFr[_selectedDepartmentFr] != null)
                                  DropdownButtonFormField<String>(
                                    decoration: _buildInputDecoration('Sous-département'),
                                    value: _selectedSubDepartmentFr,
                                    items: subSectionsFr[_selectedDepartmentFr]!.map((subDepartment) => DropdownMenuItem(value: subDepartment, child: Text(subDepartment))).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedSubDepartmentFr = value;
                                        final index = subSectionsFr[_selectedDepartmentFr]!.indexOf(value!);
                                        _selectedSubDepartmentAr = (school.subSections['ar'] as Map<String, dynamic>?)?[_selectedDepartmentAr]?[index] as String?;
                                      });
                                    },
                                    validator: (value) => value == null ? 'Requis' : null,
                                  ),
                              ],
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveEmployee,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 5,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'حفظ / Enregistrer',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
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
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    TextEditingController? controller,
    bool obscureText = false,
    TextDirection textDirection = TextDirection.ltr,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textDirection: textDirection,
      decoration: _buildInputDecoration(label),
      validator: isRequired ? (value) => value!.isEmpty ? (textDirection == TextDirection.rtl ? 'مطلوب' : 'Requis') : null : null,
    );
  }

  Widget _buildImagePicker({required String label, String? imageUrl, required VoidCallback onTap, double size = 200}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 20, color: Colors.grey)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blueAccent, width: 2),
            ),
            child: imageUrl != null
                ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(imageUrl, fit: BoxFit.cover))
                : const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الصلاحيات / Permissions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...availablePermissions.entries.map((entry) {
          return CheckboxListTile(
            title: Text(entry.value),
            value: _selectedPermissions.contains(entry.key),
            onChanged: (bool? selected) {
              setState(() {
                if (selected != null) {
                  if (selected) {
                    _selectedPermissions.add(entry.key);
                  } else {
                    _selectedPermissions.remove(entry.key);
                  }
                }
              });
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSalaryCategoryDropdown() {
    return BlocBuilder<SalaryCubit, SalaryState>(
      builder: (context, state) {
        if (state is SalaryCategoriesLoaded) {
          if (state.categories.isEmpty) {
            return const Text('لا توجد فئات رواتب متاحة لهذه المدرسة');
          }
          return DropdownButtonFormField<String>(
            decoration: _buildInputDecoration('فئة الراتب / Catégorie de salaire'),
            value: _selectedSalaryCategoryId,
            items: state.categories.map((category) {
              return DropdownMenuItem(
                value: category.id,
                child: Text(category.categoryName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSalaryCategoryId = value;
              });
            },
            validator: (value) => value == null ? 'مطلوب اختيار فئة راتب' : null,
          );
        } else if (state is SalaryError) {
          return Text('خطأ: ${state.message}');
        }
        return const CircularProgressIndicator();
      },
    );
  }

  @override
  void dispose() {
    _fullNameArController.dispose();
    _addressArController.dispose();
    _fullNameFrController.dispose();
    _addressFrController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _secondaryPhoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}