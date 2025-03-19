import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/salary/salary_cubit.dart';
import '../../models/employee_model.dart';
import '../../models/SalaryPayment.dart';

class SalaryDetailsScreen extends StatelessWidget {
  final Employee employee;
  final SalaryPayment? payment;
  final String schoolId;

  const SalaryDetailsScreen({
    required this.employee,
    required this.payment,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل راتب ${employee.fullNameAr}'),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (payment != null) ...[
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildDetailRow(Icons.attach_money, 'الراتب الأساسي', '${payment!.baseSalary}'),
                          const Divider(),
                          _buildDetailRow(Icons.access_time, 'راتب الساعات الإضافية', '${payment!.overtimeSalary}'),
                          const Divider(),
                          _buildDetailRow(Icons.money_off, 'الراتب الإجمالي', '${payment!.totalSalary}'),
                          const Divider(),
                          _buildDetailRow(Icons.timer, 'عدد الساعات الإضافية', '${payment!.overtimeHours}'),
                          const Divider(),
                          _buildDetailRow(Icons.calendar_today, 'الشهر', payment!.month),
                          const Divider(),
                          _buildDetailRow(Icons.date_range, 'تاريخ الدفع', payment!.paymentDate.toString()),
                          const Divider(),
                          _buildDetailRow(
                            payment!.isPaid ? Icons.check_circle : Icons.cancel,
                            'الحالة',
                            payment!.isPaid ? "مدفوع" : "غير مدفوع",
                            color: payment!.isPaid ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<SalaryCubit>().updatePaymentStatus(schoolId, payment!.id, !payment!.isPaid);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(payment!.isPaid ? 'تم تغيير الحالة إلى غير مدفوع' : 'تم تغيير الحالة إلى مدفوع'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: payment!.isPaid ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: Icon(payment!.isPaid ? Icons.cancel : Icons.check_circle),
                      label: Text(payment!.isPaid ? 'تغيير إلى غير مدفوع' : 'تغيير إلى مدفوع'),
                    ),
                  ),
                ] else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.money_off, size: 50, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'لم يتم دفع الراتب بعد',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.blueAccent),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      trailing: Text(
        value,
        style: TextStyle(fontSize: 16, color: color ?? Colors.black),
      ),
    );
  }
}