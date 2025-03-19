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
        // إذا كان المستخدم admin، جلب جميع المدارس وجميع الطلاب
        context.read<SchoolCubit>().fetchSchools(authState.uid, authState.role);
        context.read<StudentCubit>().fetchAllStudents();
      } else if (authState.role == 'school') {
        // إذا كان المستخدم مدرسة، استخدم uid أو schoolId الممرر كـ selectedSchoolId
        selectedSchoolId = widget.schoolId ?? authState.uid;
        context.read<SchoolCubit>().fetchSchools(selectedSchoolId!, authState.role);
        context.read<StudentCubit>().fetchStudents(schoolId: selectedSchoolId!, language: _selectedLanguage);
      } else if (authState.role == 'employee') {
        // إذا كان المستخدم موظفًا، استخدم schoolId من حالة المصادقة
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
    final font = await PdfGoogleFonts.robotoRegular(); // خط فرنسي
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

    // بناء البطاقة
    pw.Widget buildCard(int index) {
      final student = studentData[index];
      return pw.Container(
        width: (PdfPageFormat.a4.width - 80) / 2, // تقليل العرض قليلاً مع هامش إضافي
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

    final int cardsPerPage = 8; // 4 صفوف، كل صف يحتوي على بطاقتين
    for (int pageIndex = 0; pageIndex < (studentData.length / cardsPerPage).ceil(); pageIndex++) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20), // هامش خارجي للصفحة
          build: (pw.Context context) {
            List<pw.Widget> rows = [];
            for (var i = pageIndex * cardsPerPage; i < (pageIndex + 1) * cardsPerPage && i < studentData.length; i += 2) {
              final leftCard = buildCard(i);
              final rightCard = (i + 1 < studentData.length && i + 1 < (pageIndex + 1) * cardsPerPage)
                  ? buildCard(i + 1)
                  : pw.SizedBox(width: (PdfPageFormat.a4.width - 80) / 2); // مساحة فارغة إذا لم تكن هناك بطاقة ثانية

              rows.add(
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center, // توسيط البطاقات في الصف
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
          mainSections: {'fr': [], 'ar': []}, // إضافة mainSections
          subSections: {'fr': {}, 'ar': {}},   // إضافة subSections
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
    double height = 80; // تقليل الارتفاع الأساسي لتناسب بطاقتين
    final dataLines = [
      'C.A.P de : ${student['addressFr'] ?? 'Non disponible'}',
      'École : ${student['schoolNameFr'] ?? 'Non disponible'}',
      'ID : ${student['id'] ?? 'Non disponible'}',
      'Nom : ${student['firstNameFr'] ?? 'Non disponible'}',
      'Prénoms : ${student['lastNameFr'] ?? 'Non disponible'}',
      'Né(e) le : ${student['birthDate'] ?? 'Non disponible'}',
      'Classe : ${student['gradeFr'] ?? 'Non disponible'}',
    ];
    const double lineHeight = 10; // تقليل ارتفاع السطر لتناسب التصميم
    height += dataLines.length * lineHeight;
    height += 20; // تقليل الهامش الإضافي
    return height;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('يرجى تسجيل الدخول / Veuillez vous connecter')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الطلاب / Liste des étudiants', style: TextStyle(color: Colors.white)),
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
                      mainSections: {'fr': [], 'ar': []}, // إضافة mainSections
                      subSections: {'fr': {}, 'ar': {}},   // إضافة subSections
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
                    'schoolName': school.schoolName[_selectedLanguage] ?? 'غير متوفر', // لكشف الأسماء
                    'schoolNameFr': school.schoolName['fr'] ?? 'Non disponible', // لكروت الطلاب
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
                      mainSections: {'fr': [], 'ar': []}, // Added required mainSections
                      subSections: {'fr': {}, 'ar': {}},   // Added required subSections
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
                    'schoolName': school.schoolName[_selectedLanguage] ?? 'غير متوفر', // لكشف الأسماء
                    'schoolNameFr': school.schoolName['fr'] ?? 'Non disponible', // لكروت الطلاب
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
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
                  ),
                ],
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
                      final schools = schoolState.schools;
                      if (authState.role == 'school' && schools.isNotEmpty) {
                        selectedSchoolId ??= widget.schoolId ?? authState.uid;
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
                    _buildSectionTitle('قائمة الطلاب / Liste des étudiants'),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: _selectedLanguage == 'ar' ? 'ابحث بالاسم أو المعرف' : 'Rechercher par nom ou ID',
                          prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.blueAccent),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    BlocBuilder<StudentCubit, StudentState>(
                      builder: (context, state) {
                        if (state is StudentLoading) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (state is StudentsLoaded) {
                          final students = state.students
                              .where((student) =>
                          (selectedSchoolId == null || student.schoolId == selectedSchoolId) &&
                              (selectedGrade == null ||
                                  (_selectedLanguage == 'ar' ? student.gradeAr : student.gradeFr) == selectedGrade) &&
                              (selectedSection == null ||
                                  (_selectedLanguage == 'ar' ? student.sectionAr : student.sectionFr) == selectedSection) &&
                              (_searchQuery.isEmpty ||
                                  student.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                  '${student.firstNameAr} ${student.lastNameAr}'
                                      .toLowerCase()
                                      .contains(_searchQuery.toLowerCase()) ||
                                  '${student.firstNameFr} ${student.lastNameFr}'
                                      .toLowerCase()
                                      .contains(_searchQuery.toLowerCase())))
                              .toList();

                          if (students.isEmpty) {
                            return Center(
                                child: Text(_selectedLanguage == 'ar' ? 'لا يوجد طلاب' : 'Aucun étudiant trouvé'));
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: (students.length / 3).ceil(),
                            itemBuilder: (context, index) {
                              final startIndex = index * 3;
                              final endIndex = (startIndex + 3 < students.length) ? startIndex + 3 : students.length;
                              final rowStudents = students.sublist(startIndex, endIndex);

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: rowStudents.asMap().entries.map((entry) {
                                    final student = entry.value;
                                    final isLast = entry.key == rowStudents.length - 1;

                                    return Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [Colors.blueAccent.shade100, Colors.white],
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                ),
                                                borderRadius: BorderRadius.circular(15),
                                              ),
                                              child: InkWell(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => StudentDetailsScreen(
                                                        studentId: student.id,
                                                        schoolId: student.schoolId,
                                                      ),
                                                    ),
                                                  ).then((_) {
                                                    _loadInitialData();
                                                  });
                                                },
                                                borderRadius: BorderRadius.circular(15),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(12),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: [
                                                      student.profileImage != null
                                                          ? ClipRRect(
                                                        borderRadius: BorderRadius.circular(10),
                                                        child: Image.network(
                                                          student.profileImage!,
                                                          width: 80,
                                                          height: 80,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      )
                                                          : Container(
                                                        width: 80,
                                                        height: 80,
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(10),
                                                          color: Colors.grey[200],
                                                        ),
                                                        child: const Icon(Icons.person, size: 40, color: Colors.grey),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        _selectedLanguage == 'ar'
                                                            ? '${student.firstNameAr} ${student.lastNameAr}'
                                                            : '${student.firstNameFr} ${student.lastNameFr}',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.blueAccent,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      _buildInfoRow(
                                                          _selectedLanguage == 'ar' ? 'المعرف' : 'ID', student.id),
                                                      _buildInfoRow(
                                                          _selectedLanguage == 'ar' ? 'الاسم الأول' : 'Prénom',
                                                          _selectedLanguage == 'ar' ? student.firstNameAr : student.firstNameFr),
                                                      _buildInfoRow(
                                                          _selectedLanguage == 'ar' ? 'الصف' : 'Classe',
                                                          _selectedLanguage == 'ar' ? student.gradeAr : student.gradeFr),
                                                      _buildInfoRow(
                                                          _selectedLanguage == 'ar' ? 'الشعبة' : 'Section',
                                                          _selectedLanguage == 'ar' ? student.sectionAr : student.sectionFr),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (!isLast) const SizedBox(width: 16),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          );
                        }
                        return const Center(child: Text('خطأ في تحميل الطلاب / Erreur lors du chargement des étudiants'));
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blueAccent, width: 2),
          ),
          child: DropdownButton<String>(
            value: value,
            hint: Text('اختر $label / Choisir $label', style: const TextStyle(color: Colors.blueAccent)),
            onChanged: onChanged,
            items: items,
            style: const TextStyle(color: Colors.blueAccent),
            dropdownColor: Colors.white,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
          ),
        ),
      ],
    );
  }
}