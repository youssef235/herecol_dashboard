import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/Employee/EmployeeCubit.dart';
import '../../models/employee_model.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  final Employee employee;
  final String schoolId;

  const EmployeeDetailsScreen({required this.employee, required this.schoolId});

  @override
  _EmployeeDetailsScreenState createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _fullNameArController;
  late TextEditingController _fullNameFrController;
  late TextEditingController _phoneController;
  bool _isEditing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<String> _selectedPermissions = [];

  static const Map<String, String> availablePermissions = {
    'StatsScreen': 'الإحصائيات / Statistiques',
    'SchoolInfoScreen': 'معلومات المدرسة / Informations sur l’école',
    'AddSchoolScreen': 'إضافة مدرسة / Ajouter une école',
    'AddStudentScreen': 'إضافة طالب / Ajouter un étudiant',
    'StudentListScreen': 'قائمة الطلاب / Liste des étudiants',
    'AttendanceManagementScreen': 'إدارة الحضور والغياب / Gestion des présences',
    'FeesManagementScreen': 'إدارة المصاريف / Gestion des frais',
    'LatePaymentsScreen': 'الطلاب المتأخرون عن الدفع / Étudiants en retard',
    'AccountingManagementScreen': 'إدارة المحاسبة / Gestion de la comptabilité',
    'EmployeeListWithFilterScreen': 'قائمة الموظفين / Liste des employés',
    'AddEmployeeScreen': 'إضافة موظف / Ajouter un employé',
    'SalaryCategoriesScreen': 'فئات الرواتب / Catégories de salaires',
    'SalaryTrackingScreen': 'تتبع دفع الرواتب / Suivi des paiements de salaire',
    'ParentListScreen': 'قائمة أولياء الأمور / Liste des parents',
    'AddParentScreen': 'إضافة ولي أمر / Ajouter un parent',
  };

  @override
  void initState() {
    super.initState();
    _fullNameArController = TextEditingController(text: widget.employee.fullNameAr);
    _fullNameFrController = TextEditingController(text: widget.employee.fullNameFr);
    _phoneController = TextEditingController(text: widget.employee.phone);
    _selectedPermissions = widget.employee.permissions;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  void _togglePermission(String permission) {
    setState(() {
      if (_selectedPermissions.contains(permission)) {
        _selectedPermissions.remove(permission);
      } else {
        _selectedPermissions.add(permission);
      }
    });
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() {
    final updatedEmployee = widget.employee.copyWith(
      fullNameAr: _fullNameArController.text,
      fullNameFr: _fullNameFrController.text,
      phone: _phoneController.text,
      permissions: _selectedPermissions,
    );
    context.read<EmployeeCubit>().updateEmployee(updatedEmployee, widget.schoolId);
    setState(() {
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم تحديث البيانات بنجاح'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteEmployee() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white.withOpacity(0.95),
        elevation: 10,
        contentPadding: const EdgeInsets.all(20),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'تأكيد الحذف',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.blueAccent,
              ),
            ),
            Text(
              'Confirmation de suppression',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'هل أنت متأكد من حذف هذا الموظف؟\n',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: 'Êtes-vous sûr de supprimer cet employé ?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cancel, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إلغاء',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Annuler',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<EmployeeCubit>().deleteEmployee(widget.employee.id, widget.schoolId);
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'تم حذف الموظف بنجاح\n',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: 'Employé supprimé avec succès',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  backgroundColor: Colors.red.shade700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(10),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_forever, size: 20, color: Colors.red),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حذف',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Supprimer',
                      style: TextStyle(
                        color: Colors.red.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blueAccent,
        title: const Text(
          'تفاصيل الموظف / Détails de l’employé',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _isEditing ? Icons.save : Icons.edit,
                key: ValueKey(_isEditing),
                color: Colors.white,
              ),
            ),
            onPressed: _isEditing ? _saveChanges : _toggleEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _deleteEmployee,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent.shade700, Colors.blue.shade100],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Hero(
                    tag: 'employee_${widget.employee.id}',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage: widget.employee.profileImage != null
                              ? NetworkImage(widget.employee.profileImage!)
                              : null,
                          child: widget.employee.profileImage == null
                              ? const Icon(Icons.person, size: 60, color: Colors.blueAccent)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('ID', widget.employee.id),
                        const SizedBox(height: 16),
                        _buildEditableField(
                          controller: _fullNameArController,
                          label: 'الاسم الكامل (عربي)',
                          enabled: _isEditing,
                        ),
                        const SizedBox(height: 12),
                        _buildEditableField(
                          controller: _fullNameFrController,
                          label: 'Nom complet (français)',
                          enabled: _isEditing,
                        ),
                        const SizedBox(height: 12),
                        _buildEditableField(
                          controller: _phoneController,
                          label: 'رقم الهاتف / Numéro de téléphone',
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow(
                          'القسم / Département',
                          '${widget.employee.departmentAr} / ${widget.employee.departmentFr}',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'القسم الفرعي / Sous-département',
                          '${widget.employee.subDepartmentAr} / ${widget.employee.subDepartmentFr}',
                        ),
                        const SizedBox(height: 8),
          
                        _buildPermissionsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildPermissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان القسم مع تأثير انتقالي
        FadeTransition(
          opacity: _fadeAnimation,
          child: const Text(
            'الصلاحيات / Permissions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // استخدام ListView للتمرير إذا كانت القائمة طويلة
        Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: availablePermissions.length,
            itemBuilder: (context, index) {
              final entry = availablePermissions.entries.elementAt(index);
              final isSelected = _selectedPermissions.contains(entry.key);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: GestureDetector(
                  onTap: _isEditing
                      ? () => _togglePermission(entry.key)
                      : null, // تعطيل التفاعل إذا لم يكن في وضع التعديل
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSelected
                            ? [Colors.blueAccent.shade400, Colors.blue.shade700]
                            : [Colors.grey.shade200, Colors.grey.shade300],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    child: Row(
                      children: [
                        // أيقونة ديناميكية تتغير حسب الحالة
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected ? Colors.white : Colors.grey.shade600,
                            size: 24,
                            key: ValueKey(isSelected),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // النص مع دعم اللغتين
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 16,
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        // مؤشر تفاعلي عند التعديل
                        if (_isEditing)
                          Icon(
                            Icons.touch_app,
                            color: Colors.white.withOpacity(0.7),
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blueAccent),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
      style: const TextStyle(fontSize: 16, color: Colors.black87),
    );
  }

  @override
  void dispose() {
    _fullNameArController.dispose();
    _fullNameFrController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}