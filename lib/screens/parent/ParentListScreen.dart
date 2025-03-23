import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:file_selector/file_selector.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import '../../cubit/auth/auth_cubit.dart';
import '../../cubit/auth/auth_state.dart';
import '../../cubit/parent/parent_cubit.dart';
import '../../cubit/parent/parent_state.dart';
import '../../cubit/school_info/school_info_cubit.dart';
import '../../cubit/school_info/school_info_state.dart';
import '../../cubit/student/student_cubit.dart';
import '../../cubit/student/student_state.dart';
import '../../models/parent_model.dart';
import '../../models/school_info_model.dart';
import 'ParentDetailsScreen.dart';

class ParentListScreen extends StatefulWidget {
  final String? schoolId;

  const ParentListScreen({this.schoolId});

  @override
  _ParentListScreenState createState() => _ParentListScreenState();
}

class _ParentListScreenState extends State<ParentListScreen> {
  String? selectedSchoolId;
  String _selectedLanguage = 'ar';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      if (authState.role == 'admin') {
        context.read<SchoolCubit>().fetchSchools(authState.uid, authState.role);
        context.read<ParentCubit>().fetchAllParents();
      } else if (authState.role == 'school') {
        selectedSchoolId = widget.schoolId ?? authState.uid;
        context.read<SchoolCubit>().fetchSchools(selectedSchoolId!, authState.role);
        context.read<ParentCubit>().fetchParents(selectedSchoolId!);
        context.read<StudentCubit>().fetchStudents(schoolId: selectedSchoolId!);
      } else if (authState.role == 'employee' && authState.schoolId != null) {
        selectedSchoolId = authState.schoolId;
        context.read<SchoolCubit>().fetchSchools(selectedSchoolId!, authState.role);
        context.read<ParentCubit>().fetchParents(selectedSchoolId!);
        context.read<StudentCubit>().fetchStudents(schoolId: selectedSchoolId!);
      }
    }
  }

  void _filterParents() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      if (authState.role == 'school' && selectedSchoolId != null) {
        context.read<ParentCubit>().fetchParents(selectedSchoolId!);
      } else if (authState.role == 'employee' && authState.schoolId != null) {
        selectedSchoolId = authState.schoolId;
        context.read<ParentCubit>().fetchParents(selectedSchoolId!);
      } else if (authState.role == 'admin') {
        if (selectedSchoolId != null) {
          context.read<ParentCubit>().fetchParents(selectedSchoolId!);
        } else {
          context.read<ParentCubit>().fetchAllParents();
        }
      }
    }
  }

  void _confirmDelete(BuildContext context, Parent parent) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(_selectedLanguage == 'ar' ? 'تأكيد الحذف' : 'Confirmer la suppression'),
          content: Text(_selectedLanguage == 'ar'
              ? 'هل أنت متأكد من حذف ولي الأمر ${parent.nameAr}؟'
              : 'Êtes-vous sûr de vouloir supprimer le parent ${parent.nameFr ?? parent.nameAr} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_selectedLanguage == 'ar' ? 'إلغاء' : 'Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _deleteParent(context, parent);
              },
              child: Text(_selectedLanguage == 'ar' ? 'حذف' : 'Supprimer', style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteParent(BuildContext context, Parent parent) async {
    try {
      context.read<ParentCubit>().deleteParent(parent.schoolId, parent.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_selectedLanguage == 'ar' ? 'تم حذف ولي الأمر بنجاح' : 'Parent supprimé avec succès'),
        ),
      );
      _filterParents(); // تحديث القائمة بعد الحذف
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_selectedLanguage == 'ar' ? 'فشل في حذف ولي الأمر: $e' : 'Échec de la suppression: $e'),
        ),
      );
    }
  }

  Future<void> _generateParentsListPdf(List<Parent> parents) async {
    final pdf = pw.Document();
    final arabicFont = await pw.Font.ttf((await rootBundle.load('assets/fonts/Amiri-Regular.ttf')).buffer.asByteData());
    final frenchFont = await pw.Font.ttf((await rootBundle.load('assets/fonts/Amiri-Regular.ttf')).buffer.asByteData());
    final maliFlagImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/mali.png')).buffer.asUint8List(),
    );

    String schoolName = _selectedLanguage == 'ar' ? 'غير متوفر' : 'Non disponible';
    final schoolState = context.read<SchoolCubit>().state;
    if (schoolState is SchoolsLoaded && selectedSchoolId != null) {
      final selectedSchool = schoolState.schools.firstWhere(
            (school) => school.schoolId == selectedSchoolId,
        orElse: () => Schoolinfo(
          schoolId: selectedSchoolId!,
          schoolName: {'fr': 'Non disponible', 'ar': 'غير متوفر'},
          city: {'fr': '', 'ar': ''},
          email: '',
          phone: '',
          currency: {'fr': '', 'ar': ''},
          currencySymbol: {'fr': '', 'ar': ''},
          address: {'fr': '', 'ar': ''},
          classes: {'fr': [], 'ar': []},
          sections: {'fr': {}, 'ar': {}},
          categories: {'fr': [], 'ar': []},
          mainSections: {'fr': [], 'ar': []},
          subSections: {'fr': {}, 'ar': {}},
          principalName: {'fr': 'غير متوفر', 'ar': 'غير متوفر'},
        ),
      );
      schoolName = selectedSchool.schoolName[_selectedLanguage] ?? (_selectedLanguage == 'ar' ? 'غير متوفر' : 'Non disponible');
    }

    if (parents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_selectedLanguage == 'ar' ? 'لا يوجد أولياء أمور للطباعة' : 'Aucun parent à imprimer')),
      );
      return;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Image(maliFlagImage, width: 30, height: 20),
                  pw.SizedBox(width: 5),
                  pw.Text(
                    'RÉPUBLIQUE DU MALI',
                    style: pw.TextStyle(font: frenchFont, fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text('UN PEUPLE - UN BUT - UNE FOI', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: frenchFont, fontSize: 8)),
              pw.Text('INSTITUT IMANE', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: frenchFont, fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text('POUR LES ETUDES ISLAMIQUES', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: frenchFont, fontSize: 9)),
              pw.Text(
                _selectedLanguage == 'ar' ? 'المدرسة: $schoolName' : 'École: $schoolName',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: _selectedLanguage == 'ar' ? arabicFont : frenchFont, fontSize: 10),
                textDirection: _selectedLanguage == 'ar' ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black),
                columnWidths: {
                  0: pw.FixedColumnWidth(150),
                  1: pw.FixedColumnWidth(100),
                  2: pw.FixedColumnWidth(100),
                  3: pw.FixedColumnWidth(50),
                },
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Container(
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          _selectedLanguage == 'ar' ? 'رقم الهاتف' : 'Numéro de téléphone',
                          style: pw.TextStyle(
                            font: _selectedLanguage == 'ar' ? arabicFont : frenchFont,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textDirection: _selectedLanguage == 'ar' ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          _selectedLanguage == 'ar' ? 'الاسم (فرنسي)' : 'Nom (Français)',
                          style: pw.TextStyle(
                            font: _selectedLanguage == 'ar' ? arabicFont : frenchFont,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textDirection: _selectedLanguage == 'ar' ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          _selectedLanguage == 'ar' ? 'الاسم (عربي)' : 'Nom (Arabe)',
                          style: pw.TextStyle(
                            font: _selectedLanguage == 'ar' ? arabicFont : frenchFont,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textDirection: _selectedLanguage == 'ar' ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          _selectedLanguage == 'ar' ? 'المعرف' : 'Identifiant',
                          style: pw.TextStyle(
                            font: _selectedLanguage == 'ar' ? arabicFont : frenchFont,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textDirection: _selectedLanguage == 'ar' ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                        ),
                      ),
                    ],
                  ),
                  ...parents.asMap().entries.map((entry) {
                    final parent = entry.value;
                    return pw.TableRow(
                      children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            parent.phone,
                            style: pw.TextStyle(font: frenchFont, fontSize: 10),
                            textDirection: _selectedLanguage == 'ar' ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                          ),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            parent.nameFr ?? (_selectedLanguage == 'ar' ? 'غير متوفر' : 'Non disponible'),
                            style: pw.TextStyle(font: frenchFont, fontSize: 10),
                            textDirection: _selectedLanguage == 'ar' ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                          ),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            parent.nameAr,
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            parent.id,
                            style: pw.TextStyle(font: frenchFont, fontSize: 10),
                            textDirection: _selectedLanguage == 'ar' ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final FileSaveLocation? fileSaveLocation = await getSaveLocation(suggestedName: 'parents_list.pdf');
    if (fileSaveLocation != null) {
      final file = File(fileSaveLocation.path);
      await file.writeAsBytes(bytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إنشاء PDF بنجاح في: ${fileSaveLocation.path}'), duration: const Duration(seconds: 5)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إلغاء عملية الحفظ'), duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('يرجى تسجيل الدخول / Veuillez vous connecter')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'قائمة أولياء الأمور / Liste des parents',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            onPressed: () async {
              final state = context.read<ParentCubit>().state;
              if (state is ParentsLoaded) {
                await _generateParentsListPdf(state.parents);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_selectedLanguage == 'ar'
                        ? 'لا يوجد بيانات للطباعة'
                        : 'Aucune donnée à imprimer'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
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
                    selectedColor: Colors.blueAccent,
                    backgroundColor: Colors.grey.shade300,
                    labelStyle: TextStyle(
                      color: _selectedLanguage == 'ar' ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Français'),
                    selected: _selectedLanguage == 'fr',
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedLanguage = 'fr');
                    },
                    selectedColor: Colors.blueAccent,
                    backgroundColor: Colors.grey.shade300,
                    labelStyle: TextStyle(
                      color: _selectedLanguage == 'fr' ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: BlocBuilder<SchoolCubit, SchoolState>(
                  builder: (context, schoolState) {
                    if (schoolState is SchoolsLoaded) {
                      final schools = schoolState.schools;
                      if (schools.isEmpty) {
                        return const Center(child: Text('لا توجد مدارس متاحة / Aucune école disponible'));
                      }

                      if (authState.role == 'school' && schools.isNotEmpty) {
                        selectedSchoolId ??= widget.schoolId ?? authState.uid;
                      } else if (authState.role == 'employee' && schools.isNotEmpty) {
                        selectedSchoolId ??= authState.schoolId;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('فلترة أولياء الأمور / Filtrer les parents'),
                          if (authState.role == 'admin') ...[
                            _buildDropdown(
                              label: 'المدرسة / École',
                              value: selectedSchoolId,
                              items: schools.map((school) {
                                return DropdownMenuItem(
                                  value: school.schoolId,
                                  child: Text(school.schoolName[_selectedLanguage] ?? ''),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedSchoolId = value;
                                  _filterParents();
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('قائمة أولياء الأمور / Liste des parents'),
                    TextField(
                      decoration: _buildInputDecoration('ابحث بالاسم أو المعرف / Rechercher par nom ou ID'),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<ParentCubit, ParentState>(
                      builder: (context, state) {
                        if (state is ParentLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (state is ParentsLoaded) {
                          final filteredParents = state.parents.where((parent) {
                            final name = _selectedLanguage == 'ar' ? parent.nameAr : (parent.nameFr ?? '');
                            return (parent.id.contains(_searchQuery) || name.contains(_searchQuery)) &&
                                (selectedSchoolId == null || parent.schoolId == selectedSchoolId);
                          }).toList();

                          if (filteredParents.isEmpty) {
                            return const Center(child: Text('لا يوجد أولياء أمور مسجلين / Aucun parent trouvé'));
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: filteredParents.length,
                            itemBuilder: (context, index) {
                              final parent = filteredParents[index];
                              return GestureDetector(
                                onTap: () {
                                  if (selectedSchoolId != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ParentDetailsScreen(
                                          parent: parent,
                                          schoolId: selectedSchoolId!,
                                        ),
                                      ),
                                    ).then((_) => _filterParents());
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  child: Card(
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.blueAccent.withOpacity(0.1), Colors.white],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                onPressed: () => _confirmDelete(context, parent),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          CircleAvatar(
                                            radius: 35,
                                            backgroundColor: Colors.grey.shade200,
                                            child: const Icon(Icons.person, size: 25, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _selectedLanguage == 'ar' ? parent.nameAr : (parent.nameFr ?? ''),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black87,
                                              fontFamily: 'Roboto',
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.phone, size: 16, color: Colors.blueAccent),
                                              const SizedBox(width: 4),
                                              Text(
                                                parent.phone,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.black87,
                                                  fontFamily: 'Roboto',
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.email, size: 16, color: Colors.blueAccent),
                                              const SizedBox(width: 4),
                                              Text(
                                                parent.email ?? 'غير متوفر / Non disponible',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.black87,
                                                  fontFamily: 'Roboto',
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }
                        return const Center(child: Text('خطأ في تحميل البيانات / Erreur lors du chargement des données'));
                      },
                    ),
                  ],
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
      labelStyle: const TextStyle(color: Colors.blueAccent),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
      prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: _buildInputDecoration(label),
      value: value,
      items: items,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.black87),
      dropdownColor: Colors.white,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
    );
  }
}