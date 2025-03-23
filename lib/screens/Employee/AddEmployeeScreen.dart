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
import 'package:school_management_dashboard/cubit/school_info/school_info_cubit.dart';
import 'package:school_management_dashboard/cubit/school_info/school_info_state.dart';
import 'package:school_management_dashboard/firebase_services/employee_firebase_services.dart';
import 'package:school_management_dashboard/firebase_services/school_info_firebase_services.dart';
import 'package:school_management_dashboard/models/employee_model.dart';
import '../../cubit/auth/auth_state.dart';
import '../../cubit/salary/salary_state.dart';
import '../../firebase_services/SalaryFirebaseServices.dart';
import 'EmployeeListWithFilterScreen.dart';

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
  String? _selectedSalaryCategoryAr;
  String? _selectedSalaryCategoryFr;
  List<String> _selectedPermissions = [];

  final Map<String, String> _genders = {
    'ذكر': 'Masculin',
    'أنثى': 'Féminin',
  };

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
    'ParentListScreen': 'قائمة أولياء الأمور / Liste des parents', // إضافة شاشة قائمة أولياء الأمور
    'AddParentScreen': 'إضافة ولي أمر / Ajouter un parent', // افترضت وجود شاشة إضافة ولي أمر
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

        String employeeRole = _selectedDepartmentAr == 'المحاسبة' ? 'finance' : 'teacher';

        if (_selectedPermissions.isEmpty) {
          _selectedPermissions = EmployeeFirebaseServices.defaultPermissions[employeeRole] ?? [];
        }

        final employee = Employee(
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

        await FirebaseFirestore.instance.collection('users').doc(employee.id).set({
          'email': employee.email,
          'role': 'employee',
          'schoolId': _selectedSchoolId,
          'permissions': _selectedPermissions,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة الموظف بنجاح')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmployeeListWithFilterScreen(schoolId: _selectedSchoolId),
          ),
        );
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
                child: Column(
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
                      BlocBuilder<SchoolCubit, SchoolState>(
                        builder: (context, schoolState) {
                          if (schoolState is SchoolsLoaded) {
                            return DropdownButtonFormField<String>(
                              decoration: _buildInputDecoration('المدرسة / École'),
                              value: _selectedSchoolId,
                              items: schoolState.schools.map((school) {
                                return DropdownMenuItem(
                                  value: school.schoolId,
                                  child: Text('${school.schoolName['ar'] ?? 'غير متوفر'} / ${school.schoolName['fr'] ?? 'Non disponible'}'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSchoolId = value;
                                  if (value != null) {
                                    context.read<SalaryCubit>().fetchSalaryCategories(value);
                                  }
                                });
                              },
                              validator: (value) => value == null ? 'مطلوب' : null,
                            );
                          }
                          return const SizedBox();
                        },
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
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 5,
                            blurRadius: 7,
                          ),
                        ],
                      ),
                      child: BlocBuilder<SchoolCubit, SchoolState>(
                        builder: (context, schoolState) {
                          return BlocBuilder<SalaryCubit, SalaryState>(
                            builder: (context, salaryState) {
                              if (schoolState is SchoolsLoaded && salaryState is SalaryCategoriesLoaded && _selectedSchoolId != null) {
                                final school = schoolState.schools.firstWhere(
                                      (s) => s.schoolId == _selectedSchoolId,
                                  orElse: () => schoolState.schools.first,
                                );
                                final mainSectionsAr = (school.mainSections['ar'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];
                                final subSectionsAr = (school.subSections['ar'] as Map<String, dynamic>?)?.map(
                                      (key, value) => MapEntry(key, (value as List<dynamic>).map((e) => e as String).toList()),
                                ) ?? {};

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
                                      items: mainSectionsAr.map((dept) => DropdownMenuItem(value: dept, child: Text(dept))).toList(),
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
                                        items: subSectionsAr[_selectedDepartmentAr]!.map((subDept) => DropdownMenuItem(value: subDept, child: Text(subDept))).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedSubDepartmentAr = value;
                                            final index = subSectionsAr[_selectedDepartmentAr]!.indexOf(value!);
                                            _selectedSubDepartmentFr = (school.subSections['fr'] as Map<String, dynamic>?)?[_selectedDepartmentFr]?[index] as String?;
                                          });
                                        },
                                        validator: (value) => value == null ? 'مطلوب' : null,
                                      ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      decoration: _buildInputDecoration('فئة الراتب'),
                                      value: _selectedSalaryCategoryAr,
                                      items: salaryState.categories.map((category) {
                                        return DropdownMenuItem(
                                          value: category.categoryName,
                                          child: Text(category.categoryName),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedSalaryCategoryAr = value;
                                          final selectedCategory = salaryState.categories.firstWhere((cat) => cat.categoryName == value);
                                          _selectedSalaryCategoryFr = selectedCategory.categoryNameFr;
                                          _selectedSalaryCategoryId = selectedCategory.id;
                                        });
                                      },
                                      validator: (value) => value == null ? 'مطلوب' : null,
                                    ),
                                  ],
                                );
                              }
                              return const SizedBox();
                            },
                          );
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
                        builder: (context, schoolState) {
                          return BlocBuilder<SalaryCubit, SalaryState>(
                            builder: (context, salaryState) {
                              if (schoolState is SchoolsLoaded && salaryState is SalaryCategoriesLoaded && _selectedSchoolId != null) {
                                final school = schoolState.schools.firstWhere(
                                      (s) => s.schoolId == _selectedSchoolId,
                                  orElse: () => schoolState.schools.first,
                                );
                                final mainSectionsFr = (school.mainSections['fr'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];
                                final subSectionsFr = (school.subSections['fr'] as Map<String, dynamic>?)?.map(
                                      (key, value) => MapEntry(key, (value as List<dynamic>).map((e) => e as String).toList()),
                                ) ?? {};

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
                                      items: mainSectionsFr.map((dept) => DropdownMenuItem(value: dept, child: Text(dept))).toList(),
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
                                        items: subSectionsFr[_selectedDepartmentFr]!.map((subDept) => DropdownMenuItem(value: subDept, child: Text(subDept))).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedSubDepartmentFr = value;
                                            final index = subSectionsFr[_selectedDepartmentFr]!.indexOf(value!);
                                            _selectedSubDepartmentAr = (school.subSections['ar'] as Map<String, dynamic>?)?[_selectedDepartmentAr]?[index] as String?;
                                          });
                                        },
                                        validator: (value) => value == null ? 'Requis' : null,
                                      ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      decoration: _buildInputDecoration('Catégorie de salaire'),
                                      value: _selectedSalaryCategoryFr,
                                      items: salaryState.categories.map((category) {
                                        return DropdownMenuItem(
                                          value: category.categoryNameFr,
                                          child: Text(category.categoryNameFr),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedSalaryCategoryFr = value;
                                          final selectedCategory = salaryState.categories.firstWhere((cat) => cat.categoryNameFr == value);
                                          _selectedSalaryCategoryAr = selectedCategory.categoryName;
                                          _selectedSalaryCategoryId = selectedCategory.id;
                                        });
                                      },
                                      validator: (value) => value == null ? 'Requis' : null,
                                    ),
                                  ],
                                );
                              }
                              return const SizedBox();
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildModernPermissionsSelector(),
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textDirection: textDirection,
      decoration: _buildInputDecoration(label),
      validator: validator ?? (isRequired ? (value) => value!.isEmpty ? 'مطلوب' : null : null),
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

  Widget _buildModernPermissionsSelector() {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الصلاحيات / Permissions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedPermissions.length == availablePermissions.length) {
                      _selectedPermissions.clear();
                    } else {
                      _selectedPermissions = availablePermissions.keys.toList();
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _selectedPermissions.length == availablePermissions.length ? 'Annuler tout - إلغاء الكل' : 'تحديد الكل - Tout sélectionner',
                    style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: availablePermissions.entries.map((entry) {
              final isSelected = _selectedPermissions.contains(entry.key);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedPermissions.remove(entry.key);
                    } else {
                      _selectedPermissions.add(entry.key);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSelected
                          ? [Colors.blueAccent.shade100, Colors.blueAccent.shade400]
                          : [Colors.grey.shade100, Colors.grey.shade200],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.white : Colors.transparent,
                          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.grey.shade400, width: 2),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 12, color: Colors.blueAccent)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
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