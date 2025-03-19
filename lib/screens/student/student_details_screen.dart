import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../../cubit/school_info/school_info_cubit.dart';
import '../../cubit/school_info/school_info_state.dart';
import '../../cubit/student/student_cubit.dart';
import '../../cubit/student/student_state.dart';
import '../../models/school_info_model.dart';
import '../../models/student_model.dart';

class StudentDetailsScreen extends StatefulWidget {
  final String studentId;
  final String schoolId;

  const StudentDetailsScreen({required this.studentId, required this.schoolId});

  @override
  _StudentDetailsScreenState createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
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
  final _feesDueController = TextEditingController();
  final _feesPaidController = TextEditingController();
  final _ministryFileNumberController = TextEditingController();
  final _admissionDateController = TextEditingController();

  String? _profileImageUrl;
  String? _selectedGradeAr;
  String? _selectedSectionAr;
  String? _selectedGenderAr;
  String? _selectedAcademicYear;
  String? _selectedCategoryAr;
  String _selectedLanguage = 'ar'; // Default language is Arabic
  double remainingFees = 0.0;
  bool isFullyPaid = false;

  final List<String> _academicYears = [
    '2023-2024',
    '2024-2025',
    '2025-2026',
  ];

  final Map<String, String> _genders = {
    'ذكر': 'Masculin',
    'أنثى': 'Féminin',
  };

  @override
  void initState() {
    super.initState();
    context.read<StudentCubit>().fetchStudentDetails(
      schoolId: widget.schoolId,
      studentId: widget.studentId,
    );
    context.read<SchoolCubit>().fetchSchools(widget.schoolId, 'school');
    _feesDueController.addListener(_calculateRemainingFees);
    _feesPaidController.addListener(_calculateRemainingFees);
  }

