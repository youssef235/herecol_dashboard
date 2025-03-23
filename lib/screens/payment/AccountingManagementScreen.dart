import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/auth/auth_cubit.dart';
import '../../cubit/auth/auth_state.dart';
import '../../cubit/salary/salary_cubit.dart';
import '../../cubit/school_info/school_info_cubit.dart';
import '../../cubit/school_info/school_info_state.dart';
import '../../cubit/student/student_cubit.dart';
import '../../cubit/student/student_state.dart';
import '../../models/fee_structure_model.dart';

class AccountingManagementScreen extends StatefulWidget {
  final String? schoolId;

  const AccountingManagementScreen({required this.schoolId});

  @override
  _AccountingManagementScreenState createState() => _AccountingManagementScreenState();
}

class _AccountingManagementScreenState extends State<AccountingManagementScreen> {
  List<Map<String, dynamic>> installments = [];
  String? _selectedSchoolId;
  String? _selectedGradeAr;
  String? _selectedGradeFr;
  int? _selectedInstallmentCount;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      if (authState.role == 'school') {
        _selectedSchoolId = widget.schoolId ?? authState.uid;
        context.read<SchoolCubit>().fetchSchools(_selectedSchoolId!, 'school');
        context.read<SalaryCubit>().fetchSalaryCategories(_selectedSchoolId!);
      } else if (authState.role == 'admin') {
        context.read<SchoolCubit>().fetchSchools(authState.uid, 'admin');
      } else if (authState.role == 'employee') {
        _selectedSchoolId = authState.schoolId;
        if (_selectedSchoolId != null) {
          context.read<SchoolCubit>().fetchSchools(_selectedSchoolId!, 'school');
          context.read<SalaryCubit>().fetchSalaryCategories(_selectedSchoolId!);
        }
      }
    }
  }

  void _addInstallmentField() {
    if (_selectedInstallmentCount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد عدد الأقساط أولاً')),
      );
      return;
    }
    if (installments.length >= _selectedInstallmentCount!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الوصول إلى الحد الأقصى لعدد الأقساط')),
      );
      return;
    }
    setState(() {
      installments.add({
        'amountController': TextEditingController(),
        'dueDate': DateTime.now(),
      });
    });
  }

  void _saveFeeStructure() async {
    if (_selectedSchoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار مدرسة أولاً')),
      );
      return;
    }
    if (_selectedGradeAr == null || _selectedGradeFr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الصف')),
      );
      return;
    }
    if (installments.isEmpty || installments.length != _selectedInstallmentCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال جميع الأقساط المحددة')),
      );
      return;
    }

    final feeStructureId = DateTime.now().millisecondsSinceEpoch.toString();
    final feeStructure = FeeStructure(
      id: feeStructureId,
      gradeAr: _selectedGradeAr!,
      gradeFr: _selectedGradeFr!,
      installments: installments.asMap().entries.map((entry) {
        final index = entry.key;
        final installment = entry.value;
        return Installment(
          id: '$feeStructureId-$index',
          amount: double.tryParse(installment['amountController'].text) ?? 0.0,
          dueDate: installment['dueDate'],
        );
      }).toList(),
      installmentCount: _selectedInstallmentCount!,
    );

    // حفظ هيكل المصاريف في Firestore
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(_selectedSchoolId)
        .collection('feeStructures')
        .doc(feeStructureId)
        .set(feeStructure.toFirestore());

    // تحديث جميع الطلاب في الصف المحدد
    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(_selectedSchoolId)
        .collection('students')
        .where('gradeAr', isEqualTo: _selectedGradeAr)
        .get();

    final totalFeesDue = feeStructure.installments.fold<double>(0, (sum, i) => sum + i.amount);

    for (var studentDoc in studentsSnapshot.docs) {
      await studentDoc.reference.update({
        'totalFeesDue': totalFeesDue,
      });
    }

    setState(() {
      _selectedGradeAr = null;
      _selectedGradeFr = null;
      _selectedInstallmentCount = null;
      for (var installment in installments) {
        installment['amountController'].dispose();
      }
      installments.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ هيكل المصاريف وتحديث الطلاب بنجاح')),
    );
  }
  void _addNewInstallment(FeeStructure feeStructure) async {
    final amountController = TextEditingController();
    DateTime dueDate = DateTime.now();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة قسط جديد / Ajouter une nouvelle tranche'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: _buildInputDecoration('المبلغ / Montant'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: dueDate,
                  firstDate: DateTime(2000), // يسمح باختيار تواريخ من سنة 2000 وما بعد
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  dueDate = pickedDate;
                  Navigator.pop(context, {
                    'amount': double.tryParse(amountController.text) ?? 0.0,
                    'dueDate': pickedDate,
                  });
                }
              },
              child: Text(
                'تاريخ الاستحقاق: ${dueDate.toString().substring(0, 10)}',
                style: const TextStyle(color: Colors.blueAccent),
              ),
            ),          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء / Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'amount': double.tryParse(amountController.text) ?? 0.0,
                  'dueDate': dueDate,
                });
              }
            },
            child: const Text('حفظ / Enregistrer'),
          ),
        ],
      ),
    );

    if (result != null) {
      final newInstallment = Installment(
        id: '${feeStructure.id}-${feeStructure.installments.length}', // معرف فريد باستخدام عدد الأقساط الحالي
        amount: result['amount'],
        dueDate: result['dueDate'],
      );

      final updatedInstallments = [...feeStructure.installments, newInstallment];
      final updatedFeeStructure = FeeStructure(
        id: feeStructure.id,
        gradeAr: feeStructure.gradeAr,
        gradeFr: feeStructure.gradeFr,
        installments: updatedInstallments,
        installmentCount: updatedInstallments.length,
      );

      context.read<StudentCubit>().addFeeStructure(
        schoolId: _selectedSchoolId!,
        feeStructure: updatedFeeStructure,
      );
    }
  }

  void _editInstallment(int index) async {
    final amountController = TextEditingController(
      text: installments[index]['amountController'].text,
    );
    DateTime dueDate = installments[index]['dueDate'];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل القسط / Modifier la tranche'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: _buildInputDecoration('المبلغ / Montant'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: dueDate,
                  firstDate: DateTime(2000), // يسمح باختيار تواريخ من سنة 2000 وما بعد
                  lastDate: DateTime(2100),

                );
                if (pickedDate != null) {
                  dueDate = pickedDate;
                  Navigator.pop(context, {
                    'amount': double.tryParse(amountController.text) ?? 0.0,
                    'dueDate': pickedDate,
                  });
                }
              },
              child: Text(
                'تاريخ الاستحقاق: ${dueDate.toString().substring(0, 10)}',
                style: const TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء / Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'amount': double.tryParse(amountController.text) ?? 0.0,
                  'dueDate': dueDate,
                });
              }
            },
            child: const Text('حفظ / Enregistrer'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        installments[index]['amountController'].text = result['amount'].toString();
        installments[index]['dueDate'] = result['dueDate'];
      });
    }
  }

  void _deleteInstallment(int index) {
    setState(() {
      installments[index]['amountController'].dispose();
      installments.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف القسط بنجاح / Tranche supprimée avec succès')),
    );
  }

  void _editExistingInstallment(FeeStructure feeStructure, int installmentIndex) async {
    final installment = feeStructure.installments[installmentIndex];
    final amountController = TextEditingController(text: installment.amount.toString());
    DateTime dueDate = installment.dueDate;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل القسط / Modifier la tranche'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: _buildInputDecoration('المبلغ / Montant'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: dueDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  dueDate = pickedDate;
                  Navigator.pop(context, {
                    'amount': double.tryParse(amountController.text) ?? 0.0,
                    'dueDate': pickedDate,
                  });
                }
              },
              child: Text(
                'تاريخ الاستحقاق: ${dueDate.toString().substring(0, 10)}',
                style: const TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء / Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'amount': double.tryParse(amountController.text) ?? 0.0,
                  'dueDate': dueDate,
                });
              }
            },
            child: const Text('حفظ / Enregistrer'),
          ),
        ],
      ),
    );

    if (result != null) {
      final updatedInstallments = List<Installment>.from(feeStructure.installments);
      updatedInstallments[installmentIndex] = Installment(
        id: installment.id,
        amount: result['amount'],
        dueDate: result['dueDate'],
      );

      final updatedFeeStructure = FeeStructure(
        id: feeStructure.id,
        gradeAr: feeStructure.gradeAr,
        gradeFr: feeStructure.gradeFr,
        installments: updatedInstallments,
        installmentCount: updatedInstallments.length,
      );

      context.read<StudentCubit>().updateFeeStructure(
        schoolId: _selectedSchoolId!,
        feeStructure: updatedFeeStructure,
      );
    }
  }

  void _deleteExistingInstallment(FeeStructure feeStructure, int installmentIndex) {
    final updatedInstallments = List<Installment>.from(feeStructure.installments);
    updatedInstallments.removeAt(installmentIndex);

    final updatedFeeStructure = FeeStructure(
      id: feeStructure.id,
      gradeAr: feeStructure.gradeAr,
      gradeFr: feeStructure.gradeFr,
      installments: updatedInstallments,
      installmentCount: updatedInstallments.length,
    );

    context.read<StudentCubit>().updateFeeStructure(
      schoolId: _selectedSchoolId!,
      feeStructure: updatedFeeStructure,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف القسط بنجاح / Tranche supprimée avec succès')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = BlocProvider.of<AuthCubit>(context).state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('يرجى تسجيل الدخول')));
    }
    final isSuperAdmin = authState.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إدارة المحاسبة / Gestion de la comptabilité',
          style: TextStyle(color: Colors.white),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 7,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('إعدادات هيكل المصاريف / Paramètres des frais'),
                    if (isSuperAdmin)
                      BlocBuilder<SchoolCubit, SchoolState>(
                        builder: (context, schoolState) {
                          if (schoolState is SchoolsLoaded) {
                            if (_selectedSchoolId == null && schoolState.schools.isNotEmpty) {
                              _selectedSchoolId = schoolState.schools.first.schoolId;
                              context.read<StudentCubit>().fetchFeeStructures(_selectedSchoolId!);
                            }
                            return DropdownButtonFormField<String>(
                              decoration: _buildInputDecoration('اختر المدرسة / Choisir l’école'),
                              value: _selectedSchoolId,
                              items: schoolState.schools.map((school) {
                                return DropdownMenuItem(
                                  value: school.schoolId,
                                  child: Text('${school.schoolName['ar'] ?? 'غير متوفر'} / ${school.schoolName['fr'] ?? 'Non disponible'}'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSchoolId = value;
                                  _selectedGradeAr = null;
                                  _selectedGradeFr = null;
                                  _selectedInstallmentCount = null;
                                  installments.clear();
                                  if (value != null) {
                                    context.read<StudentCubit>().fetchFeeStructures(value);
                                  }
                                });
                              },
                              validator: (value) => value == null ? 'مطلوب' : null,
                            );
                          } else if (schoolState is SchoolError) {
                            return Text(schoolState.message);
                          }
                          return const Center(child: CircularProgressIndicator());
                        },
                      ),
                    if (!isSuperAdmin)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: BlocBuilder<SchoolCubit, SchoolState>(
                          builder: (context, schoolState) {
                            if (schoolState is SchoolsLoaded) {
                              final school = schoolState.schools.firstWhere(
                                    (s) => s.schoolId == _selectedSchoolId,
                                orElse: () => schoolState.schools.first,
                              );
                              return Text(
                                'المدرسة: ${school.schoolName['ar'] ?? 'غير متوفر'} / ${school.schoolName['fr'] ?? 'Non disponible'}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    BlocBuilder<SchoolCubit, SchoolState>(
                      builder: (context, schoolState) {
                        if (schoolState is SchoolsLoaded && _selectedSchoolId != null) {
                          final school = schoolState.schools.firstWhere(
                                (s) => s.schoolId == _selectedSchoolId,
                            orElse: () => schoolState.schools.isNotEmpty ? schoolState.schools.first : null!,
                          );
                          final classesAr = school.classes['ar'] ?? [];
                          final classesFr = school.classes['fr'] ?? [];
                          return Column(
                            children: [
                              DropdownButtonFormField<String>(
                                decoration: _buildInputDecoration('الصف بالعربية'),
                                value: _selectedGradeAr,
                                items: classesAr.map((grade) {
                                  return DropdownMenuItem(
                                    value: grade,
                                    child: Text(grade),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGradeAr = value;
                                    final index = classesAr.indexOf(value!);
                                    _selectedGradeFr = classesFr[index];
                                    _selectedInstallmentCount = null;
                                    installments.clear();
                                  });
                                },
                                validator: (value) => value == null ? 'مطلوب' : null,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                decoration: _buildInputDecoration('الصف بالفرنسية'),
                                value: _selectedGradeFr,
                                items: classesFr.map((grade) {
                                  return DropdownMenuItem(
                                    value: grade,
                                    child: Text(grade),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGradeFr = value;
                                    final index = classesFr.indexOf(value!);
                                    _selectedGradeAr = classesAr[index];
                                    _selectedInstallmentCount = null;
                                    installments.clear();
                                  });
                                },
                                validator: (value) => value == null ? 'مطلوب' : null,
                              ),
                            ],
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      decoration: _buildInputDecoration('عدد الأقساط / Nombre de tranches'),
                      value: _selectedInstallmentCount,
                      items: List.generate(10, (index) => index + 1).map((count) {
                        return DropdownMenuItem(
                          value: count,
                          child: Text('$count'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedInstallmentCount = value;
                          installments.clear();
                        });
                      },
                      validator: (value) => value == null ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _addInstallmentField,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('إضافة قسط / Ajouter une tranche'),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: installments.length,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: installments[index]['amountController'],
                                    keyboardType: TextInputType.number,
                                    decoration: _buildInputDecoration('قيمة القسط / Montant'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 3,
                                  child: TextButton(
                                    onPressed: () async {
                                      final pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: installments[index]['dueDate'],
                                        firstDate:  DateTime(2000),
                                        lastDate: DateTime(2100),
                                      );
                                      if (pickedDate != null) {
                                        setState(() {
                                          installments[index]['dueDate'] = pickedDate;
                                        });
                                      }
                                    },
                                    child: Text(
                                      'تاريخ الاستحقاق: ${installments[index]['dueDate'].toString().substring(0, 10)}',
                                      style: const TextStyle(color: Colors.blueAccent),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () => _editInstallment(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteInstallment(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveFeeStructure,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'حفظ هيكل المصاريف / Enregistrer la structure des frais',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
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
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 7,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('هياكل المصاريف الحالية / Structures actuelles'),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('schools')
                          .doc(_selectedSchoolId)
                          .collection('feeStructures')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('لا توجد هياكل مصاريف'));
                        }
                        final feeStructures = snapshot.data!.docs.map((doc) {
                          return FeeStructure.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
                        }).toList();
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: feeStructures.length,
                          itemBuilder: (context, index) {
                            final feeStructure = feeStructures[index];
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${feeStructure.gradeAr} / ${feeStructure.gradeFr}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, color: Colors.blueAccent),
                                          onPressed: () => _addNewInstallment(feeStructure),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'عدد الأقساط: ${feeStructure.installmentCount}',
                                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: feeStructure.installments.asMap().entries.map((entry) {
                                        final i = entry.value;
                                        final installmentIndex = entry.key;
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.payment, size: 18, color: Colors.green),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () => _editExistingInstallment(feeStructure, installmentIndex),
                                                  child: Text(
                                                    '${i.amount} - ${i.dueDate.toString().substring(0, 10)}',
                                                    style: const TextStyle(fontSize: 14),
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.orange),
                                                onPressed: () => _editExistingInstallment(feeStructure, installmentIndex),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                onPressed: () => _deleteExistingInstallment(feeStructure, installmentIndex),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
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
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var installment in installments) {
      installment['amountController'].dispose();
    }
    super.dispose();
  }
}