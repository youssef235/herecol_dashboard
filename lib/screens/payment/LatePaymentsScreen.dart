import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_selector/file_selector.dart';
import 'package:school_management_dashboard/screens/payment/StudentPaymentsScreen.dart';
import '../../cubit/auth/auth_cubit.dart';
import '../../cubit/auth/auth_state.dart';

class LatePaymentsScreen extends StatefulWidget {
  final String? schoolId;
  final String role;

  const LatePaymentsScreen({required this.schoolId, required this.role});

  @override
  _LatePaymentsScreenState createState() => _LatePaymentsScreenState();
}

class _LatePaymentsScreenState extends State<LatePaymentsScreen> {
  String? selectedSchoolId;
  String _selectedLanguage = 'ar';
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      if (authState.role == 'school') {
        selectedSchoolId = widget.schoolId ?? authState.uid;
      } else if (authState.role == 'employee') {
        selectedSchoolId = authState.schoolId;
      }
    }
  }

  Future<void> _generateLatePaymentsListPdf(List<Map<String, dynamic>> lateStudents) async {
    final pdf = pw.Document();
    final arabicFont = await pw.Font.ttf((await rootBundle.load('assets/fonts/Amiri-Regular.ttf')).buffer.asByteData());
    final frenchFont = await pw.Font.ttf((await rootBundle.load('assets/fonts/Amiri-Regular.ttf')).buffer.asByteData());
    final maliFlagImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/mali.png')).buffer.asUint8List(),
    );

    String schoolName = _selectedLanguage == 'ar' ? 'غير متوفر' : 'Non disponible';
    final schoolSnapshot = await FirebaseFirestore.instance.collection('schools').doc(selectedSchoolId).get();
    if (schoolSnapshot.exists) {
      final data = schoolSnapshot.data() as Map<String, dynamic>;
      schoolName = data['schoolName'][_selectedLanguage] ?? (_selectedLanguage == 'ar' ? 'غير متوفر' : 'Non disponible');
    }

    if (lateStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_selectedLanguage == 'ar' ? 'لا يوجد طلاب متأخرين للطباعة' : 'Aucun étudiant en retard à imprimer')),
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
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black),
                columnWidths: {
                  0: pw.FixedColumnWidth(100), // Student Name
                  1: pw.FixedColumnWidth(100), // Guardian Name
                  2: pw.FixedColumnWidth(80),  // Guardian Phone
                  3: pw.FixedColumnWidth(100), // Amount Due (Arabic)
                  4: pw.FixedColumnWidth(100), // Amount Due (French)
                },
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Container(
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          _selectedLanguage == 'ar' ? 'اسم الطالب' : 'Nom de l’étudiant',
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
                          _selectedLanguage == 'ar' ? 'اسم الولي' : 'Nom du gardien',
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
                          _selectedLanguage == 'ar' ? 'رقم هاتف الولي' : 'Téléphone du gardien',
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
                          _selectedLanguage == 'ar' ? 'المبلغ المتبقي (عربي)' : 'Montant restant (Arabe)',
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
                          _selectedLanguage == 'ar' ? 'المبلغ المتبقي (فرنسي)' : 'Montant restant (Français)',
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
                  ...lateStudents.map((student) {
                    final remainingAmount = (student['totalFeesDue'] as double) - (student['feesPaid'] as double);
                    return pw.TableRow(
                      children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            _selectedLanguage == 'ar'
                                ? '${student['firstNameAr']} ${student['lastNameAr']}'
                                : '${student['firstNameFr']} ${student['lastNameFr']}',
                            style: pw.TextStyle(font: _selectedLanguage == 'ar' ? arabicFont : frenchFont, fontSize: 10),
                            textDirection: _selectedLanguage == 'ar' ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                          ),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            student['guardianName'] ?? (_selectedLanguage == 'ar' ? 'غير متوفر' : 'Non disponible'),
                            style: pw.TextStyle(font: _selectedLanguage == 'ar' ? arabicFont : frenchFont, fontSize: 10),
                            textDirection: _selectedLanguage == 'ar' ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                          ),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            student['guardianPhone'] ?? '',
                            style: pw.TextStyle(font: frenchFont, fontSize: 10),
                          ),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            '$remainingAmount',
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            '$remainingAmount',
                            style: pw.TextStyle(font: frenchFont, fontSize: 10),
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
    final FileSaveLocation? fileSaveLocation = await getSaveLocation(suggestedName: 'late_payments_list.pdf');
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
      return Scaffold(
        body: Center(
          child: Text(
            _selectedLanguage == 'ar' ? 'يرجى تسجيل الدخول' : 'Veuillez vous connecter',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedLanguage == 'ar'
              ? 'الطلاب المتأخرون عن الدفع'
              : 'Étudiants en retard de paiement',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: Colors.white),
            onPressed: () async {
              if (selectedSchoolId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_selectedLanguage == 'ar' ? 'يرجى اختيار مدرسة' : 'Veuillez choisir une école')),
                );
                return;
              }

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Création de la liste des retardataires...'),
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

              final snapshot = await FirebaseFirestore.instance
                  .collection('schools')
                  .doc(selectedSchoolId)
                  .collection('students')
                  .get();
              final lateStudents = snapshot.docs
                  .map((doc) {
                final data = doc.data();
                return {
                  'id': doc.id,
                  'firstNameAr': data['firstNameAr'] ?? 'غير معروف',
                  'firstNameFr': data['firstNameFr'] ?? 'Inconnu',
                  'lastNameAr': data['lastNameAr'] ?? 'غير معروف',
                  'lastNameFr': data['lastNameFr'] ?? 'Inconnu',
                  'totalFeesDue': (data['totalFeesDue'] ?? 0.0).toDouble(),
                  'feesPaid': (data['feesPaid'] ?? 0.0).toDouble(),
                  'guardianName': data['guardianName'] ?? (_selectedLanguage == 'ar' ? 'غير متوفر' : 'Non disponible'),
                  'guardianPhone': data['guardianPhone'] ?? '',
                };
              })
                  .where((student) => (student['totalFeesDue'] as double) > (student['feesPaid'] as double))
                  .toList();

              await _generateLatePaymentsListPdf(lateStudents);
              Navigator.of(context).pop();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: _selectedLanguage,
              icon: const Icon(Icons.language, color: Colors.white),
              dropdownColor: Colors.blueAccent,
              underline: const SizedBox(),
              items: [
                DropdownMenuItem(
                  value: 'ar',
                  child: Text('العربية', style: TextStyle(color: Colors.white)),
                ),
                DropdownMenuItem(
                  value: 'fr',
                  child: Text('Français', style: TextStyle(color: Colors.white)),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
              },
            ),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (authState.role == 'admin') ...[
                _buildSchoolDropdown(),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: _buildStudentsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('schools').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              _selectedLanguage == 'ar' ? 'لا توجد مدارس متاحة' : 'Aucune école disponible',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final schools = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'schoolName': data['schoolName'][_selectedLanguage] ?? (_selectedLanguage == 'ar' ? 'مدرسة بدون اسم' : 'École sans nom'),
          };
        }).toList();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 3,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            decoration: _buildInputDecoration(
              _selectedLanguage == 'ar' ? 'اختر المدرسة' : 'Choisir l’école',
            ),
            value: selectedSchoolId,
            items: schools.map<DropdownMenuItem<String>>((school) {
              return DropdownMenuItem<String>(
                value: school['id'],
                child: Text(school['schoolName']!, style: const TextStyle(color: Colors.blueAccent)),
              );
            }).toList(),
            onChanged: (schoolId) {
              setState(() {
                selectedSchoolId = schoolId;
              });
            },
            hint: Text(
              _selectedLanguage == 'ar' ? 'اختر مدرسة' : 'Choisir une école',
              style: const TextStyle(color: Colors.grey),
            ),
            style: const TextStyle(color: Colors.blueAccent),
            dropdownColor: Colors.white,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
          ),
        );
      },
    );
  }

  Widget _buildStudentsList() {
    if (selectedSchoolId == null) {
      return Center(
        child: Text(
          _selectedLanguage == 'ar' ? 'يرجى اختيار مدرسة' : 'Veuillez choisir une école',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(selectedSchoolId)
          .collection('students')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              _selectedLanguage == 'ar' ? 'لا يوجد طلاب في هذه المدرسة' : 'Aucun étudiant dans cette école',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final students = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'firstNameAr': data['firstNameAr'] ?? 'غير معروف',
            'firstNameFr': data['firstNameFr'] ?? 'Inconnu',
            'lastNameAr': data['lastNameAr'] ?? 'غير معروف',
            'lastNameFr': data['lastNameFr'] ?? 'Inconnu',
            'totalFeesDue': (data['totalFeesDue'] ?? 0.0).toDouble(),
            'feesPaid': (data['feesPaid'] ?? 0.0).toDouble(),
            'guardianName': data['guardianName'] ?? (_selectedLanguage == 'ar' ? 'غير متوفر' : 'Non disponible'),
            'guardianPhone': data['guardianPhone'] ?? '',
            'profileImageUrl': data['profileImageUrl'] ?? '', // حقل الصورة
            'grade': data['grade'] ?? 'غير محدد', // حقل الصف
          };
        }).toList();

        final lateStudents = students.where((student) {
          final remainingAmount = (student['totalFeesDue'] as double) - (student['feesPaid'] as double);
          return remainingAmount > 0;
        }).toList();

        if (lateStudents.isEmpty) {
          return Center(
            child: Text(
              _selectedLanguage == 'ar' ? 'لا يوجد طلاب متأخرون عن الدفع' : 'Aucun étudiant en retard de paiement',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: lateStudents.length,
          itemBuilder: (context, index) {
            final student = lateStudents[index];
            final totalFeesDue = student['totalFeesDue'] as double;
            final feesPaid = student['feesPaid'] as double;
            final remainingAmount = totalFeesDue - feesPaid;

            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 30,
                  backgroundImage: student['profileImageUrl'] != '' && student['profileImageUrl'] != null
                      ? NetworkImage(student['profileImageUrl'] as String)
                      : null, // لا نعين backgroundImage إذا لم يكن هناك رابط صورة
                  child: student['profileImageUrl'] == '' || student['profileImageUrl'] == null
                      ? Icon(Icons.person, size: 40, color: Colors.grey) // عرض الأيقونة إذا لم تكن هناك صورة
                      : null, // لا محتوى إذا كانت هناك صورة
                ),
                title: Text(
                  _selectedLanguage == 'ar'
                      ? '${student['firstNameAr']} ${student['lastNameAr']}'
                      : '${student['firstNameFr']} ${student['lastNameFr']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      _selectedLanguage == 'ar' ? 'المعرف: ${student['id']}' : 'ID: ${student['id']}',
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    Text(
                      _selectedLanguage == 'ar' ? 'الصف: ${student['grade']}' : 'Classe: ${student['grade']}',
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    Text(
                      _selectedLanguage == 'ar'
                          ? 'المستحق: $remainingAmount | المدفوع: $feesPaid'
                          : 'Dû: $remainingAmount | Payé: $feesPaid',
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.warning, color: Colors.red),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentPaymentsScreen(
                        schoolId: selectedSchoolId!,
                        studentId: student['id'] as String,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.blueAccent),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.blueAccent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }
}