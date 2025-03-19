import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
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
  String selectedMonth = 'مارس 2025';
  String? selectedSchoolId;

  @override
  void initState() {
    super.initState();
    selectedSchoolId = widget.schoolId;
    final authState = context.read<AuthCubit>().state;
    final isSuperAdmin = authState is AuthAuthenticated && authState.role == 'admin';
    if (selectedSchoolId != null || isSuperAdmin) {
      context.read<EmployeeCubit>().fetchEmployees(schoolId: selectedSchoolId, isSuperAdmin: isSuperAdmin);
      if (selectedSchoolId != null) {
        context.read<SalaryCubit>().fetchSalaryPayments(selectedSchoolId!, selectedMonth);
      }
    }
  }

  void _payAllUnpaidSalaries(BuildContext context, List<Employee> employees, List<SalaryPayment> payments, String schoolId) {
    final unpaidEmployees = employees.where((e) => !payments.any((p) => p.employeeId == e.id && p.isPaid)).toList();
    if (unpaidEmployees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد رواتب غير مدفوعة')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('دفع جميع الرواتب غير المدفوعة'),
        content: Text('هل تريد دفع رواتب ${unpaidEmployees.length} موظفين غير مدفوعة لشهر $selectedMonth؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              for (var employee in unpaidEmployees) {
                final category = await context.read<SalaryCubit>().fetchSalaryCategorySync(schoolId, employee.salaryCategoryId!);
                final payment = SalaryPayment(
                  id: DateTime.now().millisecondsSinceEpoch.toString() + employee.id,
                  employeeId: employee.id,
                  baseSalary: category.fullTimeSalary,
                  overtimeSalary: 0,
                  totalSalary: category.fullTimeSalary,
                  overtimeHours: 0,
                  month: selectedMonth,
                  paymentDate: DateTime.now(),
                  isPaid: true,
                );
                context.read<SalaryCubit>().paySalary(payment, schoolId);
              }
              Navigator.pop(context);
            },
            child: const Text('دفع الكل'),
          ),
        ],
      ),
    );
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
          title: const Text('تتبع دفع الرواتب / Suivi des paiements de salaire'),
          backgroundColor: Colors.blueAccent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.payment),
              onPressed: () {
                final employeeState = context.read<EmployeeCubit>().state;
                final salaryState = context.read<SalaryCubit>().state;
                if (employeeState is EmployeeLoaded && salaryState is SalaryPaymentsLoaded && selectedSchoolId != null) {
                  _payAllUnpaidSalaries(context, employeeState.employees, salaryState.payments, selectedSchoolId!);
                }
              },
              tooltip: 'دفع جميع الرواتب غير المدفوعة',
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
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('لا توجد مدارس متاحة'),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'اختر المدرسة / Choisir l’école',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          value: selectedSchoolId,
                          items: uniqueSchools.map((school) {
                            return DropdownMenuItem(
                              value: school.schoolId,
                              child: Text(school.schoolName['ar'] ?? 'غير متوفر'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSchoolId = value;
                              if (value != null) {
                                context.read<EmployeeCubit>().fetchEmployees(schoolId: value, isSuperAdmin: isSuperAdmin);
                                context.read<SalaryCubit>().fetchSalaryPayments(value, selectedMonth);
                              }
                            });
                          },
                        ),
                      );
                    }
                    if (schoolState is SchoolError) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('خطأ في جلب المدارس: ${schoolState.message}'),
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
                        value: selectedMonth.split(' ')[0],
                        items: ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']
                            .map((month) => DropdownMenuItem(value: month, child: Text(month)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedMonth = '$value ${selectedMonth.split(' ')[1]}';
                            if (selectedSchoolId != null) {
                              context.read<SalaryCubit>().fetchSalaryPayments(selectedSchoolId!, selectedMonth);
                            }
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'اختر الشهر / Choisir le mois',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedMonth.split(' ')[1],
                        items: List.generate(5, (index) => (2025 + index).toString())
                            .map((year) => DropdownMenuItem(value: year, child: Text(year)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedMonth = '${selectedMonth.split(' ')[0]} $value';
                            if (selectedSchoolId != null) {
                              context.read<SalaryCubit>().fetchSalaryPayments(selectedSchoolId!, selectedMonth);
                            }
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'اختر السنة / Choisir l’année',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
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
                          return const Center(child: Text('لا يوجد موظفين متاحين لهذه المدرسة'));
                        }
                        if (selectedSchoolId != null) {
                          context.read<SalaryCubit>().fetchSalaryPayments(selectedSchoolId!, selectedMonth);
                        }
                        return BlocBuilder<SalaryCubit, SalaryState>(
                          builder: (context, salaryState) {
                            if (salaryState is SalaryLoading) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (salaryState is SalaryPaymentsLoaded) {
                              return ListView.builder(
                                itemCount: employeeState.employees.length,
                                itemBuilder: (context, index) {
                                  final employee = employeeState.employees[index];
                                  final payment = salaryState.payments.firstWhereOrNull((p) => p.employeeId == employee.id);
                                  final isPaid = payment?.isPaid ?? false;
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    elevation: 2,
                                    child: ListTile(
                                      title: Text(employee.fullNameAr),
                                      subtitle: Text('القسم: ${employee.departmentAr} | الحالة: ${isPaid ? "مدفوع" : "غير مدفوع"}'),
                                      trailing: ElevatedButton(
                                        onPressed: isPaid
                                            ? null
                                            : () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PaySalaryScreen(
                                              employee: employee,
                                              schoolId: selectedSchoolId!,
                                              selectedMonth: selectedMonth,
                                            ),
                                          ),
                                        ).then((_) {
                                          if (selectedSchoolId != null) {
                                            context.read<SalaryCubit>().fetchSalaryPayments(selectedSchoolId!, selectedMonth);
                                          }
                                        }),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueAccent,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('دفع الراتب'),
                                      ),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SalaryDetailsScreen(
                                            employee: employee,
                                            payment: payment,
                                            schoolId: selectedSchoolId!,
                                          ),
                                        ),
                                      ).then((_) {
                                        if (selectedSchoolId != null) {
                                          context.read<SalaryCubit>().fetchSalaryPayments(selectedSchoolId!, selectedMonth);
                                        }
                                      }),
                                    ),
                                  );
                                },
                              );
                            } else if (salaryState is SalaryError) {
                              return Center(child: Text('خطأ في جلب دفعات الرواتب: ${salaryState.message}'));
                            }
                            return const Center(child: Text('لا توجد دفعات رواتب لهذا الشهر'));
                          },
                        );
                      } else if (employeeState is EmployeeError) {
                        return Center(child: Text('خطأ في جلب الموظفين: ${employeeState.message}'));
                      }
                      if (!isSuperAdmin && selectedSchoolId != null && employeeState is EmployeeInitial) {
                        context.read<EmployeeCubit>().fetchEmployees(schoolId: selectedSchoolId!, isSuperAdmin: isSuperAdmin);
                        context.read<SalaryCubit>().fetchSalaryPayments(selectedSchoolId!, selectedMonth);
                      }
                      return const Center(child: Text('يرجى اختيار مدرسة'));
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