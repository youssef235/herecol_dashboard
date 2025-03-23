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
        title: Text(
          'تفاصيل راتب ${employee.fullNameAr} / Détails du salaire de ${employee.fullNameAr}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (payment != null) ...[
                  Card(
                    elevation: 6,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.grey.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              Icons.attach_money,
                              'الراتب الأساسي / Salaire de base',
                              '${payment!.baseSalary} CFA',
                            ),
                            const Divider(height: 20),
                            _buildDetailRow(
                              Icons.access_time,
                              'راتب الساعات الإضافية / Salaire des heures supplémentaires',
                              '${payment!.overtimeSalary} CFA',
                            ),
                            const Divider(height: 20),
                            _buildDetailRow(
                              Icons.money_off,
                              'الراتب الإجمالي / Salaire total',
                              '${payment!.totalSalary} CFA',
                            ),
                            const Divider(height: 20),
                            _buildDetailRow(
                              Icons.timer,
                              'عدد الساعات الإضافية / Nombre d\'heures supplémentaires',
                              '${payment!.overtimeHours}',
                            ),
                            const Divider(height: 20),
                            _buildDetailRow(
                              Icons.calendar_today,
                              'الشهر / Mois',
                              payment!.month,
                            ),
                            const Divider(height: 20),
                            _buildDetailRow(
                              Icons.date_range,
                              'تاريخ الدفع / Date de paiement',
                              payment!.paymentDate.toString().split(' ')[0],
                            ),
                            const Divider(height: 20),
                            _buildDetailRow(
                              payment!.status == PaymentStatus.paid
                                  ? Icons.check_circle
                                  : payment!.status == PaymentStatus.partiallyPaid
                                  ? Icons.hourglass_bottom
                                  : Icons.cancel,
                              'الحالة / Statut',
                              payment!.status == PaymentStatus.paid
                                  ? 'مدفوع / Payé'
                                  : payment!.status == PaymentStatus.partiallyPaid
                                  ? 'مدفوع جزئيًا: ${payment!.partialAmount} CFA، المتبقي: ${payment!.totalSalary - (payment!.partialAmount ?? 0)} CFA / '
                                  'Partiellement payé: ${payment!.partialAmount} CFA, restant: ${payment!.totalSalary - (payment!.partialAmount ?? 0)} CFA'
                                  : 'غير مدفوع / Non payé',
                              color: payment!.status == PaymentStatus.paid
                                  ? Colors.green
                                  : payment!.status == PaymentStatus.partiallyPaid
                                  ? Colors.orange
                                  : Colors.red,
                            ),
                            if (payment!.notes != null) ...[
                              const Divider(height: 20),
                              _buildDetailRow(
                                Icons.note,
                                'ملاحظات / Notes',
                                payment!.notes!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        PaymentStatus newStatus;
                        if (payment!.status == PaymentStatus.paid) {
                          newStatus = PaymentStatus.unpaid;
                        } else if (payment!.status == PaymentStatus.partiallyPaid) {
                          newStatus = PaymentStatus.unpaid;
                        } else {
                          newStatus = PaymentStatus.paid;
                        }
                        context.read<SalaryCubit>().updatePaymentStatus(schoolId, payment!.id, newStatus);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              newStatus == PaymentStatus.paid
                                  ? 'تم تغيير الحالة إلى مدفوع / Statut changé en Payé'
                                  : 'تم تغيير الحالة إلى غير مدفوع / Statut changé en Non payé',
                            ),
                            backgroundColor: newStatus == PaymentStatus.paid ? Colors.green : Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 6,
                          ),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: payment!.status == PaymentStatus.paid || payment!.status == PaymentStatus.partiallyPaid
                            ? Colors.redAccent
                            : Colors.greenAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 5,
                      ),
                      icon: Icon(
                        payment!.status == PaymentStatus.paid || payment!.status == PaymentStatus.partiallyPaid
                            ? Icons.cancel
                            : Icons.check_circle,
                        size: 28,
                      ),
                      label: Text(
                        payment!.status == PaymentStatus.paid || payment!.status == PaymentStatus.partiallyPaid
                            ? 'تغيير إلى غير مدفوع / Changer en Non payé'
                            : 'تغيير إلى مدفوع / Changer en Payé',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ] else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.money_off, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 20),
                        Text(
                          'لم يتم دفع الراتب بعد / Le salaire n\'a pas encore été payé',
                          style: TextStyle(fontSize: 20, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.blueAccent, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, color: color ?? Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}