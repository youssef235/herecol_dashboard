import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/student/student_cubit.dart';
import '../../cubit/student/student_state.dart';
import '../../models/Payment.dart';
import '../../models/fee_structure_model.dart';

class StudentPaymentsScreen extends StatefulWidget {
  final String schoolId;
  final String studentId;

  const StudentPaymentsScreen({required this.schoolId, required this.studentId});

  @override
  _StudentPaymentsScreenState createState() => _StudentPaymentsScreenState();
}

class _StudentPaymentsScreenState extends State<StudentPaymentsScreen> {
  List<String> selectedInstallmentIds = [];
  List<Payment> payments = [];

  @override
  void initState() {
    super.initState();
    context.read<StudentCubit>().fetchStudentDetails(
      schoolId: widget.schoolId,
      studentId: widget.studentId,
    );
    context.read<StudentCubit>().fetchPayments(
      schoolId: widget.schoolId,
      studentId: widget.studentId,
    );
    context.read<StudentCubit>().fetchFeeStructures(widget.schoolId);
  }

  void _addPayments(StudentCubit cubit, List<Installment> installments, double totalFeesDue, double feesPaid) async {
    if (selectedInstallmentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار قسط واحد على الأقل / Veuillez sélectionner au moins un paiement')),
      );
      return;
    }

    final date = DateTime.now();
    double totalNewPayment = 0;

