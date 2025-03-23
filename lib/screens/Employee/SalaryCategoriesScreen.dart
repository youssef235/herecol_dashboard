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
  final _nameFrController = TextEditingController(); // للاسم بالفرنسية
  final _fullTimeController = TextEditingController();
  final _halfTimeController = TextEditingController();
  final _overtimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSchoolId = widget.schoolId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFrController.dispose();
    _fullTimeController.dispose();
    _halfTimeController.dispose();
    _overtimeController.dispose();
    super.dispose();
  }

  void _showEditDialog(BuildContext context, SalaryCategory category, String schoolId) {
    _nameController.text = category.categoryName;
    _nameFrController.text = category.categoryNameFr;
    _fullTimeController.text = category.fullTimeSalary.toString();
    _halfTimeController.text = category.halfTimeSalary?.toString() ?? '';
    _overtimeController.text = category.overtimeHourRate?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل فئة الرواتب / Modifier la catégorie de salaire', style: GoogleFonts.cairo()),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الفئة (عربي) / Nom de la catégorie (arabe)',
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'مطلوب / Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameFrController,
                  decoration: InputDecoration(
                    labelText: 'اسم الفئة (فرنسي) / Nom de la catégorie (français)',
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'مطلوب / Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fullTimeController,
                  decoration: InputDecoration(
                    labelText: 'راتب الدوام الكامل / Salaire à temps plein',
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'مطلوب / Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _halfTimeController,
                  decoration: InputDecoration(
                    labelText: 'راتب الدوام النصفي (اختياري) / Salaire à mi-temps (optionnel)',
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _overtimeController,
                  decoration: InputDecoration(
                    labelText: 'سعر الساعة الإضافية (اختياري) / Taux horaire supplémentaire (optionnel)',
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء / Annuler', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final updatedCategory = SalaryCategory(
                  id: category.id,
                  categoryName: _nameController.text,
                  categoryNameFr: _nameFrController.text,
                  fullTimeSalary: double.parse(_fullTimeController.text),
                  halfTimeSalary: _halfTimeController.text.isEmpty ? null : double.parse(_halfTimeController.text),
                  overtimeHourRate: _overtimeController.text.isEmpty ? null : double.parse(_overtimeController.text),
                  currency: category.currency,
                  description: category.description,
                  isActive: category.isActive,
                );
                context.read<SalaryCubit>().updateSalaryCategory(updatedCategory, schoolId);
                Navigator.pop(context);
              }
            },
            child: Text('حفظ / Enregistrer', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String categoryId, String schoolId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف فئة الرواتب / Supprimer la catégorie de salaire', style: GoogleFonts.cairo()),
        content: Text('هل أنت متأكد من حذف هذه الفئة؟ / Êtes-vous sûr de vouloir supprimer cette catégorie ?', style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء / Annuler', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<SalaryCubit>().deleteSalaryCategory(categoryId, schoolId);
              Navigator.pop(context);
            },
            child: Text('حذف / Supprimer', style: GoogleFonts.cairo()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
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
                    content: Text('تمت إضافة فئة الرواتب بنجاح / Catégorie de salaire ajoutée avec succès', style: GoogleFonts.cairo()),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is SalaryCategoryUpdated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم تعديل فئة الرواتب بنجاح / Catégorie de salaire mise à jour avec succès', style: GoogleFonts.cairo()),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is SalaryCategoryDeleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم حذف فئة الرواتب بنجاح / Catégorie de salaire supprimée avec succès', style: GoogleFonts.cairo()),
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
      return Center(child: Text('لم يتم تحديد معرف المدرسة / Aucun identifiant d\'école spécifié', style: GoogleFonts.cairo()));
    }
    if (isSuperAdmin) {
      return BlocBuilder<SchoolCubit, SchoolState>(
        builder: (context, schoolState) {
          if (schoolState is SchoolsLoaded) {
            if (_selectedSchoolId != null &&
                !schoolState.schools.any((school) => school.schoolId == _selectedSchoolId)) {
              _selectedSchoolId = schoolState.schools.isNotEmpty ? schoolState.schools.first.schoolId : null;
            }
            return _buildSchoolSelectionView(context, schoolState.schools);
          } else if (schoolState is SchoolError) {
            return Center(child: Text('خطأ: ${schoolState.message} / Erreur: ${schoolState.message}', style: GoogleFonts.cairo()));
          }
          return const Center(child: CircularProgressIndicator());
        },
      );
    }
    return Center(child: Text('يرجى اختيار المدرسة لعرض الفئات / Veuillez sélectionner une école pour afficher les catégories', style: GoogleFonts.cairo()));
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
          Center(child: Text('يرجى اختيار مدرسة لعرض الفئات / Veuillez sélectionner une école pour afficher les catégories', style: GoogleFonts.cairo())),
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
                if (_selectedSchoolId != null &&
                    !schoolState.schools.any((school) => school.schoolId == _selectedSchoolId)) {
                  _selectedSchoolId = schoolState.schools.isNotEmpty ? schoolState.schools.first.schoolId : null;
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
                    '${category.categoryName} / ${category.categoryNameFr}',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'دوام كامل: ${category.fullTimeSalary} | نصفي: ${category.halfTimeSalary ?? 'غير محدد'} | إضافي: ${category.overtimeHourRate ?? 'غير محدد'}',
                      style: GoogleFonts.cairo(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditDialog(context, category, isSuperAdmin ? _selectedSchoolId! : widget.schoolId!),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteDialog(context, category.id, isSuperAdmin ? _selectedSchoolId! : widget.schoolId!),
                      ),
                    ],
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
        validator: (value) => value == null ? 'مطلوب اختيار مدرسة / Sélection d\'une école requise' : null,
        hint: Text('اختر مدرسة... / Sélectionnez une école...', style: GoogleFonts.cairo()),
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
                  'إضافة فئة رواتب جديدة / Ajouter une nouvelle catégorie de salaire',
                  style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                const SizedBox(height: 16),
                if (isSuperAdmin)
                  BlocBuilder<SchoolCubit, SchoolState>(
                    builder: (context, state) {
                      if (state is SchoolsLoaded) {
                        if (_selectedSchoolId != null &&
                            !state.schools.any((school) => school.schoolId == _selectedSchoolId)) {
                          _selectedSchoolId = state.schools.isNotEmpty ? state.schools.first.schoolId : null;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'المدرسة / École',
                              labelStyle: GoogleFonts.cairo(),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                            validator: (value) => value == null ? 'مطلوب اختيار مدرسة / Sélection d\'une école requise' : null,
                            hint: Text('اختر مدرسة... / Sélectionnez une école...', style: GoogleFonts.cairo()),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الفئة (عربي) / Nom de la catégorie (arabe)',
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'مطلوب / Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameFrController,
                  decoration: InputDecoration(
                    labelText: 'اسم الفئة (فرنسي) / Nom de la catégorie (français)',
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'مطلوب / Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fullTimeController,
                  decoration: InputDecoration(
                    labelText: 'راتب الدوام الكامل / Salaire à temps plein',
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'مطلوب / Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _halfTimeController,
                  decoration: InputDecoration(
                    labelText: 'راتب الدوام النصفي (اختياري) / Salaire à mi-temps (optionnel)',
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _overtimeController,
                  decoration: InputDecoration(
                    labelText: 'سعر الساعة الإضافية (اختياري) / Taux horaire supplémentaire (optionnel)',
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final category = SalaryCategory(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          categoryName: _nameController.text,
                          categoryNameFr: _nameFrController.text,
                          fullTimeSalary: double.parse(_fullTimeController.text),
                          halfTimeSalary: _halfTimeController.text.isEmpty ? null : double.parse(_halfTimeController.text),
                          overtimeHourRate: _overtimeController.text.isEmpty ? null : double.parse(_overtimeController.text),
                        );
                        final schoolIdToUse = isSuperAdmin ? _selectedSchoolId : defaultSchoolId;
                        if (schoolIdToUse != null) {
                          context.read<SalaryCubit>().addSalaryCategory(category, schoolIdToUse);
                          _nameController.clear();
                          _nameFrController.clear();
                          _fullTimeController.clear();
                          _halfTimeController.clear();
                          _overtimeController.clear();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('يرجى اختيار المدرسة أولاً / Veuillez d\'abord sélectionner une école', style: GoogleFonts.cairo()),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('إضافة فئة رواتب / Ajouter une catégorie de salaire', style: GoogleFonts.cairo(fontSize: 16)),
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