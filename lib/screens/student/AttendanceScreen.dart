import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:google_fonts/google_fonts.dart' as gf;
import 'package:printing/printing.dart';
import 'package:school_management_dashboard/firebase_services/school_info_firebase_services.dart';

import '../../cubit/auth/auth_cubit.dart';
import '../../cubit/auth/auth_state.dart';
import '../../cubit/school_info/school_info_cubit.dart';
import '../../cubit/school_info/school_info_state.dart';
import '../../cubit/student/student_cubit.dart';
import '../../cubit/student/student_state.dart';
import '../../models/school_info_model.dart'; // Import Schoolinfo model
import 'dart:io';

import '../../models/student_model.dart';

class AttendanceManagementScreen extends StatefulWidget {
  final String? schoolId;

  const AttendanceManagementScreen({this.schoolId});

  @override
  _AttendanceManagementScreenState createState() => _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState extends State<AttendanceManagementScreen> {
  String? selectedSchoolId;
  String? selectedGrade;
  DateTime selectedDate = DateTime.now();
  String get formattedDate => DateFormat('yyyy-MM-dd').format(selectedDate);

  final SchoolFirebaseServices _schoolFirebaseServices = SchoolFirebaseServices();

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      if (authState.role == 'school') {
        selectedSchoolId = widget.schoolId ?? authState.uid;
        context.read<StudentCubit>().streamStudents(schoolId: selectedSchoolId!);
      } else {
        context.read<SchoolCubit>().fetchSchools(authState.uid, authState.role);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _generateAttendancePdf(List<Student> students) async {
    final pdf = pw.Document();
    final arabicFont = pw.Font.ttf((await DefaultAssetBundle.of(context).load('assets/fonts/Amiri-Regular.ttf')).buffer.asByteData());
    final font = await PdfGoogleFonts.robotoRegular();
    final maliFlagImage = pw.MemoryImage(
      (await DefaultAssetBundle.of(context).load('assets/images/mali.png')).buffer.asUint8List(),
    );

    // Fetch school name using schoolId from the first student
    String schoolNameAR = 'غير متوفر';
    String schoolNameFR = 'غير متوفر';

    if (students.isNotEmpty) {
      final schoolInfo = await _schoolFirebaseServices.getSchoolInfo(students[0].schoolId);
      schoolNameAR = schoolInfo?.schoolName['ar'] ?? 'غير متوفر';
      schoolNameFR = schoolInfo?.schoolName['fr'] ?? 'غير متوفر';

    }

    final grade = selectedGrade ?? (students.isNotEmpty ? students[0].gradeFr ?? '6ème Année' : '6ème Année');

    // Sort students alphabetically by firstNameAr
    students.sort((a, b) => a.firstNameAr.compareTo(b.firstNameAr));

    // Generate dates for the 7 days starting from selectedDate
    List<String> weekDates = [];
    for (int i = 0; i < 7; i++) {
      final date = selectedDate.add(Duration(days: i));
      weekDates.add(DateFormat('dd/MM').format(date));
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
                      style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Un Peuple-Un But-Une Foi',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: font, fontSize: 8),
                ),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      schoolNameAR,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: arabicFont, fontSize: 10),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.Text(' / '),
                    pw.Text(
                      schoolNameFR,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: arabicFont, fontSize: 10),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ]
                ),