    for (var installmentId in selectedInstallmentIds) {
      final selectedInstallment = installments.firstWhere((i) => i.id == installmentId);
      final amount = selectedInstallment.amount;

      final alreadyPaid = payments.any((p) => p.id == installmentId);
      if (alreadyPaid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('القسط ${selectedInstallment.amount} مدفوع مسبقًا / Paiement déjà effectué')),
        );
        continue;
      }

      cubit.addPayment(
        schoolId: widget.schoolId,
        studentId: widget.studentId,
        amount: amount,
        date: date,
        installmentId: installmentId,
      );
      totalNewPayment += amount;
    }

    final newFeesPaid = feesPaid + totalNewPayment;

    cubit.updateStudentFees(
      schoolId: widget.schoolId,
      studentId: widget.studentId,
      totalFeesDue: totalFeesDue,
      feesPaid: newFeesPaid,
    );

    setState(() {
      selectedInstallmentIds.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تسجيل الدفعات بنجاح / Paiements enregistrés avec succès')),
    );
  }

  void _showEditPaymentDialog(Payment payment) {
    double newAmount = payment.amount;
    DateTime newDate = payment.date;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الدفعة / Modifier le paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المبلغ / Montant'),
              onChanged: (value) => newAmount = double.tryParse(value) ?? payment.amount,
              controller: TextEditingController(text: payment.amount.toString()),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: newDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) setState(() => newDate = pickedDate);
              },
              child: Text('تاريخ جديد / Nouvelle date: ${newDate.toString().substring(0, 10)}'),
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
              context.read<StudentCubit>().editPayment(
                schoolId: widget.schoolId,
                studentId: widget.studentId,
                paymentId: payment.id,
                newAmount: newAmount,
                newDate: newDate,
              );
              Navigator.pop(context);
            },
            child: const Text('حفظ / Sauvegarder'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مدفوعات الطالب / Paiements de l’étudiant',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.blueAccent.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: BlocConsumer<StudentCubit, StudentState>(
          listener: (context, state) {
            if (state is PaymentAdded || state is PaymentUpdated || state is PaymentDeleted || state is PaymentMarkedUnpaid) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state is PaymentAdded
                        ? 'تم تسجيل الدفعات بنجاح / Paiements enregistrés avec succès'
                        : state is PaymentUpdated
                        ? 'تم تعديل الدفعة بنجاح / Paiement modifié avec succès'
                        : state is PaymentDeleted
                        ? 'تم حذف الدفعة بنجاح / Paiement supprimé avec succès'
                        : 'تم تغيير الحالة إلى غير مدفوع / Changé à non payé',
                  ),
                  backgroundColor: state is PaymentDeleted || state is PaymentMarkedUnpaid ? Colors.red : Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
              context.read<StudentCubit>().fetchStudentDetails(schoolId: widget.schoolId, studentId: widget.studentId);
              context.read<StudentCubit>().fetchPayments(schoolId: widget.schoolId, studentId: widget.studentId);
            } else if (state is PaymentsLoaded) {
              setState(() => payments = state.payments);
            } else if (state is StudentError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is StudentLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is StudentLoaded) {
              final student = state.student;

              return BlocBuilder<StudentCubit, StudentState>(
                builder: (context, feeState) {
                  double calculatedTotalFeesDue = student.totalFeesDue ?? 0.0;
                  List<Installment> allInstallments = student.feeStructure?.installments ?? [];

                  if (feeState is FeeStructuresLoaded) {
                    final feeStructure = feeState.feeStructures.firstWhere(
                          (fs) => fs.gradeAr == student.gradeAr,
                      orElse: () => FeeStructure(
                        id: '',
                        gradeAr: student.gradeAr,
                        gradeFr: student.gradeFr,
                        installments: [],
                        installmentCount: 0,
                      ),
                    );

                    if (feeStructure.installments.isNotEmpty) {
                      allInstallments = feeStructure.installments;
                      calculatedTotalFeesDue = feeStructure.installments.fold(
                        0.0,
                            (sum, installment) => sum + installment.amount,
                      );

                      if (student.totalFeesDue == null || student.totalFeesDue == 0.0) {
                        context.read<StudentCubit>().updateStudentFees(
                          schoolId: widget.schoolId,
                          studentId: widget.studentId,
                          totalFeesDue: calculatedTotalFeesDue,
                          feesPaid: student.feesPaid ?? 0.0,
                        );
                      }
                    }
                  }

                  final unpaidInstallments = allInstallments.where((installment) {
                    return !payments.any((payment) => payment.id == installment.id);
                  }).toList();

                  final remainingAmount = calculatedTotalFeesDue - (student.feesPaid ?? 0);

                  return SingleChildScrollView(
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
                              _buildSectionTitle('معلومات الطالب / Informations de l’étudiant'),
                              Text(
                                'الاسم: ${student.firstNameAr} ${student.lastNameAr} / ${student.firstNameFr} ${student.lastNameFr}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                'الصف: ${student.gradeAr} / ${student.gradeFr}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                'المبلغ الإجمالي المستحق / Total dû: $calculatedTotalFeesDue',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                'المبلغ المدفوع / Montant payé: ${student.feesPaid ?? 0}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                remainingAmount >= 0
                                    ? 'المبلغ المتبقي / Montant restant: $remainingAmount'
                                    : 'تم الدفع بالكامل، المبلغ الزائد / Payé en totalité, excédent: ${-remainingAmount}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: remainingAmount >= 0 ? Colors.redAccent : Colors.green,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildSectionTitle('تسجيل دفعة جديدة / Enregistrer un nouveau paiement'),
                              if (unpaidInstallments.isEmpty)
                                const Text('جميع الأقساط مدفوعة / Tous les paiements sont effectués')
                              else
                                Column(
                                  children: unpaidInstallments.map((installment) {
                                    final isSelected = selectedInstallmentIds.contains(installment.id);
                                    return CheckboxListTile(
                                      title: Text(
                                        'قسط ${installment.amount} - ${installment.dueDate.toString().substring(0, 10)}',
                                      ),
                                      value: isSelected,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            selectedInstallmentIds.add(installment.id);
                                          } else {
                                            selectedInstallmentIds.remove(installment.id);
                                          }
                                        });
                                      },
                                      activeColor: Colors.blueAccent,
                                      checkColor: Colors.white,
                                    );
                                  }).toList(),
                                ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: unpaidInstallments.isEmpty
                                      ? null
                                      : () => _addPayments(
                                    context.read<StudentCubit>(),
                                    unpaidInstallments,
                                    calculatedTotalFeesDue,
                                    student.feesPaid ?? 0,
                                  ),
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
                                    'تسجيل الدفعات / Enregistrer les paiements',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                              _buildSectionTitle('سجل المدفوعات / Historique des paiements'),
                              payments.isEmpty
                                  ? const Text('لا توجد مدفوعات مسجلة بعد / Aucun paiement enregistré')
                                  : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: payments.length,
                                itemBuilder: (context, index) {
                                  final payment = payments[index];
                                  return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    child: ListTile(
                                      title: Text('المبلغ / Montant: ${payment.amount}'),
                                      subtitle: Text('التاريخ / Date: ${payment.date.toString().substring(0, 10)}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                            onPressed: () => _showEditPaymentDialog(payment),
                                            tooltip: 'تعديل / Modifier',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                                            onPressed: () {
                                              context.read<StudentCubit>().deletePayment(
                                                schoolId: widget.schoolId,
                                                studentId: widget.studentId,
                                                paymentId: payment.id,
                                                amount: payment.amount,
                                              );
                                            },
                                            tooltip: 'حذف / Supprimer',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.cancel, color: Colors.orange),
                                            onPressed: () {
                                              context.read<StudentCubit>().markPaymentAsUnpaid(
                                                schoolId: widget.schoolId,
                                                studentId: widget.studentId,
                                                paymentId: payment.id,
                                                amount: payment.amount,
                                              );
                                            },
                                            tooltip: 'جعله غير مدفوع / Marquer comme non payé',
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
            return const Center(child: Text('يرجى الانتظار أو تحديث الصفحة / Veuillez patienter ou rafraîchir'));
          },
        ),
      ),
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
}