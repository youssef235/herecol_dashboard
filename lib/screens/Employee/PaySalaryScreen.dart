import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/salary/salary_cubit.dart';
import '../../cubit/salary/salary_state.dart';
import '../../models/SalaryPayment.dart';
import '../../models/employee_model.dart';

class PaySalaryScreen extends StatefulWidget {
  final Employee employee;
  final String schoolId;
  final String selectedMonth;

  const PaySalaryScreen({
    required this.employee,
    required this.schoolId,
    required this.selectedMonth,
  });

  @override
  _PaySalaryScreenState createState() => _PaySalaryScreenState();
}

class _PaySalaryScreenState extends State<PaySalaryScreen> {
  final overtimeController = TextEditingController();
  final notesController = TextEditingController();
  final partialPaymentController = TextEditingController();
  double totalSalary = 0;
  DateTime selectedPaymentDate = DateTime.now();
  bool isPartialPayment = false;
  SalaryPayment? existingPayment; // لتخزين الدفعة السابقة إن وجدت
  double remainingAmount = 0; // المبلغ المتبقي

  @override
  void initState() {
    super.initState();
    _checkExistingPayment(); // التحقق من الدفعات السابقة
    context.read<SalaryCubit>().fetchSalaryCategory(widget.schoolId, widget.employee.salaryCategoryId!);
  }

  @override
  void dispose() {
    overtimeController.dispose();
    notesController.dispose();
    partialPaymentController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingPayment() async {
    final month = widget.selectedMonth;
    final snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('salaryPayments')
        .where('employeeId', isEqualTo: widget.employee.id)
        .where('month', isEqualTo: month)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      setState(() {
        existingPayment = SalaryPayment.fromMap(data, snapshot.docs.first.id);
        if (existingPayment!.status == PaymentStatus.partiallyPaid) {
          remainingAmount = existingPayment!.totalSalary - (existingPayment!.partialAmount ?? 0);
          partialPaymentController.text = remainingAmount.toString(); // عرض المتبقي كقيمة افتراضية
          isPartialPayment = true; // تعيين الدفع الجزئي كافتراضي
        }
      });
    }
  }