  void _calculateRemainingFees() {
    final feesDue = double.tryParse(_feesDueController.text.replaceAll(',', '')) ?? 0.0;
    final feesPaid = double.tryParse(_feesPaidController.text.replaceAll(',', '')) ?? 0.0;
    setState(() {
      remainingFees = feesDue - feesPaid;
      isFullyPaid = remainingFees <= 0;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final File file = File(image.path);
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference storageRef =
      FirebaseStorage.instance.ref().child('student_profiles/$fileName.jpg');
      try {
        await storageRef.putFile(file);
        final String downloadURL = await storageRef.getDownloadURL();
        setState(() {
          _profileImageUrl = downloadURL;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في رفع الصورة: $e')),
        );
      }
    }
  }

  Future<void> _updateStudent(Student student) async {
    if (_formKey.currentState!.validate()) {
      if (_selectedGradeAr == null || _selectedSectionAr == null || _selectedAcademicYear == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار الصف والشعبة والعام الدراسي')),
        );
        return;
      }

      // Fetch school data to map Arabic to French values
      final schoolState = context.read<SchoolCubit>().state;
      if (schoolState is SchoolsLoaded) {
        final school = schoolState.schools.firstWhere((s) => s.schoolId == widget.schoolId);
        final classesAr = school.classes['ar'] ?? [];
        final classesFr = school.classes['fr'] ?? [];
        final sectionsAr = school.sections['ar'] ?? {};
        final sectionsFr = school.sections['fr'] ?? {};
        final categoriesAr = school.categories['ar'] ?? [];
        final categoriesFr = school.categories['fr'] ?? [];

        // Ensure valid mappings for French values
        final gradeFrIndex = classesAr.indexOf(_selectedGradeAr!);
        final sectionFrList = sectionsFr[_selectedGradeAr];
        final sectionFrIndex = _selectedSectionAr != null && sectionsAr[_selectedGradeAr] != null
            ? sectionsAr[_selectedGradeAr]!.indexOf(_selectedSectionAr!)
            : -1;
        final categoryFrIndex = _selectedCategoryAr != null ? categoriesAr.indexOf(_selectedCategoryAr!) : -1;

        final updatedStudent = Student(
          id: student.id,
          firstNameAr: _firstNameArController.text,
          firstNameFr: _firstNameFrController.text,
          lastNameAr: _lastNameArController.text,
          lastNameFr: _lastNameFrController.text,
          gradeAr: _selectedGradeAr!,
          gradeFr: gradeFrIndex >= 0 && gradeFrIndex < classesFr.length ? classesFr[gradeFrIndex] : '',
          sectionAr: _selectedSectionAr!,
          sectionFr: sectionFrList != null && sectionFrIndex >= 0 && sectionFrIndex < sectionFrList.length
              ? sectionFrList[sectionFrIndex]
              : '',
          categoryAr: _selectedCategoryAr,
          categoryFr: categoryFrIndex >= 0 && categoryFrIndex < categoriesFr.length
              ? categoriesFr[categoryFrIndex]
              : null,
          birthDate: _birthDateController.text,
          phone: _phoneController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          addressAr: _addressArController.text,
          addressFr: _addressFrController.text.isEmpty ? null : _addressFrController.text,
          academicYear: _selectedAcademicYear!,
          schoolId: widget.schoolId,
          admissionDate: _admissionDateController.text,
          birthPlaceAr: _birthPlaceArController.text,
          birthPlaceFr: _birthPlaceFrController.text.isEmpty ? null : _birthPlaceFrController.text,
          profileImage: _profileImageUrl ?? student.profileImage,
          feesDue: double.tryParse(_feesDueController.text.replaceAll(',', '')) ?? 0.0,
          feesPaid: double.tryParse(_feesPaidController.text.replaceAll(',', '')) ?? 0.0,
          ministryFileNumber: _ministryFileNumberController.text.isEmpty ? null : _ministryFileNumberController.text,
          genderAr: _selectedGenderAr,
          genderFr: _selectedGenderAr != null ? _genders[_selectedGenderAr] : null,
          attendanceHistory: student.attendanceHistory,
        );

        context.read<StudentCubit>().updateStudent(
          schoolId: widget.schoolId,
          studentId: widget.studentId,
          student: updatedStudent,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تفاصيل الطالب / Détails de l'étudiant", style: TextStyle(color: Colors.white)),
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
            if (state is StudentUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تحديث بيانات الطالب بنجاح')),
              );
              Navigator.pop(context);
            } else if (state is StudentError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            } else if (state is StudentLoaded) {
              final student = state.student;
              _firstNameArController.text = student.firstNameAr;
              _firstNameFrController.text = student.firstNameFr;
              _lastNameArController.text = student.lastNameAr;
              _lastNameFrController.text = student.lastNameFr;
              _birthPlaceArController.text = student.birthPlaceAr;
              _birthPlaceFrController.text = student.birthPlaceFr ?? '';
              _addressArController.text = student.addressAr;
              _addressFrController.text = student.addressFr ?? '';
              _phoneController.text = student.phone;
              _emailController.text = student.email ?? '';
              _birthDateController.text = student.birthDate;
              _feesDueController.text = NumberFormat('#,##0.00').format(student.feesDue ?? 0.0);
              _feesPaidController.text = NumberFormat('#,##0.00').format(student.feesPaid ?? 0.0);
              _ministryFileNumberController.text = student.ministryFileNumber ?? '';
              _admissionDateController.text = student.admissionDate;
              _profileImageUrl = student.profileImage;

              _selectedGradeAr = student.gradeAr;
              _selectedSectionAr = student.sectionAr;
              _selectedGenderAr = student.genderAr;
              _selectedAcademicYear = student.academicYear;
              _selectedCategoryAr = student.categoryAr;

              _calculateRemainingFees();
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: BlocBuilder<StudentCubit, StudentState>(
                builder: (context, studentState) {
                  if (studentState is StudentLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (studentState is StudentLoaded) {
                    final student = studentState.student;

                    if (_selectedAcademicYear != null && !_academicYears.contains(_selectedAcademicYear)) {
                      _selectedAcademicYear = _academicYears.isNotEmpty ? _academicYears.first : null;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ChoiceChip(
                              label: const Text('العربية'),
                              selected: _selectedLanguage == 'ar',
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedLanguage = 'ar');
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Français'),
                              selected: _selectedLanguage == 'fr',
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedLanguage = 'fr');
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: _buildImagePicker(
                            label: 'صورة الطالب / Photo de l’étudiant',
                            imageUrl: _profileImageUrl,
                            onTap: _pickImage,
                            size: 200,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 5, blurRadius: 7),
                            ],
                          ),
                          child: BlocBuilder<SchoolCubit, SchoolState>(
                            builder: (context, schoolState) {
                              if (schoolState is SchoolsLoaded) {
                                final school = schoolState.schools.firstWhere(
                                      (s) => s.schoolId == widget.schoolId,
                                  orElse: () => Schoolinfo(
                                    schoolId: '',
                                    schoolName: {'ar': 'مدرسة غير محددة', 'fr': 'École non spécifiée'},
                                    city: {'ar': '', 'fr': ''},
                                    email: '',
                                    phone: '',
                                    currency: {'ar': '', 'fr': ''},
                                    currencySymbol: {'ar': '', 'fr': ''},
                                    address: {'ar': '', 'fr': ''},
                                    classes: {'ar': [], 'fr': []},
                                    sections: {'ar': {}, 'fr': {}},
                                    categories: {'ar': [], 'fr': []},
                                    mainSections: {'ar': [], 'fr': []}, // إضافة mainSections
                                    subSections: {'ar': {}, 'fr': {}},   // إضافة subSections
                                    logoUrl: null,
                                    principalName: {'ar': '', 'fr': ''},
                                    principalSignatureUrl: null,
                                    ownerId: null,
                                  ),
                                );

                                final classesAr = (school.classes['ar'] ?? []).toSet().toList();
                                final classesFr = (school.classes['fr'] ?? []).toSet().toList();
                                final sectionsAr = school.sections['ar'] ?? {};
                                final sectionsFr = school.sections['fr'] ?? {};
                                final categoriesAr = (school.categories['ar'] ?? []).toSet().toList();
                                final categoriesFr = (school.categories['fr'] ?? []).toSet().toList();

                                if (_selectedGradeAr != null && !classesAr.contains(_selectedGradeAr)) {
                                  _selectedGradeAr = classesAr.isNotEmpty ? classesAr.first : null;
                                  _selectedSectionAr = null;
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionTitle('معلومات مشتركة / Informations communes'),
                                    _buildTextField(
                                      label: 'رقم الطالب / Numéro de l’étudiant',
                                      controller: TextEditingController(text: student.id),
                                      readOnly: true,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      label: 'رقم الهاتف / Numéro de téléphone',
                                      controller: _phoneController,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      label: 'البريد الإلكتروني / E-mail',
                                      controller: _emailController,
                                      isRequired: false,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      label: 'تاريخ الميلاد / Date de naissance',
                                      controller: _birthDateController,
                                      onTap: _pickDate(_birthDateController),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      label: 'تاريخ القبول / Date d\'admission',
                                      controller: _admissionDateController,
                                      onTap: _pickDate(_admissionDateController),
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      decoration: _buildInputDecoration(
                                          _selectedLanguage == 'ar' ? 'الصف' : 'Classe'),
                                      value: _selectedLanguage == 'ar'
                                          ? _selectedGradeAr
                                          : classesFr.isNotEmpty && _selectedGradeAr != null
                                          ? classesFr[classesAr.indexOf(_selectedGradeAr!)]
                                          : null,
                                      items: (_selectedLanguage == 'ar' ? classesAr : classesFr).map((grade) {
                                        return DropdownMenuItem(value: grade, child: Text(grade));
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          if (_selectedLanguage == 'ar') {
                                            _selectedGradeAr = value;
                                          } else {
                                            _selectedGradeAr = classesAr[classesFr.indexOf(value!)];
                                          }
                                          _selectedSectionAr = null; // Reset section when grade changes
                                        });
                                      },
                                      validator: (value) =>
                                      value == null ? (_selectedLanguage == 'ar' ? 'مطلوب' : 'Requis') : null,
                                    ),
                                    const SizedBox(height: 12),
                                    if (_selectedGradeAr != null && (sectionsAr[_selectedGradeAr] ?? []).isNotEmpty)
                                      DropdownButtonFormField<String>(
                                        decoration: _buildInputDecoration(
                                            _selectedLanguage == 'ar' ? 'الشعبة' : 'Section'),
                                        value: _selectedLanguage == 'ar'
                                            ? _selectedSectionAr
                                            : sectionsFr[_selectedGradeAr] != null && _selectedSectionAr != null
                                            ? sectionsFr[_selectedGradeAr]![
                                        sectionsAr[_selectedGradeAr]!.indexOf(_selectedSectionAr!)]
                                            : null,
                                        items: (_selectedLanguage == 'ar'
                                            ? sectionsAr[_selectedGradeAr]
                                            : sectionsFr[_selectedGradeAr] ?? [])!
                                            .map((section) {
                                          return DropdownMenuItem(value: section, child: Text(section));
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            if (_selectedLanguage == 'ar') {
                                              _selectedSectionAr = value;
                                            } else {
                                              _selectedSectionAr =
                                              sectionsAr[_selectedGradeAr]![sectionsFr[_selectedGradeAr]!.indexOf(value!)];
                                            }
                                          });
                                        },
                                        validator: (value) =>
                                        value == null ? (_selectedLanguage == 'ar' ? 'مطلوب' : 'Requis') : null,
                                      ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      decoration: _buildInputDecoration(_selectedLanguage == 'ar' ? 'الجنس' : 'Genre'),
                                      value: _selectedLanguage == 'ar' ? _selectedGenderAr : _genders[_selectedGenderAr],
                                      items: (_selectedLanguage == 'ar' ? _genders.keys : _genders.values).map((gender) {
                                        return DropdownMenuItem(value: gender, child: Text(gender));
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          if (_selectedLanguage == 'ar') {
                                            _selectedGenderAr = value;
                                          } else {
                                            _selectedGenderAr = _genders.keys.firstWhere(
                                                  (k) => _genders[k] == value,
                                              orElse: () => _genders.keys.first, // Default to first value if not found
                                            );
                                          }
                                        });
                                      },
                                      validator: (value) =>
                                      value == null ? (_selectedLanguage == 'ar' ? 'مطلوب' : 'Requis') : null,
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      decoration: _buildInputDecoration(
                                          _selectedLanguage == 'ar' ? 'الفئة' : 'Catégorie'),
                                      value: _selectedLanguage == 'ar'
                                          ? _selectedCategoryAr
                                          : (_selectedCategoryAr != null && categoriesAr.contains(_selectedCategoryAr)
                                          ? categoriesFr[categoriesAr.indexOf(_selectedCategoryAr!)]
                                          : null),
                                      items: (_selectedLanguage == 'ar' ? categoriesAr : categoriesFr).map((category) {
                                        return DropdownMenuItem(value: category, child: Text(category));
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          if (_selectedLanguage == 'ar') {
                                            _selectedCategoryAr = value;
                                          } else {
                                            _selectedCategoryAr = value != null && categoriesFr.contains(value)
                                                ? categoriesAr[categoriesFr.indexOf(value)]
                                                : null;
                                          }
                                        });
                                      },
                                    ),

                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      label: 'المصاريف المستحقة / Frais dus',
                                      controller: _feesDueController,
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      label: 'المصاريف المدفوعة / Frais payés',
                                      controller: _feesPaidController,
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'المبلغ المتبقي / Montant restant : ${NumberFormat('#,##0.00').format(remainingFees)}',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    if (isFullyPaid)
                                      const Text(
                                        'مدفوع بالكامل / Payé en totalité',
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
                                      ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      label: 'رقم الملف في الوزارة / Numéro de dossier au ministère',
                                      controller: _ministryFileNumberController,
                                      isRequired: false,
                                    ),
                                    const SizedBox(height: 12),
                                    _academicYears.isEmpty
                                        ? const Text('لا توجد أعوام دراسية متاحة / Aucune année académique disponible')
                                        : DropdownButtonFormField<String>(
                                      decoration: _buildInputDecoration('العام الدراسي / Année académique'),
                                      value: _selectedAcademicYear,
                                      items: _academicYears.map((year) {
                                        return DropdownMenuItem(value: year, child: Text(year));
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedAcademicYear = value;
                                        });
                                      },
                                      validator: (value) => value == null ? 'مطلوب' : null,
                                    ),
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
                                    BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 5, blurRadius: 7),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionTitle('Informations en français'),
                                    _buildTextField(
                                      label: 'Prénom',
                                      controller: _firstNameFrController,
                                      textAlign: TextAlign.left,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      label: 'Nom de famille',
                                      controller: _lastNameFrController,
                                      textAlign: TextAlign.left,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      label: 'Lieu de naissance',
                                      controller: _birthPlaceFrController,
                                      textAlign: TextAlign.left,
                                      isRequired: false,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      label: 'Adresse',
                                      controller: _addressFrController,
                                      textAlign: TextAlign.left,
                                      isRequired: false,
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
                                    _buildSectionTitle('معلومات بالعربية'),
                                    _buildTextField(
                                      label: 'الاسم الأول',
                                      controller: _firstNameArController,
                                      textAlign: TextAlign.right,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      label: 'اسم العائلة',
                                      controller: _lastNameArController,
                                      textAlign: TextAlign.right,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      label: 'مكان الميلاد',
                                      controller: _birthPlaceArController,
                                      textAlign: TextAlign.right,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      label: 'العنوان',
                                      controller: _addressArController,
                                      textAlign: TextAlign.right,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _updateStudent(student),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 5,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('تحديث / Mettre à jour',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return const Center(
                      child: Text("لا يمكن تحميل بيانات الطالب / Impossible de charger les données de l'étudiant"));
                },
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
    TextEditingController? controller,
    bool readOnly = false,
    TextAlign textAlign = TextAlign.left,
    bool isRequired = true,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      textAlign: textAlign,
      decoration: _buildInputDecoration(label),
      enabled: enabled,
      keyboardType: keyboardType,
      onTap: onTap,
      validator: validator ??
          (isRequired
              ? (value) => value!.isEmpty
              ? (textAlign == TextAlign.right ? 'مطلوب' : 'Requis')
              : null
              : null),
      onChanged: controller == _feesDueController || controller == _feesPaidController
          ? (value) => _calculateRemainingFees()
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
        Text(label, style: const TextStyle(fontSize: 20, color: Colors.white)),
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

  VoidCallback _pickDate(TextEditingController controller) {
    return () async {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );
      if (pickedDate != null) {
        controller.text = "${pickedDate.toLocal()}".split(' ')[0];
      }
    };
  }
}