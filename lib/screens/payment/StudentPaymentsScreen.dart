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
  String? selectedInstallmentId;
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
  }

  void _addPayment(StudentCubit cubit, List<Installment> installments, double feesDue, double feesPaid) {
    if (selectedInstallmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار قسط أولاً')),
      );
      return;
    }

    final selectedInstallment = installments.firstWhere((i) => i.id == selectedInstallmentId);
    final amount = selectedInstallment.amount;

    // التحقق مما إذا كان القسط مدفوعًا مسبقًا
    final alreadyPaid = payments.any((p) => p.amount == amount && p.date.toString().substring(0, 10) == selectedInstallment.dueDate.toString().substring(0, 10));
    if (alreadyPaid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا القسط مدفوع مسبقًا')),
      );
      return;
    }

    final date = DateTime.now();

    cubit.addPayment(
      schoolId: widget.schoolId,
      studentId: widget.studentId,
      amount: amount,
      date: date,
    );

    final newFeesPaid = feesPaid + amount;
    final newFeesDue = feesDue - amount;

    cubit.updateStudentFees(
      schoolId: widget.schoolId,
      studentId: widget.studentId,
      feesDue: newFeesDue > 0 ? newFeesDue : 0,
      feesPaid: newFeesPaid,
    );

    setState(() {
      selectedInstallmentId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مدفوعات الطالب / Paiements de l’étudiant',
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
        child: BlocConsumer<StudentCubit, StudentState>(
          listener: (context, state) {
            if (state is PaymentAdded) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تسجيل الدفعة بنجاح')),
              );
              context.read<StudentCubit>().fetchStudentDetails(
                schoolId: widget.schoolId,
                studentId: widget.studentId,
              );
              context.read<StudentCubit>().fetchPayments(
                schoolId: widget.schoolId,
                studentId: widget.studentId,
              );
            } else if (state is PaymentsLoaded) {
              setState(() {
                payments = state.payments;
              });
            } else if (state is StudentError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is StudentLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is StudentLoaded) {
              final student = state.student;
              final availableInstallments = student.feeStructure?.installments ?? [];

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
                              'الاسم: ${student.firstNameAr} ${student.lastNameAr} / ${student.firstNameFr} ${student.lastNameFr}'),
                          Text('المبلغ المستحق: ${student.feesDue ?? 0}'),
                          Text('المبلغ المدفوع: ${student.feesPaid ?? 0}'),
                          const SizedBox(height: 10),
                          Text(
                            'المبلغ المتبقي: ${(student.feesDue ?? 0) - (student.feesPaid ?? 0)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
                          ),
                          const SizedBox(height: 20),
                          _buildSectionTitle('تسجيل دفعة جديدة / Enregistrer un nouveau paiement'),
                          if (availableInstallments.isEmpty)
                            const Text('لا توجد أقساط متاحة لهذا الطالب')
                          else
                            DropdownButtonFormField<String>(
                              decoration: _buildInputDecoration('اختر القسط / Choisir la tranche'),
                              value: selectedInstallmentId,
                              items: availableInstallments.map((installment) {
                                return DropdownMenuItem(
                                  value: installment.id,
                                  child: Text(
                                    'قسط ${installment.amount} - ${installment.dueDate.toString().substring(0, 10)}',
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedInstallmentId = value;
                                });
                              },
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: availableInstallments.isEmpty
                                  ? null
                                  : () => _addPayment(
                                context.read<StudentCubit>(),
                                availableInstallments,
                                student.feesDue ?? 0,
                                student.feesPaid ?? 0,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                'تسجيل الدفع / Enregistrer le paiement',
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
                              ? const Text('لا توجد مدفوعات مسجلة بعد')
                              : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: payments.length,
                            itemBuilder: (context, index) {
                              final payment = payments[index];
                              return ListTile(
                                title: Text('المبلغ: ${payment.amount}'),
                                subtitle:
                                Text('التاريخ: ${payment.date.toString().substring(0, 10)}'),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text('يرجى الانتظار أو تحديث الصفحة'));
          },
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
}