import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/Employee/EmployeeCubit.dart';
import '../../cubit/Employee/EmployeeState.dart';
import '../../cubit/auth/auth_cubit.dart';
import '../../cubit/auth/auth_state.dart';
import '../../cubit/salary/salary_cubit.dart';
import '../../cubit/school_info/school_info_cubit.dart';
import '../../cubit/school_info/school_info_state.dart';
import '../../models/school_info_model.dart';
import 'dart:developer' as developer; // لإضافة السجلات

class EmployeeListWithFilterScreen extends StatefulWidget {
  final String? schoolId;

  const EmployeeListWithFilterScreen({this.schoolId});

  @override
  _EmployeeListWithFilterScreenState createState() => _EmployeeListWithFilterScreenState();
}

class _EmployeeListWithFilterScreenState extends State<EmployeeListWithFilterScreen> {
  String? selectedSchoolId;
  String? selectedDepartment;
  String? selectedSubDepartment;
  String _selectedLanguage = 'ar'; // الافتراضي العربية
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      if (authState.role == 'admin') {
        context.read<SchoolCubit>().fetchSchools(authState.uid, authState.role);
        context.read<EmployeeCubit>().fetchEmployees(isSuperAdmin: true);
      } else if (authState.role == 'school') {
        selectedSchoolId = widget.schoolId ?? authState.uid;
        developer.log('Initial selectedSchoolId for school: $selectedSchoolId');
        context.read<SchoolCubit>().fetchSchools(selectedSchoolId!, authState.role);
        context.read<EmployeeCubit>().fetchEmployees(schoolId: selectedSchoolId!, isSuperAdmin: false);
        context.read<SalaryCubit>().fetchSalaryCategories(selectedSchoolId!);
      } else if (authState.role == 'employee' && authState.schoolId != null) {
        selectedSchoolId = authState.schoolId;
        developer.log('Initial selectedSchoolId for employee: $selectedSchoolId');
        context.read<SchoolCubit>().fetchSchools(selectedSchoolId!, authState.role);
        context.read<EmployeeCubit>().fetchEmployees(schoolId: selectedSchoolId!, isSuperAdmin: false);
        context.read<SalaryCubit>().fetchSalaryCategories(selectedSchoolId!);
      } else {
        developer.log('No valid schoolId found for role: ${authState.role}');
      }
    }
  }

  void _filterEmployees() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      if (authState.role == 'school' && selectedSchoolId != null) {
        developer.log('Filtering employees with: schoolId=$selectedSchoolId, department=$selectedDepartment, subDepartment=$selectedSubDepartment');
        context.read<EmployeeCubit>().fetchEmployees(
          schoolId: selectedSchoolId!,
          isSuperAdmin: false,
          department: selectedDepartment,
          subDepartment: selectedSubDepartment,
        );
      } else if (authState.role == 'employee' && authState.schoolId != null) {
        selectedSchoolId = authState.schoolId;
        developer.log('Employee filtering employees with: schoolId=$selectedSchoolId, department=$selectedDepartment, subDepartment=$selectedSubDepartment');
        context.read<EmployeeCubit>().fetchEmployees(
          schoolId: selectedSchoolId!,
          isSuperAdmin: false,
          department: selectedDepartment,
          subDepartment: selectedSubDepartment,
        );
      } else if (authState.role == 'admin') {
        if (selectedSchoolId != null) {
          developer.log('Admin filtering employees with: schoolId=$selectedSchoolId, department=$selectedDepartment, subDepartment=$selectedSubDepartment');
          context.read<EmployeeCubit>().fetchEmployees(
            schoolId: selectedSchoolId!,
            isSuperAdmin: true,
            department: selectedDepartment,
            subDepartment: selectedSubDepartment,
          );
        } else {
          developer.log('Admin fetching all employees');
          context.read<EmployeeCubit>().fetchEmployees(isSuperAdmin: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('يرجى تسجيل الدخول / Veuillez vous connecter')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الموظفين / Liste des employés', style: TextStyle(color: Colors.white)),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('العربية'),
                    selected: _selectedLanguage == 'ar',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedLanguage = 'ar';
                          _resetSelectionsIfInvalid();
                          _filterEmployees();
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Français'),
                    selected: _selectedLanguage == 'fr',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedLanguage = 'fr';
                          _resetSelectionsIfInvalid();
                          _filterEmployees();
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 5, blurRadius: 7),
                  ],
                ),
                child: BlocBuilder<SchoolCubit, SchoolState>(
                  builder: (context, schoolState) {
                    if (schoolState is SchoolsLoaded) {
                      final schools = schoolState.schools;
                      if (schools.isEmpty) {
                        return const Center(child: Text('لا توجد مدارس متاحة / Aucune école disponible'));
                      }
                      if (authState.role == 'school' && schools.isNotEmpty) {
                        selectedSchoolId ??= widget.schoolId ?? authState.uid;
                        developer.log('Set selectedSchoolId from school role: $selectedSchoolId');
                      } else if (authState.role == 'employee' && schools.isNotEmpty) {
                        selectedSchoolId ??= authState.schoolId;
                        developer.log('Set selectedSchoolId from employee role: $selectedSchoolId');
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('فلترة الموظفين / Filtrer les employés'),
                          if (authState.role == 'admin') ...[
                            _buildDropdown(
                              label: 'المدرسة / École',
                              value: selectedSchoolId,
                              items: schools.map((school) {
                                return DropdownMenuItem(
                                  value: school.schoolId,
                                  child: Text(school.schoolName[_selectedLanguage] ?? ''),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedSchoolId = value;
                                  selectedDepartment = null;
                                  selectedSubDepartment = null;
                                  _filterEmployees();
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (selectedSchoolId != null) ...[
                            _buildDropdown(
                              label: 'القسم الرئيسي / Département principal',
                              value: selectedDepartment,
                              items: schools
                                  .firstWhere((school) => school.schoolId == selectedSchoolId)
                                  .mainSections[_selectedLanguage]!
                                  .map((dept) => DropdownMenuItem(value: dept, child: Text(dept)))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedDepartment = value;
                                  selectedSubDepartment = null;
                                  _filterEmployees();
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            if (selectedDepartment != null)
                              _buildDropdown(
                                label: 'القسم الفرعي / Sous-département',
                                value: selectedSubDepartment,
                                items: schools
                                    .firstWhere((school) => school.schoolId == selectedSchoolId)
                                    .subSections[_selectedLanguage]![selectedDepartment]!
                                    .map((subDept) => DropdownMenuItem(value: subDept, child: Text(subDept)))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedSubDepartment = value;
                                    _filterEmployees();
                                  });
                                },
                              ),
                          ],
                        ],
                      );
                    } else if (schoolState is SchoolError) {
                      return Center(child: Text(schoolState.message));
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 5, blurRadius: 7),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('قائمة الموظفين / Liste des employés'),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: _selectedLanguage == 'ar' ? 'ابحث بالاسم أو المعرف' : 'Rechercher par nom ou ID',
                          prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.blueAccent),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    BlocBuilder<EmployeeCubit, EmployeeState>(
                      builder: (context, state) {
                        if (state is EmployeeLoading) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (state is EmployeeLoaded) {
                          developer.log('Total employees loaded: ${state.employees.length}');
                          state.employees.forEach((employee) {
                            developer.log(
                                'Employee: ID=${employee.id}, schoolId=${employee.schoolId}, departmentAr=${employee.departmentAr}, subDepartmentAr=${employee.subDepartmentAr}');
                          });

                          final employees = state.employees
                              .where((employee) {
                            final schoolMatch = selectedSchoolId == null ||
                                employee.schoolId?.trim().toLowerCase() == selectedSchoolId!.trim().toLowerCase();
                            final deptMatch = selectedDepartment == null ||
                                (_selectedLanguage == 'ar'
                                    ? employee.departmentAr?.trim().toLowerCase() == selectedDepartment!.trim().toLowerCase()
                                    : employee.departmentFr?.trim().toLowerCase() == selectedDepartment!.trim().toLowerCase());
                            final subDeptMatch = selectedSubDepartment == null ||
                                (_selectedLanguage == 'ar'
                                    ? employee.subDepartmentAr?.trim().toLowerCase() == selectedSubDepartment!.trim().toLowerCase()
                                    : employee.subDepartmentFr?.trim().toLowerCase() == selectedSubDepartment!.trim().toLowerCase());
                            final searchMatch = _searchQuery.isEmpty ||
                                employee.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                employee.fullNameAr.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                (employee.fullNameFr?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

                            developer.log(
                                'Employee ${employee.id}: schoolMatch=$schoolMatch, deptMatch=$deptMatch, subDeptMatch=$subDeptMatch, searchMatch=$searchMatch');
                            return schoolMatch && deptMatch && subDeptMatch && searchMatch;
                          })
                              .toList();

                          if (employees.isEmpty) {
                            return Center(
                                child: Text(_selectedLanguage == 'ar' ? 'لا يوجد موظفون' : 'Aucun employé trouvé'));
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: (employees.length / 2).ceil(),
                            itemBuilder: (context, index) {
                              final startIndex = index * 2;
                              final endIndex = (startIndex + 2 < employees.length) ? startIndex + 2 : employees.length;
                              final rowEmployees = employees.sublist(startIndex, endIndex);

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: rowEmployees.asMap().entries.map((entry) {
                                    final employee = entry.value;
                                    return Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.blueAccent.shade100, Colors.white],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            // يمكن إضافة شاشة تفاصيل الموظف هنا إذا لزم الأمر
                                          },
                                          borderRadius: BorderRadius.circular(15),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                employee.profileImage != null
                                                    ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: Image.network(
                                                    employee.profileImage!,
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) =>
                                                        Icon(Icons.person, size: 80, color: Colors.grey),
                                                  ),
                                                )
                                                    : Container(
                                                  width: 80,
                                                  height: 80,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(10),
                                                    color: Colors.grey[200],
                                                  ),
                                                  child: const Icon(Icons.person, size: 40, color: Colors.grey),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  _selectedLanguage == 'ar'
                                                      ? employee.fullNameAr ?? 'غير متوفر'
                                                      : employee.fullNameFr ?? 'Non disponible',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blueAccent,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 4),
                                                _buildInfoRow(_selectedLanguage == 'ar' ? 'المعرف' : 'ID', employee.id),
                                                _buildInfoRow(
                                                    _selectedLanguage == 'ar' ? 'القسم' : 'Département',
                                                    _selectedLanguage == 'ar'
                                                        ? employee.departmentAr ?? 'غير متوفر'
                                                        : employee.departmentFr ?? 'Non disponible'),
                                                _buildInfoRow(
                                                    _selectedLanguage == 'ar' ? 'القسم الفرعي' : 'Sous-département',
                                                    _selectedLanguage == 'ar'
                                                        ? employee.subDepartmentAr ?? 'غير متوفر'
                                                        : employee.subDepartmentFr ?? 'Non disponible'),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          );
                        }
                        return const Center(child: Text('خطأ في تحميل الموظفين / Erreur lors du chargement des employés'));
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

  void _resetSelectionsIfInvalid() {
    final schoolState = context.read<SchoolCubit>().state;
    if (schoolState is SchoolsLoaded && selectedSchoolId != null) {
      final selectedSchool = schoolState.schools.firstWhere(
            (school) => school.schoolId == selectedSchoolId,
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
      final availableDepartments = selectedSchool.mainSections[_selectedLanguage]!;
      if (selectedDepartment != null && !availableDepartments.contains(selectedDepartment)) {
        selectedDepartment = null;
        selectedSubDepartment = null;
      } else if (selectedDepartment != null && selectedSubDepartment != null) {
        final availableSubDepartments = selectedSchool.subSections[_selectedLanguage]![selectedDepartment]!;
        if (!availableSubDepartments.contains(selectedSubDepartment)) {
          selectedSubDepartment = null;
        }
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blueAccent, width: 2),
          ),
          child: DropdownButton<String>(
            value: value,
            hint: Text('اختر $label / Choisir $label', style: const TextStyle(color: Colors.blueAccent)),
            onChanged: onChanged,
            items: items,
            style: const TextStyle(color: Colors.blueAccent),
            dropdownColor: Colors.white,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
          ),
        ),
      ],
    );
  }
}