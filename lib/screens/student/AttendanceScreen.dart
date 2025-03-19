import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:school_management_dashboard/firebase_services/school_info_firebase_services.dart';
import '../../cubit/auth/auth_cubit.dart';
import '../../cubit/auth/auth_state.dart';
import '../../cubit/school_info/school_info_cubit.dart';
import '../../cubit/school_info/school_info_state.dart';
import '../../cubit/student/student_cubit.dart';
import '../../cubit/student/student_state.dart';
import '../../models/school_info_model.dart';
import '../../models/student_model.dart';
import 'dart:io';

// مكون مخصص لعرض خيارات الحضور
class AttendanceIndicator extends StatelessWidget {
  final String option; // 'حاضر', 'غائب', 'غير محدد'
  final String? currentAttendance; // الحالة الحالية
  final VoidCallback? onTap; // للتفاعل عند النقر
  final double size; // حجم العنصر

  const AttendanceIndicator({
    Key? key,
    required this.option,
    this.currentAttendance,
    this.onTap,
    this.size = 40.0,
  }) : super(key: key);

  static const Map<String, Map<String, dynamic>> _attendanceStyles = {
    'حاضر': {
      'color': Colors.green,
      'icon': Icons.check_circle,
      'label': 'P',
    },
    'غائب': {
      'color': Colors.red,
      'icon': Icons.cancel,
      'label': 'A',
    },
    'غير محدد': {
      'color': Colors.grey,
      'icon': Icons.help_outline,
      'label': '?',
    },
  };

