import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../../cubit/Employee/EmployeeCubit.dart';
import '../../cubit/Employee/EmployeeState.dart';
import '../../cubit/auth/auth_cubit.dart';
import '../../cubit/auth/auth_state.dart';
import '../../cubit/salary/salary_cubit.dart';
import '../../cubit/salary/salary_state.dart';
import '../../cubit/school_info/school_info_cubit.dart';
import '../../cubit/school_info/school_info_state.dart';
import '../../firebase_services/SalaryFirebaseServices.dart';
import '../../firebase_services/employee_firebase_services.dart';
import '../../firebase_services/school_info_firebase_services.dart';
import '../../models/SalaryPayment.dart';
import '../../models/employee_model.dart';
import '../../models/school_info_model.dart';
import 'PaySalaryScreen.dart';
import 'SalaryDetailsScreen.dart';

class SalaryTrackingScreen extends StatefulWidget {
  final String? schoolId;

  const SalaryTrackingScreen({required this.schoolId});

  @override
  _SalaryTrackingScreenState createState() => _SalaryTrackingScreenState();
}

class _SalaryTrackingScreenState extends State<SalaryTrackingScreen> {
  int selectedMonthIndex = 2; // مارس (Mars) هو الشهر الثالث (0-based index)
  int selectedYear = 2025; // السنة الافتراضية
  String? selectedSchoolId;
  String language = 'fr'; // اللغة الافتراضية: الفرنسية
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);

  final Map<String, Map<String, String>> translations = {
    'ar': {
      'title': 'تتبع دفع الرواتب',
      'selectSchool': 'اختر المدرسة',
      'selectMonthYear': 'اختر الشهر والسنة',
      'payAllDialogTitle': 'دفع جميع الرواتب غير المدفوعة',
      'payAllDialogContent': 'هل تريد دفع رواتب {count} موظفين غير مدفوعة لشهر {month}؟',
      'cancel': 'إلغاء',
      'payAllButton': 'دفع الكل',
      'noUnpaid': 'لا توجد رواتب غير مدفوعة',
      'noEmployees': 'لا يوجد موظفين متاحين لهذه المدرسة',
      'noPayments': 'لا توجد دفعات رواتب لهذا الشهر',
      'selectSchoolPrompt': 'يرجى اختيار مدرسة',
      'paySalary': 'دفع الراتب',
      'department': 'القسم',
      'status': 'الحالة',
      'paid': 'مدفوع',
      'unpaid': 'غير مدفوع',
      'errorLoadingSchools': 'خطأ في جلب المدارس: {message}',
      'errorLoadingEmployees': 'خطأ في جلب الموظفين: {message}',
      'errorLoadingPayments': 'خطأ في جلب دفعات الرواتب: {message}',
      'noSchools': 'لا توجد مدارس متاحة',
      'printReceipt': 'طباعة الفاتورة',
      'printAllReceipts': 'طباعة كل الفواتير',
      'partiallyPaid': 'مدفوع جزئيًا',
    },
    'fr': {
      'title': 'Suivi des paiements de salaire',
      'selectSchool': 'Choisir l’école',
      'selectMonthYear': 'Choisir le mois et l’année',
      'payAll': 'Payer tous les salaires non payés',
      'payAllDialogTitle': 'Payer tous les salaires non payés',
      'payAllDialogContent': 'Voulez-vous payer les salaires de {count} employés non payés pour {month} ?',
      'cancel': 'Annuler',
      'payAllButton': 'Payer tout',
      'noUnpaid': 'Aucun salaire non payé',
      'noEmployees': 'Aucun employé disponible pour cette école',
      'noPayments': 'Aucun paiement pour ce mois',
      'selectSchoolPrompt': 'Veuillez choisir une école',
      'paySalary': 'Payer le salaire',
      'department': 'Département',
      'status': 'Statut',
      'paid': 'Payé',
      'unpaid': 'Non payé',
      'errorLoadingSchools': 'Erreur lors du chargement des écoles : {message}',
      'errorLoadingEmployees': 'Erreur lors du chargement des employés : {message}',
      'errorLoadingPayments': 'Erreur lors du chargement des paiements : {message}',
      'noSchools': 'Aucune école disponible',
      'printReceipt': 'Imprimer le reçu',
      'printAllReceipts': 'Imprimer tous les reçus',
      'partiallyPaid': 'Partiellement payé',
    },
  };

  @override
  void initState() {
    super.initState();
    selectedSchoolId = widget.schoolId;
    final authState = context.read<AuthCubit>().state;
    final isSuperAdmin = authState is AuthAuthenticated && authState.role == 'admin';
    if (selectedSchoolId != null || isSuperAdmin) {
      context.read<EmployeeCubit>().fetchEmployees(schoolId: selectedSchoolId, isSuperAdmin: isSuperAdmin);
      if (selectedSchoolId != null) {
        context.read<SalaryCubit>().fetchSalaryPayments(selectedSchoolId!, _getSelectedMonthStringForQuery());
      }
    }
  }

  String _getSelectedMonthStringForDisplay() {
    final monthsAr = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    final monthsFr = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    final month = language == 'ar' ? monthsAr[selectedMonthIndex] : monthsFr[selectedMonthIndex];
    return '$month $selectedYear';
  }

  String _getSelectedMonthStringForQuery() {
    return "${(selectedMonthIndex + 1).toString().padLeft(2, '0')}-$selectedYear"; // تنسيق "MM-YYYY"
  }

  Future<void> _generateEmployeeReceiptPdf(Employee employee, SalaryPayment? payment) async {
    final pdf = pw.Document();
    final arabicFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Amiri-Regular.ttf'));
    final frenchFont = await PdfGoogleFonts.robotoRegular();
    final maliFlagImage = pw.MemoryImage(await rootBundle.load('assets/images/mali.png').then((data) => data.buffer.asUint8List()));

    String schoolName = language == 'ar' ? 'غير متوفر' : 'Non disponible';
    final schoolState = context.read<SchoolCubit>().state;
    if (schoolState is SchoolsLoaded && selectedSchoolId != null) {
      final school = schoolState.schools.firstWhere(
            (s) => s.schoolId == selectedSchoolId,
        orElse: () => Schoolinfo(
          schoolId: selectedSchoolId!,
          schoolName: {'ar': 'غير متوفر', 'fr': 'Non disponible'},
          city: {'ar': '', 'fr': ''},
          email: '',
          phone: '',
          currency: {'ar': '', 'fr': ''},
          currencySymbol: {'ar': '', 'fr': ''},
          address: {'ar': '', 'fr': ''},
          classes: {'ar': [], 'fr': []},
          sections: {'ar': {}, 'fr': {}},
          categories: {'ar': [], 'fr': []},
          mainSections: {'ar': [], 'fr': []},
          subSections: {'ar': {}, 'fr': {}},
          principalName: {'ar': 'غير متوفر', 'fr': 'Non disponible'},
        ),
      );
      schoolName = school.schoolName[language] ?? schoolName;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Image(maliFlagImage, width: 30, height: 20),
                    pw.SizedBox(width: 5),
                    pw.Text('RÉPUBLIQUE DU MALI', style: pw.TextStyle(font: frenchFont, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Text('UN PEUPLE - UN BUT - UNE FOI', style: pw.TextStyle(font: frenchFont, fontSize: 8)),
                pw.Text('INSTITUT IMANE', style: pw.TextStyle(font: frenchFont, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Text('POUR LES ETUDES ISLAMIQUES', style: pw.TextStyle(font: frenchFont, fontSize: 9)),
                pw.Text(
                  language == 'ar' ? 'المدرسة: $schoolName' : 'École: $schoolName',
                  style: pw.TextStyle(font: arabicFont, fontSize: 12),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  language == 'ar' ? 'فاتورة دفع راتب' : 'Reçu de paiement de salaire',
                  style: pw.TextStyle(font: arabicFont, fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {0: pw.FixedColumnWidth(150), 1: pw.FixedColumnWidth(150)},
                  defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                  children: [
                    pw.TableRow(children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(language == 'ar' ? 'اسم الموظف' : 'Nom de l’employé', style: pw.TextStyle(font: arabicFont)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(language == 'ar' ? employee.fullNameAr : (employee.fullNameFr ?? employee.fullNameAr), style: pw.TextStyle(font: arabicFont)),
                      ),
                    ]),
                    pw.TableRow(children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(language == 'ar' ? 'القسم' : 'Département', style: pw.TextStyle(font: arabicFont)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(language == 'ar' ? employee.departmentAr : (employee.departmentFr ?? employee.departmentAr), style: pw.TextStyle(font: arabicFont)),
                      ),
                    ]),
                    if (payment != null) ...[
                      pw.TableRow(children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(language == 'ar' ? 'الشهر' : 'Mois', style: pw.TextStyle(font: arabicFont)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(_convertMonthFormat(payment.month), style: pw.TextStyle(font: arabicFont)),
                        ),
                      ]),
                      pw.TableRow(children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(language == 'ar' ? 'الراتب الأساسي' : 'Salaire de base', style: pw.TextStyle(font: arabicFont)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${payment.baseSalary} CFA', style: pw.TextStyle(font: arabicFont)),
                        ),
                      ]),
                      pw.TableRow(children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(language == 'ar' ? 'راتب الساعات الإضافية' : 'Salaire heures supp.', style: pw.TextStyle(font: arabicFont)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${payment.overtimeSalary} CFA', style: pw.TextStyle(font: arabicFont)),
                        ),
                      ]),
                      pw.TableRow(children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(language == 'ar' ? 'الراتب الإجمالي' : 'Salaire total', style: pw.TextStyle(font: arabicFont)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${payment.totalSalary} CFA', style: pw.TextStyle(font: arabicFont)),
                        ),
                      ]),
                      pw.TableRow(children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(language == 'ar' ? 'تاريخ الدفع' : 'Date de paiement', style: pw.TextStyle(font: arabicFont)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(payment.paymentDate.toString().split(' ')[0], style: pw.TextStyle(font: arabicFont)),
                        ),
                      ]),
                      pw.TableRow(children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(language == 'ar' ? 'الحالة' : 'Statut', style: pw.TextStyle(font: arabicFont)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            language == 'ar'
                                ? (payment.status == PaymentStatus.paid
                                ? 'مدفوع'
                                : payment.status == PaymentStatus.partiallyPaid
                                ? 'مدفوع جزئيًا: ${payment.partialAmount} CFA من ${payment.totalSalary} CFA'
                                : 'غير مدفوع')
                                : (payment.status == PaymentStatus.paid
                                ? 'Payé'
                                : payment.status == PaymentStatus.partiallyPaid
                                ? 'Partiellement payé: ${payment.partialAmount} CFA sur ${payment.totalSalary} CFA'
                                : 'Non payé'),
                            style: pw.TextStyle(font: arabicFont),
                          ),
                        ),
                      ]),
                      if (payment.notes != null)
                        pw.TableRow(children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(language == 'ar' ? 'ملاحظات' : 'Notes', style: pw.TextStyle(font: arabicFont)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(payment.notes!, style: pw.TextStyle(font: arabicFont)),
                          ),
                        ]),
                    ] else
                      pw.TableRow(children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(language == 'ar' ? 'الحالة' : 'Statut', style: pw.TextStyle(font: arabicFont)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(language == 'ar' ? 'غير مدفوع' : 'Non payé', style: pw.TextStyle(font: arabicFont)),
                        ),
                      ]),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final fileName = 'salary_receipt_${employee.id}_${_getSelectedMonthStringForDisplay().replaceAll(' ', '_')}.pdf';
    final dir = await getApplicationDocumentsDirectory();
    final archivePath = '${dir.path}/salary_archive';
    await Directory(archivePath).create(recursive: true);
    final file = File('$archivePath/$fileName');
    await file.writeAsBytes(bytes);

    final FileSaveLocation? saveLocation = await getSaveLocation(suggestedName: fileName);
    if (saveLocation != null) {
      final saveFile = File(saveLocation.path);
      await saveFile.writeAsBytes(bytes);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Receipt saved at: ${saveLocation.path}')));
    }
  }

  String _convertMonthFormat(String month) {
    final monthsAr = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    final monthsFr = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    final parts = month.split('-');
    if (parts.length == 2) {
      final monthIndex = int.parse(parts[0]) - 1;
      final year = parts[1];
      return language == 'ar' ? '${monthsAr[monthIndex]} $year' : '${monthsFr[monthIndex]} $year';
    }
    return month; // إذا لم يكن بالتنسيق المتوقع، أعد النص كما هو
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isSuperAdmin = authState is AuthAuthenticated && authState.role == 'admin';

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => SchoolCubit(SchoolFirebaseServices())),
        BlocProvider(create: (context) => EmployeeCubit(EmployeeFirebaseServices())),
        BlocProvider(create: (context) => SalaryCubit(SalaryFirebaseServices())),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(translations[language]?['title'] ?? 'Salary Tracking'),
          backgroundColor: Colors.blueAccent,
          elevation: 0,
          actions: [
            IconButton(
              color: Colors.white,
              icon: Icon(language == 'ar' ? Icons.language : Icons.translate),
              onPressed: () {
                setState(() {
                  language = language == 'ar' ? 'fr' : 'ar';
                  if (selectedSchoolId != null) {
                    context.read<SalaryCubit>().fetchSalaryPayments(selectedSchoolId!, _getSelectedMonthStringForQuery());
                  }
                });
              },
              tooltip: language == 'ar' ? 'Changer en français' : 'تحويل إلى العربية',
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
          child: Column(
            children: [
              if (isSuperAdmin)
                BlocBuilder<SchoolCubit, SchoolState>(
                  builder: (context, schoolState) {
                    if (schoolState is SchoolInitial && authState is AuthAuthenticated) {
                      context.read<SchoolCubit>().fetchSchools(authState.uid, 'admin');
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (schoolState is SchoolsLoaded) {
                      final uniqueSchools = schoolState.schools.toSet().toList();
                      if (selectedSchoolId != null && !uniqueSchools.any((school) => school.schoolId == selectedSchoolId)) {
                        selectedSchoolId = uniqueSchools.isNotEmpty ? uniqueSchools.first.schoolId : null;
                      }
                      if (uniqueSchools.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(translations[language]?['noSchools'] ?? 'No schools available'),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: translations[language]?['selectSchool'] ?? 'Select School',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          value: selectedSchoolId,
                          items: uniqueSchools.map((school) {
                            return DropdownMenuItem(
                              value: school.schoolId,
                              child: Text(school.schoolName[language] ?? (language == 'ar' ? 'غير متوفر' : 'Non disponible')),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSchoolId = value;
                              if (value != null) {
                                context.read<EmployeeCubit>().fetchEmployees(schoolId: value, isSuperAdmin: isSuperAdmin);
                                context.read<SalaryCubit>().fetchSalaryPayments(value, _getSelectedMonthStringForQuery());
                              }
                            });
                          },
                        ),
                      );
                    }
                    if (schoolState is SchoolError) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          (translations[language]?['errorLoadingSchools'] ?? 'Error loading schools: {message}')
                              .replaceFirst('{message}', schoolState.message),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _getSelectedMonthStringForDisplay(),
                        items: _generateMonthYearOptions(),
                        onChanged: (value) {
                          setState(() {
                            final parts = value?.split(' ') ?? [];
                            if (parts.length == 2) {
                              final monthsAr = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
                              final monthsFr = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
                              final monthList = language == 'ar' ? monthsAr : monthsFr;
                              selectedMonthIndex = monthList.indexOf(parts[0]);
                              selectedYear = int.tryParse(parts[1]) ?? selectedYear;
                              if (selectedSchoolId != null) {
                                context.read<SalaryCubit>().fetchSalaryPayments(selectedSchoolId!, _getSelectedMonthStringForQuery());
                              }
                            }
                          });
                        },
                        decoration: InputDecoration(
                          labelText: translations[language]?['selectMonthYear'] ?? 'Select Month and Year',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
              Expanded(
                child: BlocListener<EmployeeCubit, EmployeeState>(
                  listener: (context, state) {
                    if (state is EmployeeError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message)),
                      );
                    }
                  },
                  child: BlocBuilder<EmployeeCubit, EmployeeState>(
                    builder: (context, employeeState) {
                      if (employeeState is EmployeeLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (employeeState is EmployeeLoaded) {
                        if (employeeState.employees.isEmpty) {
                          return Center(child: Text(translations[language]?['noEmployees'] ?? 'No employees available'));
                        }
                        return BlocBuilder<SalaryCubit, SalaryState>(
                          builder: (context, salaryState) {
                            if (salaryState is SalaryLoading) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (salaryState is SalaryPaymentsLoaded) {
                              return ListView.builder(
                                itemCount: employeeState.employees.length,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemBuilder: (context, index) {
                                  final employee = employeeState.employees[index];
                                  final payment = salaryState.payments.firstWhereOrNull((p) => p.employeeId == employee.id);
                                  final status = payment?.status ?? PaymentStatus.unpaid;

                                  return GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SalaryDetailsScreen(
                                          employee: employee,
                                          payment: payment,
                                          schoolId: selectedSchoolId ?? '',
                                        ),
                                      ),
                                    ).then((_) {
                                      if (selectedSchoolId != null) {
                                        context.read<SalaryCubit>().fetchSalaryPayments(selectedSchoolId!, _getSelectedMonthStringForQuery());
                                      }
                                    }),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            status == PaymentStatus.paid
                                                ? Colors.greenAccent.withOpacity(0.2)
                                                : status == PaymentStatus.partiallyPaid
                                                ? Colors.orange.withOpacity(0.2)
                                                : Colors.blue.withOpacity(0.2),
                                            Colors.white,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: status == PaymentStatus.paid
                                                    ? Colors.greenAccent.withOpacity(0.3)
                                                    : status == PaymentStatus.partiallyPaid
                                                    ? Colors.orange.withOpacity(0.3)
                                                    : Colors.blue.withOpacity(0.3),
                                              ),
                                              child: Icon(
                                                status == PaymentStatus.paid
                                                    ? Icons.check_circle
                                                    : status == PaymentStatus.partiallyPaid
                                                    ? Icons.hourglass_bottom
                                                    : Icons.pending,
                                                color: status == PaymentStatus.paid
                                                    ? Colors.green
                                                    : status == PaymentStatus.partiallyPaid
                                                    ? Colors.orange
                                                    : Colors.blueAccent,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    language == 'ar' ? employee.fullNameAr : (employee.fullNameFr ?? employee.fullNameAr),
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Colors.black87,
                                                      fontFamily: 'Roboto',
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${translations[language]?['department'] ?? 'Department'}: ${language == 'ar' ? employee.departmentAr : (employee.departmentFr ?? employee.departmentAr)}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black54,
                                                      fontFamily: 'Roboto',
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${translations[language]?['status'] ?? 'Status'}: ${status == PaymentStatus.paid ? (translations[language]?['paid'] ?? 'Paid') : status == PaymentStatus.partiallyPaid ? (translations[language]?['partiallyPaid'] ?? 'Partially Paid') : (translations[language]?['unpaid'] ?? 'Unpaid')}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: status == PaymentStatus.paid
                                                          ? Colors.green
                                                          : status == PaymentStatus.partiallyPaid
                                                          ? Colors.orange
                                                          : Colors.red,
                                                      fontWeight: FontWeight.w500,
                                                      fontFamily: 'Roboto',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                ElevatedButton(
                                                  onPressed: status == PaymentStatus.paid
                                                      ? null
                                                      : () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => PaySalaryScreen(
                                                        employee: employee,
                                                        schoolId: selectedSchoolId ?? '',
                                                        selectedMonth: _getSelectedMonthStringForQuery(),
                                                      ),
                                                    ),
                                                  ).then((_) {
                                                    if (selectedSchoolId != null) {
                                                      context.read<SalaryCubit>().fetchSalaryPayments(selectedSchoolId!, _getSelectedMonthStringForQuery());
                                                    }
                                                  }),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.blueAccent,
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    elevation: 2,
                                                  ),
                                                  child: Text(
                                                    translations[language]?['paySalary'] ?? 'Pay Salary',
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(Icons.print, color: Colors.blueAccent),
                                                  onPressed: () async {
                                                    await _generateEmployeeReceiptPdf(employee, payment);
                                                  },
                                                  tooltip: translations[language]?['printReceipt'] ?? 'Print Receipt',
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            } else if (salaryState is SalaryError) {
                              return Center(
                                child: Text(
                                  (translations[language]?['errorLoadingPayments'] ?? 'Error loading payments: {message}')
                                      .replaceFirst('{message}', salaryState.message),
                                ),
                              );
                            }
                            return Center(child: Text(translations[language]?['noPayments'] ?? 'No payments for this month'));
                          },
                        );
                      } else if (employeeState is EmployeeError) {
                        return Center(
                          child: Text(
                            (translations[language]?['errorLoadingEmployees'] ?? 'Error loading employees: {message}')
                                .replaceFirst('{message}', employeeState.message),
                          ),
                        );
                      }
                      if (!isSuperAdmin && selectedSchoolId != null && employeeState is EmployeeInitial) {
                        context.read<EmployeeCubit>().fetchEmployees(schoolId: selectedSchoolId!, isSuperAdmin: isSuperAdmin);
                        context.read<SalaryCubit>().fetchSalaryPayments(selectedSchoolId!, _getSelectedMonthStringForQuery());
                      }
                      return Center(child: Text(translations[language]?['selectSchoolPrompt'] ?? 'Please select a school'));
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

  List<DropdownMenuItem<String>> _generateMonthYearOptions() {
    final monthsAr = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    final monthsFr = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (index) => currentYear - 5 + index);

    List<DropdownMenuItem<String>> options = [];
    for (var year in years) {
      for (int i = 0; i < 12; i++) {
        final month = language == 'ar' ? monthsAr[i] : monthsFr[i];
        options.add(DropdownMenuItem(
          value: '$month $year',
          child: Text('$month $year'),
        ));
      }
    }
    return options;
  }
}