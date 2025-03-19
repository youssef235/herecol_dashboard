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

  @override
  void initState() {
    super.initState();
    context.read<SalaryCubit>().fetchSalaryCategory(widget.schoolId, widget.employee.salaryCategoryId!);
  }

  @override
  void dispose() {
    overtimeController.dispose();
    notesController.dispose();
    partialPaymentController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('دفع راتب ${widget.employee.fullNameAr}'),
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
                  content: const Text('تم دفع الراتب بنجاح'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              Navigator.pop(context);
            } else if (state is SalaryError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                double overtimeRate = category.overtimeHourRate;
                totalSalary = totalSalary == 0 ? baseSalary : totalSalary;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildDetailRow(Icons.attach_money, 'الراتب الأساسي', '$baseSalary ${category.currency}'),
                                const Divider(),
                                _buildDetailRow(Icons.access_time, 'سعر الساعة الإضافية', '$overtimeRate ${category.currency}'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: overtimeController,
                          decoration: const InputDecoration(
                            labelText: 'عدد الساعات الإضافية',
                            hintText: 'أدخل عددًا صحيحًا',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final hours = int.tryParse(value) ?? 0;
                            setState(() {
                              totalSalary = baseSalary + (hours * overtimeRate) - (isPartialPayment ? (double.tryParse(partialPaymentController.text) ?? 0) : 0);
                            });
                          },
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
                                  totalSalary = baseSalary + ((int.tryParse(overtimeController.text) ?? 0) * overtimeRate);
                                });
                              },
                            ),
                            const Text('دفع جزئي'),
                          ],
                        ),
                        if (isPartialPayment)
                          TextField(
                            controller: partialPaymentController,
                            decoration: const InputDecoration(
                              labelText: 'المبلغ الجزئي',
                              hintText: 'أدخل المبلغ المدفوع',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final partialAmount = double.tryParse(value) ?? 0;
                              setState(() {
                                totalSalary = baseSalary + ((int.tryParse(overtimeController.text) ?? 0) * overtimeRate) - partialAmount;
                              });
                            },
                          ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: notesController,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات (اختياري)',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text('تاريخ الدفع: ${selectedPaymentDate.toString().split(' ')[0]}'),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () => _selectPaymentDate(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('اختر تاريخ'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _buildDetailRow(Icons.money, 'الراتب الإجمالي', '$totalSalary ${category.currency}'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final month = widget.selectedMonth;
                              final existingPayment = await FirebaseFirestore.instance
                                  .collection('schools')
                                  .doc(widget.schoolId)
                                  .collection('salaryPayments')
                                  .where('employeeId', isEqualTo: widget.employee.id)
                                  .where('month', isEqualTo: month)
                                  .get();

                              if (existingPayment.docs.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('تم دفع الراتب لهذا الشهر بالفعل'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (isPartialPayment && (double.tryParse(partialPaymentController.text) ?? 0) >= totalSalary) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('المبلغ الجزئي يجب أن يكون أقل من الإجمالي'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                                return;
                              }

                              final payment = SalaryPayment(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                employeeId: widget.employee.id,
                                baseSalary: baseSalary,
                                overtimeSalary: (int.tryParse(overtimeController.text) ?? 0) * overtimeRate,
                                totalSalary: totalSalary,
                                overtimeHours: int.tryParse(overtimeController.text) ?? 0,
                                month: month,
                                paymentDate: selectedPaymentDate,
                                isPaid: !isPartialPayment,
                                notes: notesController.text.isEmpty ? null : notesController.text,
                              );

                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('تأكيد الدفع'),
                                  content: Text('هل أنت متأكد من دفع ${isPartialPayment ? "جزء من " : ""}الراتب بقيمة $totalSalary ${category.currency}؟'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('إلغاء'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        context.read<SalaryCubit>().paySalary(payment, widget.schoolId);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('تأكيد'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.payment),
                            label: const Text('دفع الراتب'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const Center(child: Text('جارٍ التحميل...'));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      trailing: Text(
        value,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}