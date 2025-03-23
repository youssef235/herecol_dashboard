import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../cubit/auth/auth_cubit.dart';
import '../../cubit/auth/auth_state.dart';
import '../../cubit/school_info/school_info_cubit.dart';
import '../../cubit/school_info/school_info_state.dart';
import '../../cubit/student/student_cubit.dart';
import '../../cubit/student/student_state.dart';
import '../../models/school_info_model.dart';
import '../../models/student_model.dart';
import '../../models/fee_structure_model.dart';
import 'student_list_screen.dart'; // تأكد من استيراد StudentListScreen

class AddStudentScreen extends StatefulWidget {
  final String role;
  final String uid;

  const AddStudentScreen({required this.role, required this.uid});

  @override
  _AddStudentScreenState createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Arabic controllers
  final _firstNameArController = TextEditingController();
  final _lastNameArController = TextEditingController();
  final _birthPlaceArController = TextEditingController();
  final _addressArController = TextEditingController();

  // French controllers
  final _firstNameFrController = TextEditingController();
  final _lastNameFrController = TextEditingController();
  final _birthPlaceFrController = TextEditingController();
  final _addressFrController = TextEditingController();

  // Common controllers
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _ministryFileNumberController = TextEditingController();

  String? _profileImageUrl;
  String? _schoolId;
  String? _selectedGradeAr;
  String? _selectedGradeFr;
  String? _selectedSectionAr;
  String? _selectedSectionFr;
  String? _selectedGenderAr;
  String? _selectedGenderFr;
  String? _selectedAcademicYear;
  String? _selectedCategoryAr;
  String? _selectedCategoryFr;
  String? _selectedFeeStructureId;

  final List<String> _academicYears = [
    '2023-2024',
    '2024-2025',
    '2025-2026',
    '2026-2027',
    '2027-2028',
    '2028-2029',
    '2029-2030',
  ];