  Future<void> _selectPaymentDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedPaymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedPaymentDate) {
      setState(() {
        selectedPaymentDate = picked;
      });
    }
  }

  void _calculateTotalSalary(double baseSalary, double overtimeRate) {
    final hours = int.tryParse(overtimeController.text) ?? 0;
    final partialAmount = isPartialPayment ? (double.tryParse(partialPaymentController.text) ?? 0) : 0;
    final fullSalary = baseSalary + (hours * overtimeRate);
    setState(() {
      totalSalary = isPartialPayment ? partialAmount.toDouble() : fullSalary.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'دفع راتب ${widget.employee.fullNameAr} / Paiement salaire ${widget.employee.fullNameFr ?? widget.employee.fullNameAr}',
          style: const TextStyle(fontSize: 18),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
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
            if (state is SalaryPaid) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    existingPayment != null && existingPayment!.status == PaymentStatus.partiallyPaid
                        ? 'تم تحديث الدفع الجزئي بنجاح / Mise à jour du paiement partiel réussie'
                        : 'تم دفع الراتب بنجاح / Paiement du salaire effectué avec succès',
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
              Navigator.pop(context);
            } else if (state is SalaryError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          },
          child: BlocBuilder<SalaryCubit, SalaryState>(
            builder: (context, state) {
              if (state is SalaryLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is SalaryCategoryLoaded) {
                final category = state.category;
                double baseSalary = category.fullTimeSalary;
                double overtimeRate = category.overtimeHourRate ?? 0;
                final fullSalary = baseSalary + ((int.tryParse(overtimeController.text) ?? 0) * overtimeRate);
                totalSalary = totalSalary == 0 ? fullSalary : totalSalary;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildDetailRow(Icons.attach_money, 'الراتب الأساسي', 'Salaire de base', '$baseSalary CFA'),
                                const Divider(),
                                _buildDetailRow(Icons.access_time, 'سعر الساعة الإضافية', 'Taux horaire supplémentaire', '$overtimeRate CFA'),
                                if (existingPayment != null && existingPayment!.status == PaymentStatus.partiallyPaid) ...[
                                  const Divider(),
                                  _buildDetailRow(Icons.money_off, 'المتبقي', 'Restant', '$remainingAmount CFA'),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: overtimeController,
                          decoration: const InputDecoration(
                            labelText: 'عدد الساعات الإضافية / Nombre d’heures supplémentaires',
                            hintText: 'أدخل عددًا صحيحًا / Entrez un nombre entier',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => _calculateTotalSalary(baseSalary, overtimeRate),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Checkbox(
                              value: isPartialPayment,
                              onChanged: (value) {
                                setState(() {
                                  isPartialPayment = value!;
                                  if (!isPartialPayment) partialPaymentController.clear();
                                  _calculateTotalSalary(baseSalary, overtimeRate);
                                });
                              },
                            ),
                            const Text(
                              'دفع جزئي / Paiement partiel',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        if (isPartialPayment)
                          TextField(
                            controller: partialPaymentController,
                            decoration: InputDecoration(
                              labelText: 'المبلغ الجزئي / Montant partiel (CFA)',
                              hintText: existingPayment != null && existingPayment!.status == PaymentStatus.partiallyPaid
                                  ? 'أدخل مبلغًا لدفع المتبقي أو جزء آخر / Entrez un montant pour le restant ou une autre partie'
                                  : 'أدخل المبلغ المدفوع / Entrez le montant payé',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => _calculateTotalSalary(baseSalary, overtimeRate),
                          ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: notesController,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات / Notes (اختياري / facultatif)',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'تاريخ الدفع / Date de paiement: ${selectedPaymentDate.toString().split(' ')[0]}',
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () => _selectPaymentDate(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('اختر تاريخ / Choisir une date'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _buildDetailRow(Icons.money, 'الراتب الإجمالي', 'Salaire total', '$fullSalary CFA'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final month = widget.selectedMonth;
                              final overtimeHours = int.tryParse(overtimeController.text) ?? 0;
                              final partialAmount = isPartialPayment ? (double.tryParse(partialPaymentController.text) ?? 0) : 0;

                              if (isPartialPayment && partialAmount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('المبلغ الجزئي يجب أن يكون أكبر من صفر / Le montant partiel doit être supérieur à zéro'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                                return;
                              }

                              double newPartialAmount = partialAmount.toDouble();
                              PaymentStatus newStatus = isPartialPayment ? PaymentStatus.partiallyPaid : PaymentStatus.paid;
                              String updatedNotes = '';

                              if (existingPayment != null && existingPayment!.status == PaymentStatus.partiallyPaid) {
                                // تحديث الدفعة الجزئية السابقة
                                final previousPartial = existingPayment!.partialAmount ?? 0;
                                newPartialAmount = (previousPartial + partialAmount).toDouble();

                                if (newPartialAmount > fullSalary) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('المبلغ الجزئي المحدث يتجاوز الراتب الإجمالي / Le montant partiel dépasse le salaire total'),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                  return;
                                }

                                newStatus = newPartialAmount >= fullSalary ? PaymentStatus.paid : PaymentStatus.partiallyPaid;
                                updatedNotes = 'تم دفع جزء إضافي: $partialAmount CFA، الإجمالي المدفوع: $newPartialAmount CFA من $fullSalary CFA، '
                                    'المتبقي: ${fullSalary - newPartialAmount} CFA / '
                                    'Paiement partiel supplémentaire: $partialAmount CFA, total payé: $newPartialAmount CFA sur $fullSalary CFA, '
                                    'restant: ${fullSalary - newPartialAmount} CFA';
                              } else if (isPartialPayment && partialAmount >= fullSalary) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('المبلغ الجزئي يجب أن يكون أقل من الإجمالي / Le montant partiel doit être inférieur au total'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                                return;
                              } else {
                                // دفعة جديدة
                                updatedNotes = isPartialPayment
                                    ? 'تم دفع جزء: $partialAmount CFA من $fullSalary CFA، المتبقي: ${fullSalary - partialAmount} CFA / '
                                    'Paiement partiel: $partialAmount CFA sur $fullSalary CFA, restant: ${fullSalary - partialAmount} CFA'
                                    : notesController.text.isEmpty
                                    ? ''
                                    : notesController.text;
                              }

                              final payment = SalaryPayment(
                                id: existingPayment?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                employeeId: widget.employee.id,
                                baseSalary: baseSalary,
                                overtimeSalary: overtimeHours * overtimeRate,
                                totalSalary: fullSalary,
                                overtimeHours: overtimeHours,
                                month: month,
                                paymentDate: selectedPaymentDate,
                                status: newStatus,
                                partialAmount: isPartialPayment || newStatus == PaymentStatus.partiallyPaid ? newPartialAmount : null,
                                notes: updatedNotes,
                              );

                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('تأكيد الدفع / Confirmation du paiement'),
                                  content: Text(
                                    'هل أنت متأكد من دفع ${isPartialPayment ? "جزء من " : ""}الراتب بقيمة $partialAmount CFA؟\n'
                                        'المتبقي بعد الدفع: ${fullSalary - newPartialAmount} CFA\n'
                                        'Êtes-vous sûr de payer ${isPartialPayment ? "une partie du " : ""}salaire de $partialAmount CFA ? '
                                        'Restant après paiement: ${fullSalary - newPartialAmount} CFA',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('إلغاء / Annuler'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (existingPayment != null && existingPayment!.status == PaymentStatus.partiallyPaid) {
                                          // تحديث الدفعة الحالية
                                          FirebaseFirestore.instance
                                              .collection('schools')
                                              .doc(widget.schoolId)
                                              .collection('salaryPayments')
                                              .doc(existingPayment!.id)
                                              .update(payment.toMap())
                                              .then((_) {
                                            context.read<SalaryCubit>().paySalary(payment, widget.schoolId);
                                            Navigator.pop(context);
                                          });
                                        } else {
                                          // إنشاء دفعة جديدة
                                          context.read<SalaryCubit>().paySalary(payment, widget.schoolId);
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: const Text('تأكيد / Confirmer'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.payment),
                            label: const Text('دفع الراتب / Payer le salaire'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const Center(child: Text('جارٍ التحميل... / Chargement en cours...'));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String titleAr, String titleFr, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(
        '$titleAr / $titleFr',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      trailing: Text(
        value,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}