  @override
  Widget build(BuildContext context) {
    final style = _attendanceStyles[option] ?? _attendanceStyles['غير محدد']!;
    final isSelected = option == currentAttendance;
    final borderColor = isSelected ? style['color'] : style['color'].withOpacity(0.5);
    final backgroundColor = isSelected ? style['color'] : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: size,
        height: size,
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: style['color'].withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
          ],
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Center(
          child: Icon(
            style['icon'] as IconData,
            color: isSelected ? Colors.white : style['color'],
            size: size * 0.6,
          ),
        ),
      ),
    );
  }
}

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
        // إذا كان المستخدم مدرسة، استخدم uid أو schoolId الممرر كـ selectedSchoolId
        selectedSchoolId = widget.schoolId ?? authState.uid;
        context.read<StudentCubit>().streamStudents(schoolId: selectedSchoolId!);
      } else if (authState.role == 'employee') {
        // إذا كان المستخدم موظفًا، استخدم schoolId من حالة المصادقة
        selectedSchoolId = authState.schoolId;
        if (selectedSchoolId != null) {
          context.read<StudentCubit>().streamStudents(schoolId: selectedSchoolId!);
        }
      } else if (authState.role == 'admin') {
        // إذا كان المستخدم admin، جلب جميع المدارس
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
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          primaryColor: Colors.blueAccent,
          colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
          buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
        ),
        child: child!,
      ),
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

    String schoolNameAR = 'غير متوفر';
    String schoolNameFR = 'غير متوفر';

    if (students.isNotEmpty) {
      final schoolInfo = await _schoolFirebaseServices.getSchoolInfo(students[0].schoolId);
      schoolNameAR = schoolInfo?.schoolName['ar'] ?? 'غير متوفر';
      schoolNameFR = schoolInfo?.schoolName['fr'] ?? 'غير متوفر';
    }

    final grade = selectedGrade ?? (students.isNotEmpty ? students[0].gradeFr ?? '6ème Année' : '6ème Année');

    students.sort((a, b) => a.firstNameAr.compareTo(b.firstNameAr));

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
                'Un Peuple - Un But - Une Foi',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: font, fontSize: 8),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    schoolNameAR,
                    style: pw.TextStyle(font: arabicFont, fontSize: 12),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.Text(' / '),
                  pw.Text(
                    schoolNameFR,
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'كشف الحضور والغياب',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: arabicFont, fontSize: 16, fontWeight: pw.FontWeight.bold),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'LISTE DES ÉLÈVES - $grade',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black),
                columnWidths: {
                  0: pw.FixedColumnWidth(30),
                  1: pw.FixedColumnWidth(150),
                  2: pw.FixedColumnWidth(150),
                  for (int i = 0; i < 7; i++) i + 3: pw.FixedColumnWidth(30),
                },
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Text('#', style: pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                      pw.Text('الاسم', style: pw.TextStyle(font: arabicFont, fontSize: 12, fontWeight: pw.FontWeight.bold), textDirection: pw.TextDirection.rtl, textAlign: pw.TextAlign.center),
                      pw.Text('Nom', style: pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                      ...weekDates.map((date) => pw.Text(date, style: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)).toList(),
                    ],
                  ),
                  ...students.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final student = entry.value;
                    return pw.TableRow(
                      children: [
                        pw.Text('$index', style: pw.TextStyle(font: font, fontSize: 10), textAlign: pw.TextAlign.center),
                        pw.Text('${student.firstNameAr} ${student.lastNameAr}', style: pw.TextStyle(font: arabicFont, fontSize: 10), textDirection: pw.TextDirection.rtl, textAlign: pw.TextAlign.center),
                        pw.Text('${student.firstNameFr} ${student.lastNameFr}', style: pw.TextStyle(font: font, fontSize: 10), textAlign: pw.TextAlign.center),
                        ...List.generate(7, (i) {
                          final date = selectedDate.add(Duration(days: i));
                          final attendance = student.attendanceHistory?[DateFormat('yyyy-MM-dd').format(date)] ?? 'غير محدد';
                          return pw.Text(
                            attendance == 'حاضر' ? 'P' : attendance == 'غائب' ? 'A' : '?',
                            style: pw.TextStyle(font: font, fontSize: 10),
                            textAlign: pw.TextAlign.center,
                          );
                        }),
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

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/attendance_list_$grade.pdf');
    await file.writeAsBytes(await pdf.save());
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
    OpenFile.open(file.path);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  Widget _buildAttendanceDots(Student student) {
    final List<String> attendanceOptions = ['حاضر', 'غائب', 'غير محدد'];
    String currentAttendance = student.attendanceHistory?[formattedDate] ?? 'غير محدد';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: attendanceOptions.map((option) {
        return AttendanceIndicator(
          option: option,
          currentAttendance: currentAttendance,
          onTap: () {
            final authState = context.read<AuthCubit>().state;
            if (authState is AuthAuthenticated) {
              context.read<StudentCubit>().updateStudentAttendanceWithDate(
                schoolId: selectedSchoolId ?? authState.uid,
                studentId: student.id,
                date: formattedDate,
                attendance: option,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('يجب تسجيل الدخول أولاً', style: GoogleFonts.cairo())),
              );
            }
          },
          size: 36.0, // حجم أكبر لتحسين الوضوح
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return Scaffold(
        body: Center(
          child: Text('يرجى تسجيل الدخول / Veuillez vous connecter', style: GoogleFonts.cairo(fontSize: 18)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة الحضور / Gestion de la présence', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            onPressed: () {
              final state = context.read<StudentCubit>().state;
              if (state is StudentsLoaded) {
                _generateAttendancePdf(selectedGrade != null
                    ? state.students.where((student) => student.gradeFr == selectedGrade).toList()
                    : state.students);
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
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('اختيار التاريخ / Sélectionner la date'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('التاريخ: $formattedDate / Date: $formattedDate',
                              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: () => _selectDate(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: Text('اختر تاريخ / Choisir une date', style: GoogleFonts.cairo(fontSize: 16)),
                          ),
                        ],
                      ),
                      if (authState.role == 'admin') ...[
                        const SizedBox(height: 20),
                        BlocBuilder<SchoolCubit, SchoolState>(
                          builder: (context, schoolState) {
                            if (schoolState is SchoolsLoaded) {
                              return DropdownButtonFormField<String>(
                                decoration: _buildInputDecoration('المدرسة / École'),
                                value: selectedSchoolId,
                                items: schoolState.schools.map((school) {
                                  return DropdownMenuItem(
                                    value: school.schoolId,
                                    child: Text('${school.schoolName['ar'] ?? 'غير متوفر'}', style: GoogleFonts.cairo()),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedSchoolId = value;
                                    selectedGrade = null;
                                    if (value != null) {
                                      context.read<StudentCubit>().streamStudents(schoolId: value);
                                    }
                                  });
                                },
                                validator: (value) => value == null ? 'مطلوب' : null,
                                dropdownColor: Colors.white,
                              );
                            }
                            return const Center(child: CircularProgressIndicator());
                          },
                        ),
                        const SizedBox(height: 20),
                        BlocBuilder<StudentCubit, StudentState>(
                          builder: (context, state) {
                            if (state is StudentsLoaded && state.students.isNotEmpty) {
                              final grades = state.students.map((student) => student.gradeFr).toSet().toList();
                              return DropdownButtonFormField<String>(
                                decoration: _buildInputDecoration('الصف / Classe'),
                                value: selectedGrade,
                                items: grades.map((grade) {
                                  return DropdownMenuItem(
                                    value: grade,
                                    child: Text(grade ?? 'غير محدد', style: GoogleFonts.cairo()),
                                  );
                                }).toList(),
                                onChanged: (value) => setState(() => selectedGrade = value),
                                validator: (value) => value == null ? 'مطلوب' : null,
                                dropdownColor: Colors.white,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: BlocBuilder<StudentCubit, StudentState>(
                    builder: (context, state) {
                      if (state is StudentLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is StudentsLoaded) {
                        final filteredStudents = selectedGrade != null
                            ? state.students.where((student) => student.gradeFr == selectedGrade).toList()
                            : state.students;
                        if (filteredStudents.isEmpty) {
                          return Center(
                            child: Text('لا يوجد طلاب / Aucun étudiant', style: GoogleFonts.cairo(fontSize: 18)),
                          );
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
                                  margin: const EdgeInsets.symmetric(vertical: 10),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.blueAccent.shade100,
                                      child: student.profileImage != null
                                          ? ClipOval(child: Image.network(student.profileImage!, fit: BoxFit.cover))
                                          : Icon(Icons.person, size: 30, color: Colors.blueAccent),
                                    ),
                                    title: Text(
                                      '${student.firstNameAr} ${student.lastNameAr}',
                                      style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${student.firstNameFr} ${student.lastNameFr}',
                                            style: GoogleFonts.cairo(color: Colors.grey.shade600)),
                                        Text('ID: ${student.id}', style: GoogleFonts.cairo(color: Colors.grey.shade700)),
                                        Text('الحضور: $attendance / Présence: $attendance',
                                            style: GoogleFonts.cairo(color: Colors.black87)),
                                      ],
                                    ),
                                    trailing: _buildAttendanceDots(student),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      }
                      return Center(
                        child: Text('اختر مدرسة / Choisissez une école', style: GoogleFonts.cairo(fontSize: 18)),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}