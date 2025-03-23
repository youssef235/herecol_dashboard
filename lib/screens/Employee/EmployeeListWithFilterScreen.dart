import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_selector/file_selector.dart';
import '../../cubit/Employee/EmployeeCubit.dart';
import '../../cubit/Employee/EmployeeState.dart';
import '../../cubit/auth/auth_cubit.dart';
import '../../cubit/auth/auth_state.dart';
import '../../cubit/salary/salary_cubit.dart';
import '../../cubit/school_info/school_info_cubit.dart';
import '../../cubit/school_info/school_info_state.dart';
import '../../models/school_info_model.dart';
import 'EmployeeDetailsScreen.dart';

class EmployeeListWithFilterScreen extends StatefulWidget {
  final String? schoolId;

  const EmployeeListWithFilterScreen({this.schoolId});

  @override
  _EmployeeListWithFilterScreenState createState() => _EmployeeListWithFilterScreenState();
}

class _EmployeeListWithFilterScreenState extends State<EmployeeListWithFilterScreen> {
  String? selectedSchoolId;
  String? selectedDepartment;
  String? selectedSubDepartment;
  String _selectedLanguage = 'ar';
  String _searchQuery = '';
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);

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
        context.read<EmployeeCubit>().fetchEmployees(isSuperAdmin: true);
      } else if (authState.role == 'school') {
        selectedSchoolId = widget.schoolId ?? authState.uid;
        context.read<SchoolCubit>().fetchSchools(selectedSchoolId!, authState.role);
        context.read<EmployeeCubit>().fetchEmployees(schoolId: selectedSchoolId!, isSuperAdmin: false);
        context.read<SalaryCubit>().fetchSalaryCategories(selectedSchoolId!);
      } else if (authState.role == 'employee' && authState.schoolId != null) {
        selectedSchoolId = authState.schoolId;
        context.read<SchoolCubit>().fetchSchools(selectedSchoolId!, authState.role);
        context.read<EmployeeCubit>().fetchEmployees(schoolId: selectedSchoolId!, isSuperAdmin: false);
        context.read<SalaryCubit>().fetchSalaryCategories(selectedSchoolId!);
      }
    }
  }

  void _filterEmployees() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      if (authState.role == 'school' && selectedSchoolId != null) {
        context.read<EmployeeCubit>().fetchEmployees(
          schoolId: selectedSchoolId!,
          isSuperAdmin: false,
          department: selectedDepartment,
          subDepartment: selectedSubDepartment,
        );
      } else if (authState.role == 'employee' && authState.schoolId != null) {
        selectedSchoolId = authState.schoolId;
        context.read<EmployeeCubit>().fetchEmployees(
          schoolId: selectedSchoolId!,
          isSuperAdmin: false,
          department: selectedDepartment,
          subDepartment: selectedSubDepartment,
        );
      } else if (authState.role == 'admin') {
        if (selectedSchoolId != null) {
          context.read<EmployeeCubit>().fetchEmployees(
            schoolId: selectedSchoolId!,
            isSuperAdmin: true,
            department: selectedDepartment,
            subDepartment: selectedSubDepartment,
          );
        } else {
          context.read<EmployeeCubit>().fetchEmployees(isSuperAdmin: true);
        }
      }
    }
  }

  Future<void> _generateEmployeeNamesListPdf(List<Map<String, String>> employeeData) async {
    final pdf = pw.Document();
    final arabicFont = await pw.Font.ttf((await rootBundle.load('assets/fonts/Amiri-Regular.ttf')).buffer.asByteData());
    final frenchFont = await pw.Font.ttf((await rootBundle.load('assets/fonts/Amiri-Regular.ttf')).buffer.asByteData());
    final maliFlagImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/mali.png')).buffer.asUint8List(),
    );

    String schoolName = _selectedLanguage == 'ar' ? 'غير متوفر' : 'Non disponible';
    String department = _selectedLanguage == 'ar' ? 'غير محدد' : 'Non spécifié';
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
      if (selectedDepartment != null) {
        department = selectedDepartment!;
      } else if (employeeData.isNotEmpty) {
        department = _selectedLanguage == 'ar' ? employeeData[0]['departmentAr'] ?? 'غير محدد' : employeeData[0]['departmentFr'] ?? 'Non spécifié';
      }
    }

    if (employeeData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_selectedLanguage == 'ar' ? 'لا يوجد موظفين للطباعة' : 'Aucun employé à imprimer')),
      );
      _progressNotifier.value = 1.0;
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
          pw.Text(
          _selectedLanguage == 'ar' ? 'القسم: $department' : 'Département: $department',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(font: _selectedLanguage == 'ar' ? arabicFont : frenchFont, fontSize: 10),
          textDirection: _selectedLanguage == 'ar' ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          ),
          pw.SizedBox(height: 20),
          pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black),
          columnWidths: {
          0: pw.FixedColumnWidth(80), // Notes
          1: pw.FixedColumnWidth(80), // Department (Arabic)
          2: pw.FixedColumnWidth(80), // Department (French)
          3: pw.FixedColumnWidth(80), // Email
          4: pw.FixedColumnWidth(80), // Phone
          5: pw.FixedColumnWidth(80), // Name (Arabic)
          6: pw.FixedColumnWidth(80), // Name (French)
          },
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
          pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
          pw.Container(
          alignment: pw.Alignment.center,
          child: pw.Text(
          _selectedLanguage == 'ar' ? 'ملاحظات' : 'Notes',
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
          _selectedLanguage == 'ar' ? 'القسم (عربي)' : 'Département (Arabe)',
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
          _selectedLanguage == 'ar' ? 'القسم (فرنسي)' : 'Département (Français)',
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
          _selectedLanguage == 'ar' ? 'البريد' : 'Email',
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
          _selectedLanguage == 'ar' ? 'رقم الهاتف' : 'Téléphone',
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
          _selectedLanguage == 'ar' ? 'الاسم بالعربية' : 'Nom (Arabe)',
          style: pw.TextStyle(font: arabicFont, fontSize: 12, fontWeight: pw.FontWeight.bold),
          textDirection: pw.TextDirection.rtl,
          ),
          ),
          pw.Container(
          alignment: pw.Alignment.center,
          child: pw.Text(
          _selectedLanguage == 'ar' ? 'الاسم بالفرنسية' : 'Nom (Français)',
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
          ...employeeData.asMap().entries.map((entry) {
          final employee = entry.value;
          return pw.TableRow(
          children: [
          pw.Container(
          alignment: pw.Alignment.center,
          child: pw.Text(employee['notes'] ?? '', style: pw.TextStyle(font: frenchFont, fontSize: 10)),
          ),
          pw.Container(
          alignment: pw.Alignment.center,
          child: pw.Text(
          employee['departmentAr'] ?? 'غير محدد',
          style: pw.TextStyle(font: arabicFont, fontSize: 10),
          textDirection: pw.TextDirection.rtl,
          ),
          ),
          pw.Container(
          alignment: pw.Alignment.center,
          child: pw.Text(
          employee['departmentFr'] ?? 'Non spécifié',
          style: pw.TextStyle(font: frenchFont, fontSize: 10),
          ),
          ),
          pw.Container(
          alignment: pw.Alignment.center,
          child: pw.Text(employee['email'] ?? '', style: pw.TextStyle(font: frenchFont, fontSize: 10)),
          ),
          pw.Container(
          alignment: pw.Alignment.center,
          child: pw.Text(employee['phone'] ?? '', style: pw.TextStyle(font: frenchFont, fontSize: 10)),
          ),
          pw.Container(
          alignment: pw.Alignment.center,
          child: pw.Text(
          employee['fullNameAr'] ?? 'غير متوفر',
          style: pw.TextStyle(font: arabicFont, fontSize: 10),
          textDirection: pw.TextDirection.rtl,
          ),
          ),
          pw.Container(
          alignment: pw.Alignment.center,
          child: pw.Text(
          employee['fullNameFr'] ?? 'Non disponible',
          style: pw.TextStyle(font: frenchFont, fontSize: 10),
          ),
          ),
          ],
          );
          }).toList(),
          ],
          ),
          ]);
        },
      ),
    );

    final bytes = await pdf.save();
    final FileSaveLocation? fileSaveLocation = await getSaveLocation(suggestedName: 'employee_names_list.pdf');
    if (fileSaveLocation != null) {
      final file = File(fileSaveLocation.path);
      await file.writeAsBytes(bytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF generated successfully at: ${fileSaveLocation.path}'), duration: const Duration(seconds: 5)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save operation cancelled'), duration: Duration(seconds: 2)),
      );
    }
    _progressNotifier.value = 1.0;
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
          'قائمة الموظفين / Liste des employés',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: Colors.white),
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Création de la liste des noms...'),
                    content: ValueListenableBuilder<double>(
                      valueListenable: _progressNotifier,
                      builder: (context, value, child) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LinearProgressIndicator(value: value),
                            const SizedBox(height: 10),
                            Text('${(value * 100).toStringAsFixed(1)}% complet'),
                          ],
                        );
                      },
                    ),
                  );
                },
              );

              final state = context.read<EmployeeCubit>().state;
              final schoolState = context.read<SchoolCubit>().state;
              if (state is EmployeeLoaded && schoolState is SchoolsLoaded) {
                final employees = state.employees
                    .where((employee) =>
                (selectedSchoolId == null || employee.schoolId == selectedSchoolId) &&
                    (selectedDepartment == null ||
                        (_selectedLanguage == 'ar' ? employee.departmentAr : employee.departmentFr) == selectedDepartment) &&
                    (selectedSubDepartment == null ||
                        (_selectedLanguage == 'ar' ? employee.subDepartmentAr : employee.subDepartmentFr) ==
                            selectedSubDepartment))
                    .toList();
                final employeeData = employees.map((employee) {
                  return {
                    'fullNameFr': employee.fullNameFr ,
                    'fullNameAr': employee.fullNameAr ,
                    'phone': employee.phone,
                    'email': employee.email,
                    'departmentAr': employee.departmentAr ,
                    'departmentFr': employee.departmentFr ,

                  };
                }).toList();
                await _generateEmployeeNamesListPdf(employeeData);
                Navigator.of(context).pop();
              }
            },
          ),        ],
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
                          _buildSectionTitle('فلترة الموظفين / Filtrer les employés'),
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
                                  selectedDepartment = null;
                                  selectedSubDepartment = null;
                                  _filterEmployees();
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (selectedSchoolId != null) ...[
                            _buildDropdown(
                              label: 'القسم الرئيسي / Département principal',
                              value: selectedDepartment,
                              items: schools
                                  .firstWhere((school) => school.schoolId == selectedSchoolId)
                                  .mainSections[_selectedLanguage]!
                                  .map((dept) => DropdownMenuItem(value: dept, child: Text(dept)))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedDepartment = value;
                                  selectedSubDepartment = null;
                                  _filterEmployees();
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            if (selectedDepartment != null)
                              _buildDropdown(
                                label: 'القسم الفرعي / Sous-département',
                                value: selectedSubDepartment,
                                items: schools
                                    .firstWhere((school) => school.schoolId == selectedSchoolId)
                                    .subSections[_selectedLanguage]![selectedDepartment]!
                                    .map((subDept) => DropdownMenuItem(value: subDept, child: Text(subDept)))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedSubDepartment = value;
                                    _filterEmployees();
                                  });
                                },
                              ),
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
                    _buildSectionTitle('قائمة الموظفين / Liste des employés'),
                    TextField(
                      decoration: _buildInputDecoration('ابحث بالاسم أو المعرف / Rechercher par nom ou ID'),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<EmployeeCubit, EmployeeState>(
                      builder: (context, state) {
                        if (state is EmployeeLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (state is EmployeeLoaded) {
                          final filteredEmployees = state.employees.where((employee) {
                            final name = _selectedLanguage == 'ar' ? employee.fullNameAr : (employee.fullNameFr ?? '');
                            final dept = _selectedLanguage == 'ar' ? employee.departmentAr : (employee.departmentFr ?? '');
                            final subDept = _selectedLanguage == 'ar' ? employee.subDepartmentAr : (employee.subDepartmentFr ?? '');
                            return (employee.id.contains(_searchQuery) || name.contains(_searchQuery)) &&
                                (selectedSchoolId == null || employee.schoolId == selectedSchoolId) &&
                                (selectedDepartment == null || dept == selectedDepartment) &&
                                (selectedSubDepartment == null || subDept == selectedSubDepartment);
                          }).toList();

                          if (filteredEmployees.isEmpty) {
                            return const Center(child: Text('لا يوجد موظفون / Aucun employé trouvé'));
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
                            itemCount: filteredEmployees.length,
                            itemBuilder: (context, index) {
                              final employee = filteredEmployees[index];
                              return GestureDetector(
                                onTap: () {
                                  if (selectedSchoolId != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EmployeeDetailsScreen(
                                          employee: employee,
                                          schoolId: selectedSchoolId!,
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('يرجى اختيار مدرسة أولاً / Veuillez sélectionner une école d’abord'),
                                      ),
                                    );
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  child: Card(
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: CircleAvatar(
                                              radius: 35,
                                              backgroundImage: employee.profileImage != null
                                                  ? NetworkImage(employee.profileImage!)
                                                  : null,
                                              backgroundColor: Colors.grey.shade200,
                                              child: employee.profileImage == null
                                                  ? const Icon(Icons.person, size: 25, color: Colors.grey)
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _selectedLanguage == 'ar'
                                                ? employee.fullNameAr
                                                : (employee.fullNameFr ),
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
                                          Text(
                                            _selectedLanguage == 'ar'
                                                ? (employee.departmentAr ?? '')
                                                : (employee.departmentFr ?? ''),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Roboto',
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.phone, size: 16, color: Colors.blueAccent),
                                              const SizedBox(width: 4),
                                              Text(
                                                employee.phone,
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
                                                employee.email,
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