                pw.SizedBox(height: 20),
                pw.Text(
                  'كشف الحضور والغياب',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: arabicFont, fontSize: 14, fontWeight: pw.FontWeight.bold),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.Text(
                  'LISTE DES ÉLÈVES $grade',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black),
                  columnWidths: {
                    0: pw.FixedColumnWidth(30),  // #
                    1: pw.FixedColumnWidth(150), // الاسم
                    2: pw.FixedColumnWidth(150), // Nom
                    3: pw.FixedColumnWidth(30),  // Day 1
                    4: pw.FixedColumnWidth(30),  // Day 2
                    5: pw.FixedColumnWidth(30),  // Day 3
                    6: pw.FixedColumnWidth(30),  // Day 4
                    7: pw.FixedColumnWidth(30),  // Day 5
                    8: pw.FixedColumnWidth(30),  // Day 6
                    9: pw.FixedColumnWidth(30),  // Day 7
                  },
                  defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text('#', style: pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            'الاسم',
                            style: pw.TextStyle(font: arabicFont, fontSize: 12, fontWeight: pw.FontWeight.bold),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text('Nom', style: pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        ),
                        ...weekDates.map((date) => pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(date, style: pw.TextStyle(font: font, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        )).toList(),
                      ],
                    ),
                    ...students.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final student = entry.value;
                      return pw.TableRow(
                        children: [
                          pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text('$index', style: pw.TextStyle(font: font, fontSize: 10)),
                          ),
                          pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              '${student.firstNameAr} ${student.lastNameAr}',
                              style: pw.TextStyle(font: arabicFont, fontSize: 10),
                              textDirection: pw.TextDirection.rtl,
                            ),
                          ),
                          pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              '${student.firstNameFr} ${student.lastNameFr}',
                              style: pw.TextStyle(font: font, fontSize: 10),
                            ),
                          ),
                          ...List.generate(7, (i) => pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text('', style: pw.TextStyle(font: font, fontSize: 10)),
                          )),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            );
          },
        ));

        final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/attendance_list_$grade.pdf');
    await file.writeAsBytes(await pdf.save());
    OpenFile.open(file.path);
  }
  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('يرجى تسجيل الدخول / Veuillez vous connecter')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الحضور / Gestion de la présence', style: TextStyle(color: Colors.white)),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    _buildSectionTitle('اختيار التاريخ / Sélectionner la date'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('التاريخ: $formattedDate / Date: $formattedDate',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => _selectDate(context),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('اختر تاريخ / Choisir une date'),
                        ),
                      ],
                    ),
                    if (authState.role == 'admin') ...[
                      const SizedBox(height: 16),
                      BlocBuilder<SchoolCubit, SchoolState>(
                        builder: (context, schoolState) {
                          if (schoolState is SchoolsLoaded) {
                            return DropdownButtonFormField<String>(
                              decoration: _buildInputDecoration('المدرسة / École'),
                              value: selectedSchoolId,
                              items: schoolState.schools.map((school) {
                                return DropdownMenuItem(
                                  value: school.schoolId,
                                  child: Text(school.schoolName['ar'] ?? ''),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedSchoolId = value;
                                  selectedGrade = null; // Reset grade when school changes
                                  if (value != null) {
                                    context.read<StudentCubit>().streamStudents(schoolId: value);
                                  }
                                });
                              },
                              validator: (value) => value == null ? 'مطلوب' : null,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 16),
                      BlocBuilder<StudentCubit, StudentState>(
                        builder: (context, state) {
                          if (state is StudentsLoaded && state.students.isNotEmpty) {
                            // Extract unique grades from students
                            final grades = state.students.map((student) => student.gradeFr).toSet().toList();
                            return DropdownButtonFormField<String>(
                              decoration: _buildInputDecoration('الصف / Classe'),
                              value: selectedGrade,
                              items: grades.map((grade) {
                                return DropdownMenuItem(
                                  value: grade,
                                  child: Text(grade ?? 'غير محدد'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedGrade = value;
                                });
                              },
                              validator: (value) => value == null ? 'مطلوب' : null,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    BlocBuilder<StudentCubit, StudentState>(
                      builder: (context, state) {
                        if (state is StudentsLoaded && state.students.isNotEmpty) {
                          final filteredStudents = selectedGrade != null
                              ? state.students.where((student) => student.gradeFr == selectedGrade).toList()
                              : state.students;
                          return ElevatedButton(
                            onPressed: () => _generateAttendancePdf(filteredStudents),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('طباعة كشف الحضور / Imprimer la liste de présence'),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
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
                child: BlocBuilder<StudentCubit, StudentState>(
                  builder: (context, state) {
                    if (state is StudentLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is StudentsLoaded) {
                      final filteredStudents = selectedGrade != null
                          ? state.students.where((student) => student.gradeFr == selectedGrade).toList()
                          : state.students;
                      if (filteredStudents.isEmpty) {
                        return const Center(child: Text('لا يوجد طلاب / Aucun étudiant'));
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('قائمة الطلاب / Liste des étudiants'),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredStudents.length,
                            itemBuilder: (context, index) {
                              final student = filteredStudents[index];
                              String attendance = student.attendanceHistory?[formattedDate] ?? 'غير محدد';
                              return Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Colors.blueAccent.shade100,
                                        child: student.profileImage != null
                                            ? ClipOval(
                                            child: Image.network(student.profileImage!,
                                                width: 60, height: 60, fit: BoxFit.cover))
                                            : const Icon(Icons.person, size: 30, color: Colors.blueAccent),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('${student.firstNameAr} ${student.lastNameAr}',
                                                style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blueAccent)),
                                            Text('${student.firstNameFr} ${student.lastNameFr}',
                                                style: TextStyle(color: Colors.grey.shade600)),
                                            Text('ID: ${student.id}', style: TextStyle(color: Colors.grey.shade700)),
                                            Text('الحضور: $attendance / Présence: $attendance',
                                                style: const TextStyle(color: Colors.black87)),
                                          ],
                                        ),
                                      ),
                                      DropdownButton<String>(
                                        value: attendance,
                                        items: ['حاضر', 'غائب', 'غير محدد'].map((value) {
                                          return DropdownMenuItem(
                                            value: value,
                                            child: Text(value,
                                                style: TextStyle(
                                                    color: value == 'حاضر'
                                                        ? Colors.green
                                                        : value == 'غائب'
                                                        ? Colors.red
                                                        : Colors.grey)),
                                          );
                                        }).toList(),
                                        onChanged: (newValue) {
                                          if (newValue != null) {
                                            context.read<StudentCubit>().updateStudentAttendanceWithDate(
                                              schoolId: selectedSchoolId ?? authState.uid,
                                              studentId: student.id,
                                              date: formattedDate,
                                              attendance: newValue,
                                            );
                                          }
                                        },
                                        underline: const SizedBox(),
                                        icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    }
                    return const Center(child: Text('اختر مدرسة / Choisissez une école'));
                  },
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
}