  final Map<String, String> _genders = {
    'ذكر': 'Masculin',
    'أنثى': 'Féminin',
  };

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
      } else if (widget.role == 'employee') {
        _schoolId = authState.schoolId;
        if (_schoolId != null) {
          context.read<SchoolCubit>().fetchSchools(_schoolId!, 'school');
        }
      }
      context.read<StudentCubit>().fetchFeeStructures(_schoolId ?? widget.uid);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final File file = File(image.path);
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef =
      FirebaseStorage.instance.ref().child('student_profiles/$fileName');
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

  Future<void> _saveStudent() async {
    if (_formKey.currentState!.validate()) {
      if (widget.role == 'admin' && _schoolId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار مدرسة')),
        );
        return;
      }
      if (_selectedGradeAr == null ||
          _selectedSectionAr == null ||
          _selectedAcademicYear == null ||
          _selectedFeeStructureId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار الصف والشعبة والعام الدراسي وهيكل المصاريف')),
        );
        return;
      }

      double totalFeesDue = 0.0;
      final feeState = context.read<StudentCubit>().state;
      if (feeState is FeeStructuresLoaded) {
        final selectedFeeStructure = feeState.feeStructures
            .firstWhere((fs) => fs.id == _selectedFeeStructureId);
        totalFeesDue =
            selectedFeeStructure.installments.fold(0.0, (sum, i) => sum + i.amount);
      }

      final student = Student(
        id: '',
        firstNameAr: _firstNameArController.text,
        firstNameFr: _firstNameFrController.text,
        lastNameAr: _lastNameArController.text,
        lastNameFr: _lastNameFrController.text,
        gradeAr: _selectedGradeAr!,
        gradeFr: _selectedGradeFr!,
        sectionAr: _selectedSectionAr!,
        sectionFr: _selectedSectionFr!,
        categoryAr: _selectedCategoryAr,
        categoryFr: _selectedCategoryFr,
        birthDate: _birthDateController.text,
        phone: _phoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        addressAr: _addressArController.text,
        addressFr: _addressFrController.text,
        academicYear: _selectedAcademicYear!,
        schoolId: widget.role == 'admin' ? _schoolId! : widget.uid,
        admissionDate: DateTime.now().toString(),
        birthPlaceAr: _birthPlaceArController.text,
        birthPlaceFr: _birthPlaceFrController.text,
        profileImage: _profileImageUrl,
        totalFeesDue: totalFeesDue, // استبدال feesDue بـ totalFeesDue
        feesPaid: 0.0,
        ministryFileNumber: _ministryFileNumberController.text,
        genderAr: _selectedGenderAr,
        genderFr: _selectedGenderFr,
      );

      context.read<StudentCubit>().addStudent(
        firstNameAr: student.firstNameAr,
        firstNameFr: student.firstNameFr,
        lastNameAr: student.lastNameAr,
        lastNameFr: student.lastNameFr,
        gradeAr: student.gradeAr,
        gradeFr: student.gradeFr,
        sectionAr: student.sectionAr,
        sectionFr: student.sectionFr,
        categoryAr: student.categoryAr,
        categoryFr: student.categoryFr,
        birthDate: student.birthDate,
        phone: student.phone,
        email: student.email,
        addressAr: student.addressAr,
        addressFr: student.addressFr,
        schoolId: student.schoolId,
        birthPlaceAr: student.birthPlaceAr,
        birthPlaceFr: student.birthPlaceFr,
        role: widget.role,
        uid: widget.uid,
        totalFeesDue: student.totalFeesDue ?? 0.0, // استبدال feesDue بـ totalFeesDue
        feesPaid: student.feesPaid ?? 0.0,
        academicYear: student.academicYear,
        ministryFileNumber: student.ministryFileNumber ?? '',
        genderAr: student.genderAr,
        genderFr: student.genderFr,
        profileImage: student.profileImage,
      );

      // الانتقال إلى شاشة قائمة الطلاب بعد الإضافة
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StudentListScreen(schoolId: student.schoolId),
        ),
      );
    }
  }
  // دالة جديدة لعرض الصف بالعربية والفرنسية معًا
  Widget _buildGradeDropdown(Schoolinfo school) {
    final classesAr = school.classes['ar'] ?? [];
    final classesFr = school.classes['fr'] ?? [];
    return DropdownButtonFormField<String>(
      decoration: _buildInputDecoration('الصف / Classe'),
      value: _selectedGradeAr,
      items: classesAr.map((gradeAr) {
        final index = classesAr.indexOf(gradeAr);
        final gradeFr = classesFr[index];
        return DropdownMenuItem(
          value: gradeAr,
          child: Text('$gradeAr / $gradeFr'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedGradeAr = value;
          final index = classesAr.indexOf(value!);
          _selectedGradeFr = classesFr[index];
          _selectedSectionAr = null;
          _selectedSectionFr = null;
        });
      },
      validator: (value) => value == null ? 'مطلوب' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة طالب جديد / Ajouter un nouvel étudiant',
            style: TextStyle(color: Colors.white)),
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
        child: BlocListener<StudentCubit, StudentState>(
          listener: (context, state) {
            if (state is StudentAdded) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إضافة الطالب بنجاح')),
              );
            } else if (state is StudentError) {
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
                        BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 5,
                            blurRadius: 7),
                      ],
                    ),
                    child: BlocBuilder<SchoolCubit, SchoolState>(
                      builder: (context, schoolState) {
                        if (schoolState is SchoolsLoaded) {
                          final school = schoolState.schools.firstWhere(
                                (s) => s.schoolId ==
                                (widget.role == 'admin' ? _schoolId : widget.uid),
                            orElse: () => schoolState.schools.isNotEmpty
                                ? schoolState.schools.first
                                : Schoolinfo(
                              schoolId: '',
                              schoolName: {
                                'ar': 'مدرسة غير محددة',
                                'fr': 'École non spécifiée'
                              },
                              city: {'ar': '', 'fr': ''},
                              email: '',
                              phone: '',
                              currency: {'ar': '', 'fr': ''},
                              currencySymbol: {'ar': '', 'fr': ''},
                              address: {'ar': '', 'fr': ''},
                              classes: {'ar': [], 'fr': []},
                              sections: {'ar': {}, 'fr': {}},
                              categories: {'ar': [], 'fr': []},
                              mainSections: {'ar': [], 'fr': []},
                              subSections: {'ar': {}, 'fr': {}},
                              logoUrl: null,
                              principalName: {'ar': '', 'fr': ''},
                              principalSignatureUrl: null,
                              ownerId: null,
                            ),
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: _buildImagePicker(
                                  label: 'صورة الطالب / Photo de l’étudiant',
                                  imageUrl: _profileImageUrl,
                                  onTap: _pickImage,
                                  size: 200,
                                ),
                              ),
                              _buildSectionTitle(
                                  'معلومات مشتركة / Informations communes'),
                              if (widget.role == 'admin') ...[
                                DropdownButtonFormField<String>(
                                  decoration:
                                  _buildInputDecoration('المدرسة / École'),
                                  value: _schoolId,
                                  items: schoolState.schools.map((school) {
                                    return DropdownMenuItem(
                                      value: school.schoolId,
                                      child: Text(
                                        '${school.schoolName['ar'] ?? 'غير متوفر'} / ${school.schoolName['fr'] ?? 'Non disponible'}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _schoolId = value;
                                      _selectedGradeAr = null;
                                      _selectedGradeFr = null;
                                      _selectedSectionAr = null;
                                      _selectedSectionFr = null;
                                      context
                                          .read<StudentCubit>()
                                          .fetchFeeStructures(
                                          _schoolId ?? widget.uid);
                                    });
                                  },
                                  validator: (value) =>
                                  value == null ? 'مطلوب' : null,
                                ),
                                const SizedBox(height: 12),
                              ],
                              _buildTextField(
                                  label: 'رقم الهاتف / Numéro de téléphone',
                                  controller: _phoneController,
                                  isRequired: false),
                              const SizedBox(height: 12),
                              _buildTextField(
                                  label: 'البريد الإلكتروني / E-mail',
                                  controller: _emailController,
                                  isRequired: false),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _birthDateController,
                                readOnly: true,
                                decoration: _buildInputDecoration(
                                    'تاريخ الميلاد / Date de naissance')
                                    .copyWith(
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
                                      _birthDateController.text =
                                      "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                                    });
                                  }
                                },
                                validator: (value) =>
                                value!.isEmpty ? 'مطلوب' : null,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                decoration: _buildInputDecoration(
                                    'العام الدراسي / Année académique'),
                                value: _selectedAcademicYear,
                                items: _academicYears.map((year) {
                                  return DropdownMenuItem(
                                      value: year, child: Text(year));
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedAcademicYear = value;
                                  });
                                },
                                validator: (value) =>
                                value == null ? 'مطلوب' : null,
                              ),
                              const SizedBox(height: 12),
                              _buildGradeDropdown(school), // حقل الصف المعدل
                              const SizedBox(height: 12),
                              BlocBuilder<StudentCubit, StudentState>(
                                builder: (context, state) {
                                  if (state is FeeStructuresLoaded &&
                                      _selectedGradeAr != null) {
                                    final feeStructures = state.feeStructures
                                        .where((fs) =>
                                    fs.gradeAr == _selectedGradeAr)
                                        .toList();
                                    return DropdownButtonFormField<String>(
                                      decoration: _buildInputDecoration(
                                          'هيكل المصاريف / Structure des frais'),
                                      value: _selectedFeeStructureId,
                                      items: feeStructures.map((fs) {
                                        final totalFees = fs.installments
                                            .fold(0.0, (sum, i) => sum + i.amount);
                                        return DropdownMenuItem(
                                          value: fs.id,
                                          child: Text(
                                              '${fs.gradeAr} - المجموع: $totalFees'),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedFeeStructureId = value;
                                        });
                                      },
                                      validator: (value) =>
                                      value == null ? 'مطلوب' : null,
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                label:
                                'رقم الملف في الوزارة / Numéro de dossier au ministère',
                                controller: _ministryFileNumberController,
                                isRequired: false,
                              ),
                            ],
                          );
                        } else if (schoolState is SchoolError) {
                          return Center(
                              child: Text('خطأ: ${schoolState.message}'));
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
                                  blurRadius: 7),
                            ],
                          ),
                          child: BlocBuilder<SchoolCubit, SchoolState>(
                            builder: (context, schoolState) {
                              if (schoolState is SchoolsLoaded) {
                                final school = schoolState.schools.firstWhere(
                                      (s) => s.schoolId ==
                                      (widget.role == 'admin'
                                          ? _schoolId
                                          : widget.uid),
                                  orElse: () => schoolState.schools.first,
                                );
                                final sectionsFr = school.sections['fr'] ?? {};
                                final categoriesFr =
                                    school.categories['fr'] ?? [];

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionTitle('Informations en français'),
                                    _buildTextField(
                                        label: 'Prénom',
                                        controller: _firstNameFrController),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                        label: 'Nom de famille',
                                        controller: _lastNameFrController),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                        label: 'Lieu de naissance',
                                        controller: _birthPlaceFrController),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                        label: 'Adresse',
                                        controller: _addressFrController),
                                    const SizedBox(height: 12),
                                    if (_selectedGradeFr != null &&
                                        sectionsFr[_selectedGradeFr] != null)
                                      DropdownButtonFormField<String>(
                                        decoration:
                                        _buildInputDecoration('Section'),
                                        value: _selectedSectionFr,
                                        items: sectionsFr[_selectedGradeFr]!
                                            .map((section) {
                                          return DropdownMenuItem(
                                              value: section,
                                              child: Text(section));
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedSectionFr = value;
                                            final index = sectionsFr[
                                            _selectedGradeFr]!
                                                .indexOf(value!);
                                            _selectedSectionAr = school
                                                .sections['ar']![
                                            _selectedGradeAr]![index];
                                          });
                                        },
                                        validator: (value) =>
                                        value == null ? 'Requis' : null,
                                      ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      decoration:
                                      _buildInputDecoration('Catégorie'),
                                      value: _selectedCategoryFr,
                                      items: categoriesFr.map((category) {
                                        return DropdownMenuItem(
                                            value: category,
                                            child: Text(category));
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedCategoryFr = value;
                                          final index =
                                          categoriesFr.indexOf(value!);
                                          _selectedCategoryAr =
                                          school.categories['ar']![index];
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      decoration:
                                      _buildInputDecoration('Genre'),
                                      value: _selectedGenderFr,
                                      items: _genders.values.map((gender) {
                                        return DropdownMenuItem(
                                            value: gender, child: Text(gender));
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedGenderFr = value;
                                          _selectedGenderAr = _genders.keys
                                              .firstWhere(
                                                  (k) => _genders[k] == value);
                                        });
                                      },
                                      validator: (value) =>
                                      value == null ? 'Requis' : null,
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
                                  blurRadius: 7),
                            ],
                          ),
                          child: BlocBuilder<SchoolCubit, SchoolState>(
                            builder: (context, schoolState) {
                              if (schoolState is SchoolsLoaded) {
                                final school = schoolState.schools.firstWhere(
                                      (s) => s.schoolId ==
                                      (widget.role == 'admin'
                                          ? _schoolId
                                          : widget.uid),
                                  orElse: () => schoolState.schools.first,
                                );
                                final sectionsAr = school.sections['ar'] ?? {};
                                final categoriesAr =
                                    school.categories['ar'] ?? [];

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionTitle('معلومات بالعربية'),
                                    _buildTextField(
                                        label: 'الاسم الأول',
                                        controller: _firstNameArController,
                                        textDirection: TextDirection.rtl),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                        label: 'اسم العائلة',
                                        controller: _lastNameArController,
                                        textDirection: TextDirection.rtl),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                        label: 'مكان الميلاد',
                                        controller: _birthPlaceArController,
                                        textDirection: TextDirection.rtl),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                        label: 'العنوان',
                                        controller: _addressArController,
                                        textDirection: TextDirection.rtl),
                                    const SizedBox(height: 12),
                                    if (_selectedGradeAr != null &&
                                        sectionsAr[_selectedGradeAr] != null)
                                      DropdownButtonFormField<String>(
                                        decoration:
                                        _buildInputDecoration('الشعبة'),
                                        value: _selectedSectionAr,
                                        items: sectionsAr[_selectedGradeAr]!
                                            .map((section) {
                                          return DropdownMenuItem(
                                              value: section,
                                              child: Text(section));
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedSectionAr = value;
                                            final index = sectionsAr[
                                            _selectedGradeAr]!
                                                .indexOf(value!);
                                            _selectedSectionFr = school
                                                .sections['fr']![
                                            _selectedGradeFr]![index];
                                          });
                                        },
                                        validator: (value) =>
                                        value == null ? 'مطلوب' : null,
                                      ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      decoration:
                                      _buildInputDecoration('الفئة'),
                                      value: _selectedCategoryAr,
                                      items: categoriesAr.map((category) {
                                        return DropdownMenuItem(
                                            value: category,
                                            child: Text(category));
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedCategoryAr = value;
                                          final index =
                                          categoriesAr.indexOf(value!);
                                          _selectedCategoryFr =
                                          school.categories['fr']![index];
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      decoration:
                                      _buildInputDecoration('الجنس'),
                                      value: _selectedGenderAr,
                                      items: _genders.keys.map((gender) {
                                        return DropdownMenuItem(
                                            value: gender, child: Text(gender));
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedGenderAr = value;
                                          _selectedGenderFr = _genders[value];
                                        });
                                      },
                                      validator: (value) =>
                                      value == null ? 'مطلوب' : null,
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
                      onPressed: _saveStudent,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        elevation: 5,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('حفظ / Enregistrer',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
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
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    TextEditingController? controller,
    bool obscureText = false,
    TextDirection textDirection = TextDirection.ltr,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
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

  Widget _buildImagePicker({
    required String label,
    String? imageUrl,
    required VoidCallback onTap,
    double size = 200,
  }) {
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
                ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(imageUrl, fit: BoxFit.cover))
                : const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _firstNameArController.dispose();
    _lastNameArController.dispose();
    _birthPlaceArController.dispose();
    _addressArController.dispose();
    _firstNameFrController.dispose();
    _lastNameFrController.dispose();
    _birthPlaceFrController.dispose();
    _addressFrController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _ministryFileNumberController.dispose();
    super.dispose();
  }
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
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    TextEditingController? controller,
    bool obscureText = false,
    TextDirection textDirection = TextDirection.ltr,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
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

  Widget _buildImagePicker({
    required String label,
    String? imageUrl,
    required VoidCallback onTap,
    double size = 200,
  }) {
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
                ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(imageUrl, fit: BoxFit.cover))
                : const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
          ),
        ),
      ],
    );
  }

 