import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:school_management_dashboard/firebase_services/school_info_firebase_services.dart';
import '../../cubit/auth/auth_cubit.dart';
import '../../cubit/auth/auth_state.dart';
import '../../cubit/salary/salary_cubit.dart';
import '../../cubit/salary/salary_state.dart';
import '../../cubit/school_info/school_info_cubit.dart';
import '../../cubit/school_info/school_info_state.dart';
import '../../firebase_services/SalaryFirebaseServices.dart';
import '../../models/SalaryCategory.dart';
import '../../models/school_info_model.dart';

class SalaryCategoriesScreen extends StatefulWidget {
  final String? schoolId;

  const SalaryCategoriesScreen({required this.schoolId, super.key});

  @override
  State<SalaryCategoriesScreen> createState() => _SalaryCategoriesScreenState();
}

class _SalaryCategoriesScreenState extends State<SalaryCategoriesScreen> {
  String? _selectedSchoolId;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _fullTimeController = TextEditingController();
  final _halfTimeController = TextEditingController();
  final _overtimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSchoolId = widget.schoolId; // تعيين القيمة الافتراضية
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fullTimeController.dispose();
    _halfTimeController.dispose();
    _overtimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isSuperAdmin = authState is AuthAuthenticated && authState.role == 'admin';

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SalaryCubit(SalaryFirebaseServices())
            ..fetchSalaryCategories(_selectedSchoolId ?? (isSuperAdmin ? null : widget.schoolId)),
        ),
        if (isSuperAdmin)
          BlocProvider(
            create: (context) => SchoolCubit(SchoolFirebaseServices())
              ..fetchSchools(authState.uid, 'admin'),
          ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'فئات الرواتب / Catégories de salaires',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
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
          child: BlocListener<SalaryCubit, SalaryState>(
            listener: (context, state) {
              if (state is SalaryCategoryAdded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تمت إضافة فئة الرواتب بنجاح', style: GoogleFonts.cairo()),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is SalaryError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message, style: GoogleFonts.cairo()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: BlocBuilder<SalaryCubit, SalaryState>(
              builder: (context, salaryState) {
                if (salaryState is SalaryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (salaryState is SalaryCategoriesLoaded) {
                  return _buildCategoriesView(context, salaryState.categories, isSuperAdmin);
                }
                if (salaryState is SalaryError) {
                  return Center(child: Text(salaryState.message, style: GoogleFonts.cairo()));
                }
                return _buildInitialView(context, isSuperAdmin);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialView(BuildContext context, bool isSuperAdmin) {
    if (!isSuperAdmin && widget.schoolId == null) {
      return Center(child: Text('لم يتم تحديد معرف المدرسة', style: GoogleFonts.cairo()));
    }
    if (isSuperAdmin) {
      return BlocBuilder<SchoolCubit, SchoolState>(
        builder: (context, schoolState) {
          if (schoolState is SchoolsLoaded) {
            // تحقق من أن _selectedSchoolId موجود في قائمة المدارس
            if (_selectedSchoolId != null &&
                !schoolState.schools.any((school) => school.schoolId == _selectedSchoolId)) {
              _selectedSchoolId = schoolState.schools.isNotEmpty
                  ? schoolState.schools.first.schoolId
                  : null;
            }
            return _buildSchoolSelectionView(context, schoolState.schools);
          } else if (schoolState is SchoolError) {
            return Center(child: Text('خطأ: ${schoolState.message}', style: GoogleFonts.cairo()));
          }
          return const Center(child: CircularProgressIndicator());
        },
      );
    }
    return Center(child: Text('يرجى اختيار المدرسة لعرض الفئات', style: GoogleFonts.cairo()));
  }

  Widget _buildSchoolSelectionView(BuildContext context, List<Schoolinfo> schools) {
    return Column(
      children: [
        _buildSchoolDropdown(context, schools, (value) {
          setState(() {
            _selectedSchoolId = value;
            if (value != null) {
              context.read<SalaryCubit>().fetchSalaryCategories(value);
            }
          });
        }),
        const SizedBox(height: 16),
        if (_selectedSchoolId == null)
          Center(child: Text('يرجى اختيار مدرسة لعرض الفئات', style: GoogleFonts.cairo())),
      ],
    );
  }

  Widget _buildCategoriesView(BuildContext context, List<SalaryCategory> categories, bool isSuperAdmin) {
    return Column(
      children: [
        if (isSuperAdmin)
          BlocBuilder<SchoolCubit, SchoolState>(
            builder: (context, schoolState) {
              if (schoolState is SchoolsLoaded) {
                // تحقق من أن _selectedSchoolId موجود في قائمة المدارس
                if (_selectedSchoolId != null &&
                    !schoolState.schools.any((school) => school.schoolId == _selectedSchoolId)) {
                  _selectedSchoolId = schoolState.schools.isNotEmpty
                      ? schoolState.schools.first.schoolId
                      : null;
                }
                return _buildSchoolDropdown(context, schoolState.schools, (value) {
                  setState(() {
                    _selectedSchoolId = value;
                    if (value != null) {
                      context.read<SalaryCubit>().fetchSalaryCategories(value);
                    }
                  });
                });
              }
              return const SizedBox();
            },
          ),
        Expanded(
          child: ListView.builder(
            itemCount: categories.length + 1,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAddCategoryForm(context, isSuperAdmin ? _selectedSchoolId : widget.schoolId);
              }
              final category = categories[index - 1];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    category.categoryName,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'دوام كامل: ${category.fullTimeSalary} | نصفي: ${category.halfTimeSalary} | إضافي: ${category.overtimeHourRate}',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolDropdown(BuildContext context, List<Schoolinfo> schools, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'اختر المدرسة / Choisir l’école',
          labelStyle: GoogleFonts.cairo(),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        value: _selectedSchoolId,
        items: schools.map((school) {
          return DropdownMenuItem(
            value: school.schoolId,
            child: Text(
              '${school.schoolName['ar'] ?? 'غير متوفر'} / ${school.schoolName['fr'] ?? 'Non disponible'}',
              style: GoogleFonts.cairo(),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'مطلوب اختيار مدرسة' : null,
        hint: Text('اختر مدرسة...', style: GoogleFonts.cairo()),
      ),
    );
  }

  Widget _buildAddCategoryForm(BuildContext context, String? defaultSchoolId) {
    final authState = context.read<AuthCubit>().state;
    final isSuperAdmin = authState is AuthAuthenticated && authState.role == 'admin';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إضافة فئة رواتب جديدة',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 16),
                if (isSuperAdmin)
                  BlocBuilder<SchoolCubit, SchoolState>(
                    builder: (context, state) {
                      if (state is SchoolsLoaded) {
                        // تحقق من أن _selectedSchoolId موجود في قائمة المدارس
                        if (_selectedSchoolId != null &&
                            !state.schools.any((school) => school.schoolId == _selectedSchoolId)) {
                          _selectedSchoolId = state.schools.isNotEmpty
                              ? state.schools.first.schoolId
                              : null;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'المدرسة / École',
                              labelStyle: GoogleFonts.cairo(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            value: _selectedSchoolId,
                            items: state.schools.map((school) {
                              return DropdownMenuItem(
                                value: school.schoolId,
                                child: Text(
                                  '${school.schoolName['ar'] ?? 'غير متوفر'} / ${school.schoolName['fr'] ?? 'Non disponible'}',
                                  style: GoogleFonts.cairo(),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSchoolId = value;
                              });
                            },
                            validator: (value) => value == null ? 'مطلوب اختيار مدرسة' : null,
                            hint: Text('اختر مدرسة...', style: GoogleFonts.cairo()),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الفئة',
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fullTimeController,
                  decoration: InputDecoration(
                    labelText: 'راتب الدوام الكامل',
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _halfTimeController,
                  decoration: InputDecoration(
                    labelText: 'راتب الدوام النصفي',
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _overtimeController,
                  decoration: InputDecoration(
                    labelText: 'سعر الساعة الإضافية',
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final category = SalaryCategory(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          categoryName: _nameController.text,
                          fullTimeSalary: double.tryParse(_fullTimeController.text) ?? 0.0,
                          halfTimeSalary: double.tryParse(_halfTimeController.text) ?? 0.0,
                          overtimeHourRate: double.tryParse(_overtimeController.text) ?? 0.0,
                        );
                        final schoolIdToUse = isSuperAdmin ? _selectedSchoolId : defaultSchoolId;
                        if (schoolIdToUse != null) {
                          context.read<SalaryCubit>().addSalaryCategory(category, schoolIdToUse);
                          _nameController.clear();
                          _fullTimeController.clear();
                          _halfTimeController.clear();
                          _overtimeController.clear();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('يرجى اختيار المدرسة أولاً', style: GoogleFonts.cairo()),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('إضافة فئة رواتب', style: GoogleFonts.cairo(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}