import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:file_selector/file_selector.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:school_management_dashboard/cubit/auth/auth_cubit.dart';
import 'package:school_management_dashboard/cubit/auth/auth_state.dart';
import 'package:school_management_dashboard/cubit/school_info/school_info_cubit.dart';
import 'package:school_management_dashboard/cubit/school_info/school_info_state.dart';
import 'package:school_management_dashboard/cubit/student/student_cubit.dart';
import 'package:school_management_dashboard/cubit/student/student_state.dart';
import 'package:school_management_dashboard/screens/student/student_details_screen.dart';
import '../../models/school_info_model.dart';
import '../../models/student_model.dart';

class StudentListScreen extends StatefulWidget {
  final String? schoolId;

  const StudentListScreen({this.schoolId});

  @override
  _StudentListScreenState createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  String? selectedSchoolId;
  String? selectedGrade;
  String? selectedSection;
  String _selectedLanguage = 'ar'; // الافتراضي العربية
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
        context.read<StudentCubit>().fetchAllStudents();
      } else if (authState.role == 'school') {
        selectedSchoolId = widget.schoolId ?? authState.uid;
        context.read<SchoolCubit>().fetchSchools(selectedSchoolId!, authState.role);
        context.read<StudentCubit>().fetchStudents(schoolId: selectedSchoolId!, language: _selectedLanguage);
      } else if (authState.role == 'employee') {
        selectedSchoolId = authState.schoolId;
        if (selectedSchoolId != null) {
          context.read<SchoolCubit>().fetchSchools(selectedSchoolId!, 'school');
          context.read<StudentCubit>().fetchStudents(schoolId: selectedSchoolId!, language: _selectedLanguage);
        }
      }
    }
  }

  void _filterStudents() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      if (selectedSchoolId != null) {
        context.read<StudentCubit>().fetchStudents(
          schoolId: selectedSchoolId!,
          grade: selectedGrade,
          section: selectedSection,
          language: _selectedLanguage,
        );
      } else if (authState.role == 'admin') {
        context.read<StudentCubit>().fetchAllStudents();
      }
    }
  }

  Future<void> _generateAndSavePdf(List<Map<String, String>> studentData) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final maliFlagImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/mali.png')).buffer.asUint8List(),
    );

    final List<pw.MemoryImage?> studentImages = [];
    for (var i = 0; i < studentData.length; i++) {
      final student = studentData[i];
      if (student['profileImage'] != null && student['profileImage']!.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(student['profileImage']!));
          if (response.statusCode == 200) {
            studentImages.add(pw.MemoryImage(response.bodyBytes));
          } else {
            studentImages.add(null);
          }
        } catch (e) {
          studentImages.add(null);
        }
      } else {
        studentImages.add(null);
      }
      _progressNotifier.value = (i + 1) / studentData.length * 0.5;
    }

    final List<pw.MemoryImage?> signatureImages = [];
    for (var i = 0; i < studentData.length; i++) {
      final student = studentData[i];
      if (student['principalSignatureUrl'] != null && student['principalSignatureUrl']!.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(student['principalSignatureUrl']!));
          if (response.statusCode == 200) {
            signatureImages.add(pw.MemoryImage(response.bodyBytes));
          } else {
            signatureImages.add(null);
          }
        } catch (e) {
          signatureImages.add(null);
        }
      } else {
        signatureImages.add(null);
      }
      _progressNotifier.value = 0.5 + (i + 1) / studentData.length * 0.5;
    }

    pw.Widget buildCard(int index) {
      final student = studentData[index];
      return pw.Container(
        width: (PdfPageFormat.a4.width - 80) / 2,
        height: _calculateCardHeight(student),
        margin: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.blue, width: 1),
          borderRadius: pw.BorderRadius.circular(5),
          color: PdfColors.grey300,
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 80,
              height: _calculateCardHeight(student) - 16,
              child: studentImages[index] != null
                  ? pw.Image(studentImages[index]!, fit: pw.BoxFit.fitWidth)
                  : pw.Container(
                color: PdfColors.grey300,
                child: pw.Center(
                  child: pw.Icon(const pw.IconData(0xe853), size: 30, color: PdfColors.black),
                ),
              ),
            ),
            pw.SizedBox(width: 5),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Image(maliFlagImage, width: 20, height: 15),
                      pw.SizedBox(width: 3),
                      pw.Text(
                        'RÉPUBLIQUE DU MALI',
                        style: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'UN PEUPLE - UN BUT - UNE FOI',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(font: font, fontSize: 6),
                  ),
                  pw.Text(
                    'CARTE D\'IDENTITÉ SCOLAIRE 2025',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(font: font, fontSize: 8, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('C.A.P de : ${student['addressFr'] ?? 'Non disponible'}', style: pw.TextStyle(font: font, fontSize: 9)),
                  pw.Text('École : ${student['schoolNameFr'] ?? 'Non disponible'}', style: pw.TextStyle(font: font, fontSize: 9)),
                  pw.Text('ID : ${student['id'] ?? 'Non disponible'}', style: pw.TextStyle(font: font, fontSize: 9)),
                  pw.Text('Nom : ${student['firstNameFr'] ?? 'Non disponible'}', style: pw.TextStyle(font: font, fontSize: 9)),
                  pw.Text('Prénoms : ${student['lastNameFr'] ?? 'Non disponible'}', style: pw.TextStyle(font: font, fontSize: 9)),
                  pw.Text('Né(e) le : ${student['birthDate'] ?? 'Non disponible'}', style: pw.TextStyle(font: font, fontSize: 9)),
                  pw.Text('Classe : ${student['gradeFr'] ?? 'Non disponible'}', style: pw.TextStyle(font: font, fontSize: 9)),
                ],
              ),
            ),
            pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Directeur : ${student['principalName'] ?? 'Non disponible'}', style: pw.TextStyle(font: font, fontSize: 7)),
                signatureImages[index] != null
                    ? pw.Image(signatureImages[index]!, width: 40, height: 15, fit: pw.BoxFit.cover)
                    : pw.SizedBox(height: 15),
              ],
            ),
          ],
        ),
      );
    }

    final int cardsPerPage = 8;
    for (int pageIndex = 0; pageIndex < (studentData.length / cardsPerPage).ceil(); pageIndex++) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            List<pw.Widget> rows = [];
            for (var i = pageIndex * cardsPerPage; i < (pageIndex + 1) * cardsPerPage && i < studentData.length; i += 2) {
              final leftCard = buildCard(i);
              final rightCard = (i + 1 < studentData.length && i + 1 < (pageIndex + 1) * cardsPerPage)
                  ? buildCard(i + 1)
                  : pw.SizedBox(width: (PdfPageFormat.a4.width - 80) / 2);

              rows.add(
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [leftCard, rightCard],
                ),
              );
            }
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: rows,
            );
          },
        ),
      );
      _progressNotifier.value = 0.8 + (pageIndex + 1) / (studentData.length / cardsPerPage).ceil() * 0.2;
    }

    final bytes = await pdf.save();
    final FileSaveLocation? fileSaveLocation = await getSaveLocation(suggestedName: 'student_cards.pdf');
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

  Future<void> _generateNamesListPdf(List<Map<String, String>> studentData) async {
    final pdf = pw.Document();
    final arabicFont = await pw.Font.ttf((await rootBundle.load('assets/fonts/Amiri-Regular.ttf')).buffer.asByteData());
    final frenchFont = await PdfGoogleFonts.robotoRegular();
    final maliFlagImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/mali.png')).buffer.asUint8List(),
    );

    String schoolName = _selectedLanguage == 'ar' ? 'غير متوفر' : 'Non disponible';
    String grade = _selectedLanguage == 'ar' ? 'غير محدد' : 'Non spécifié';
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
      if (selectedGrade != null) {
        grade = selectedGrade!;
      } else if (studentData.isNotEmpty) {
        grade = _selectedLanguage == 'ar' ? studentData[0]['gradeAr'] ?? 'غير محدد' : studentData[0]['gradeFr'] ?? 'Non spécifié';
      }
    }

    if (studentData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_selectedLanguage == 'ar' ? 'لا يوجد طلاب للطباعة' : 'Aucun étudiant à imprimer')),
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
                _selectedLanguage == 'ar' ? 'الصف: $grade' : 'Classe: $grade',
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
                  4: pw.FixedColumnWidth(30),
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
                          _selectedLanguage == 'ar' ? 'الاسم بالفرنسية' : 'Nom',
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
                          'ID',
                          style: pw.TextStyle(font: frenchFont, fontSize: 12, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          '#',
                          style: pw.TextStyle(font: frenchFont, fontSize: 12, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  ...studentData.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final student = entry.value;
                    return pw.TableRow(
                      children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text('', style: pw.TextStyle(font: frenchFont, fontSize: 10)),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            '${student['firstNameFr'] ?? 'Non disponible'} ${student['lastNameFr'] ?? ''}',
                            style: pw.TextStyle(font: frenchFont, fontSize: 10),
                          ),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            '${student['firstNameAr'] ?? 'غير متوفر'} ${student['lastNameAr'] ?? ''}',
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(student['id'] ?? '', style: pw.TextStyle(font: frenchFont, fontSize: 10)),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text('$index', style: pw.TextStyle(font: frenchFont, fontSize: 10)),
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
    final FileSaveLocation? fileSaveLocation = await getSaveLocation(suggestedName: 'student_names_list.pdf');
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

  double _calculateCardHeight(Map<String, String> student) {
    double height = 80;
    final dataLines = [
      'C.A.P de : ${student['addressFr'] ?? 'Non disponible'}',
      'École : ${student['schoolNameFr'] ?? 'Non disponible'}',
      'ID : ${student['id'] ?? 'Non disponible'}',
      'Nom : ${student['firstNameFr'] ?? 'Non disponible'}',
      'Prénoms : ${student['lastNameFr'] ?? 'Non disponible'}',
      'Né(e) le : ${student['birthDate'] ?? 'Non disponible'}',
      'Classe : ${student['gradeFr'] ?? 'Non disponible'}',
    ];
    const double lineHeight = 10;
    height += dataLines.length * lineHeight;
    height += 20;
    return height;
  }

  void _confirmDelete(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(_selectedLanguage == 'ar' ? 'تأكيد الحذف' : 'Confirmer la suppression'),
          content: Text(_selectedLanguage == 'ar'
              ? 'هل أنت متأكد من حذف الطالب ${student.firstNameAr} ${student.lastNameAr}؟'
              : 'Êtes-vous sûr de vouloir supprimer l\'étudiant ${student.firstNameFr} ${student.lastNameFr} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_selectedLanguage == 'ar' ? 'إلغاء' : 'Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _deleteStudent(context, student);
              },
              child: Text(_selectedLanguage == 'ar' ? 'حذف' : 'Supprimer', style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteStudent(BuildContext context, Student student) async {
    try {
       context.read<StudentCubit>().deleteStudent(
        schoolId: student.schoolId,
        studentId: student.id,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_selectedLanguage == 'ar' ? 'تم حذف الطالب بنجاح' : 'Étudiant supprimé avec succès'),
        ),
      );
      _loadInitialData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_selectedLanguage == 'ar' ? 'فشل في حذف الطالب: $e' : 'Échec de la suppression: $e'),
        ),
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
          'قائمة الطلاب / Liste des étudiants',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Création de un fichier PDF...'),
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

              final state = context.read<StudentCubit>().state;
              final schoolState = context.read<SchoolCubit>().state;
              if (state is StudentsLoaded && schoolState is SchoolsLoaded) {
                final students = state.students
                    .where((student) =>
                (selectedSchoolId == null || student.schoolId == selectedSchoolId) &&
                    (selectedGrade == null || (_selectedLanguage == 'ar' ? student.gradeAr : student.gradeFr) == selectedGrade) &&
                    (selectedSection == null || (_selectedLanguage == 'ar' ? student.sectionAr : student.sectionFr) == selectedSection))
                    .toList();
                final schools = schoolState.schools;
                final studentData = students.map((student) {
                  final school = schools.firstWhere(
                        (school) => school.schoolId == student.schoolId,
                    orElse: () => Schoolinfo(
                      schoolId: student.schoolId,
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
                  return {
                    'id': student.id,
                    'firstNameFr': student.firstNameFr ?? '',
                    'lastNameFr': student.lastNameFr ?? '',
                    'firstNameAr': student.firstNameAr ?? '',
                    'lastNameAr': student.lastNameAr ?? '',
                    'gradeFr': student.gradeFr ?? '',
                    'gradeAr': student.gradeAr ?? '',
                    'sectionFr': student.sectionFr ?? '',
                    'sectionAr': student.sectionAr ?? '',
                    'schoolName': school.schoolName[_selectedLanguage] ?? 'غير متوفر',
                    'schoolNameFr': school.schoolName['fr'] ?? 'Non disponible',
                    'addressFr': school.address['fr'] ?? 'Non disponible',
                    'birthDate': student.birthDate ?? '',
                    'profileImage': student.profileImage ?? '',
                    'principalName': school.principalName['fr'] ?? 'غير متوفر',
                    'principalSignatureUrl': school.principalSignatureUrl ?? '',
                  };
                }).toList();

                await _generateAndSavePdf(studentData);
                Navigator.of(context).pop();
              }
            },
          ),
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

              final state = context.read<StudentCubit>().state;
              final schoolState = context.read<SchoolCubit>().state;
              if (state is StudentsLoaded && schoolState is SchoolsLoaded) {
                final students = state.students
                    .where((student) =>
                (selectedSchoolId == null || student.schoolId == selectedSchoolId) &&
                    (selectedGrade == null || (_selectedLanguage == 'ar' ? student.gradeAr : student.gradeFr) == selectedGrade) &&
                    (selectedSection == null || (_selectedLanguage == 'ar' ? student.sectionAr : student.sectionFr) == selectedSection))
                    .toList();
                final schools = schoolState.schools;
                final studentData = students.map((student) {
                  final school = schools.firstWhere(
                        (school) => school.schoolId == student.schoolId,
                    orElse: () => Schoolinfo(
                      schoolId: student.schoolId,
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
                  return {
                    'id': student.id,
                    'firstNameFr': student.firstNameFr ?? '',
                    'lastNameFr': student.lastNameFr ?? '',
                    'firstNameAr': student.firstNameAr ?? '',
                    'lastNameAr': student.lastNameAr ?? '',
                    'gradeFr': student.gradeFr ?? '',
                    'gradeAr': student.gradeAr ?? '',
                    'sectionFr': student.sectionFr ?? '',
                    'sectionAr': student.sectionAr ?? '',
                    'schoolName': school.schoolName[_selectedLanguage] ?? 'غير متوفر',
                    'schoolNameFr': school.schoolName['fr'] ?? 'Non disponible',
                    'addressFr': school.address['fr'] ?? 'Non disponible',
                    'birthDate': student.birthDate ?? '',
                    'profileImage': student.profileImage ?? '',
                    'principalName': school.principalName['fr'] ?? 'غير متوفر',
                    'principalSignatureUrl': school.principalSignatureUrl ?? '',
                  };
                }).toList();
                await _generateNamesListPdf(studentData);
                Navigator.of(context).pop();
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
                      if (selected) {
                        setState(() {
                          _selectedLanguage = 'ar';
                          _resetSelectionsIfInvalid();
                          _filterStudents();
                        });
                      }
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
                      if (selected) {
                        setState(() {
                          _selectedLanguage = 'fr';
                          _resetSelectionsIfInvalid();
                          _filterStudents();
                        });
                      }
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
                          _buildSectionTitle('فلترة الطلاب / Filtrer les étudiants'),
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
                                  selectedGrade = null;
                                  selectedSection = null;
                                  _filterStudents();
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (selectedSchoolId != null) ...[
                            _buildDropdown(
                              label: 'الصف / Classe',
                              value: selectedGrade,
                              items: schools
                                  .firstWhere((school) => school.schoolId == selectedSchoolId)
                                  .classes[_selectedLanguage]!
                                  .map((grade) => DropdownMenuItem(value: grade, child: Text(grade)))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedGrade = value;
                                  selectedSection = null;
                                  _filterStudents();
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            if (selectedGrade != null)
                              _buildDropdown(
                                label: 'الشعبة / Section',
                                value: selectedSection,
                                items: schools
                                    .firstWhere((school) => school.schoolId == selectedSchoolId)
                                    .sections[_selectedLanguage]![selectedGrade]!
                                    .map((section) => DropdownMenuItem(value: section, child: Text(section)))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedSection = value;
                                    _filterStudents();
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
                    _buildSectionTitle('قائمة الطلاب / Liste des étudiants'),
                    TextField(
                      decoration: _buildInputDecoration('ابحث بالاسم أو المعرف / Rechercher par nom ou ID'),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<StudentCubit, StudentState>(
                      builder: (context, state) {
                        if (state is StudentLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (state is StudentsLoaded) {
                          final filteredStudents = state.students.where((student) {
                            final name = _selectedLanguage == 'ar'
                                ? '${student.firstNameAr} ${student.lastNameAr}'
                                : '${student.firstNameFr} ${student.lastNameFr}';
                            final grade = _selectedLanguage == 'ar' ? student.gradeAr : student.gradeFr;
                            final section = _selectedLanguage == 'ar' ? student.sectionAr : student.sectionFr;
                            return (student.id.contains(_searchQuery) || name.contains(_searchQuery)) &&
                                (selectedSchoolId == null || student.schoolId == selectedSchoolId) &&
                                (selectedGrade == null || grade == selectedGrade) &&
                                (selectedSection == null || section == selectedSection);
                          }).toList();

                          if (filteredStudents.isEmpty) {
                            return const Center(child: Text('لا يوجد طلاب / Aucun étudiant trouvé'));
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
                            itemCount: filteredStudents.length,
                            itemBuilder: (context, index) {
                              final student = filteredStudents[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StudentDetailsScreen(
                                        studentId: student.id,
                                        schoolId: student.schoolId,
                                      ),
                                    ),
                                  ).then((_) => _loadInitialData());
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

  children: [
    IconButton(
  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
  onPressed: () => _confirmDelete(context, student),
),],),
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
                                                  radius: 50,
                                                  backgroundImage: student.profileImage != null
                                                      ? NetworkImage(student.profileImage!)
                                                      : null,
                                                  backgroundColor: Colors.grey.shade200,
                                                  child: student.profileImage == null
                                                      ? const Icon(Icons.person, size: 25, color: Colors.grey)
                                                      : null,
                                                ),
                                              ),

                                          const SizedBox(height: 8),
                                          Text(
                                            _selectedLanguage == 'ar'
                                                ? '${student.firstNameAr} ${student.lastNameAr}'
                                                : '${student.firstNameFr} ${student.lastNameFr}',
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
                                            _selectedLanguage == 'ar' ? student.gradeAr : student.gradeFr ?? '',
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
                                              const Icon(Icons.perm_identity, size: 16, color: Colors.blueAccent),
                                              const SizedBox(width: 4),
                                              Text(
                                                student.id,
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
                                              const Icon(Icons.class_, size: 16, color: Colors.blueAccent),
                                              const SizedBox(width: 4),
                                              Text(
                                                _selectedLanguage == 'ar' ? student.sectionAr : student.sectionFr ?? '',
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

  void _resetSelectionsIfInvalid() {
    final schoolState = context.read<SchoolCubit>().state;
    if (schoolState is SchoolsLoaded && selectedSchoolId != null) {
      final selectedSchool = schoolState.schools.firstWhere((school) => school.schoolId == selectedSchoolId);
      final availableGrades = selectedSchool.classes[_selectedLanguage]!;
      if (selectedGrade != null && !availableGrades.contains(selectedGrade)) {
        selectedGrade = null;
        selectedSection = null;
      } else if (selectedGrade != null && selectedSection != null) {
        final availableSections = selectedSchool.sections[_selectedLanguage]![selectedGrade]!;
        if (!availableSections.contains(selectedSection)) {
          selectedSection = null;
        }
      }
    }
  }
}