import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/parent/parent_cubit.dart';
import '../../cubit/parent/parent_state.dart';
import '../../cubit/student/student_cubit.dart';
import '../../cubit/student/student_state.dart';
import '../../models/parent_model.dart';
import '../../models/student_model.dart';

class ParentDetailsScreen extends StatefulWidget {
  final Parent parent;
  final String schoolId;

  const ParentDetailsScreen({required this.parent, required this.schoolId});

  @override
  _ParentDetailsScreenState createState() => _ParentDetailsScreenState();
}

class _ParentDetailsScreenState extends State<ParentDetailsScreen> {
  late TextEditingController _nameArController;
  late TextEditingController _nameFrController;
  late TextEditingController _phoneController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressArController;
  late TextEditingController _addressFrController;
  late List<String> _studentIds;

  @override
  void initState() {
    super.initState();
    _nameArController = TextEditingController(text: widget.parent.nameAr);
    _nameFrController = TextEditingController(text: widget.parent.nameFr);
    _phoneController = TextEditingController(text: widget.parent.phone);
    _emergencyPhoneController = TextEditingController(text: widget.parent.emergencyPhone);
    _emailController = TextEditingController(text: widget.parent.email ?? '');
    _addressArController = TextEditingController(text: widget.parent.addressAr);
    _addressFrController = TextEditingController(text: widget.parent.addressFr ?? '');
    _studentIds = List.from(widget.parent.studentIds);

    context.read<StudentCubit>().fetchStudents(schoolId: widget.schoolId);
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameFrController.dispose();
    _phoneController.dispose();
    _emergencyPhoneController.dispose();
    _emailController.dispose();
    _addressArController.dispose();
    _addressFrController.dispose();
    super.dispose();
  }

  void _updateParent() {
    final updatedParent = Parent(
      id: widget.parent.id,
      schoolId: widget.schoolId,
      nameAr: _nameArController.text,
      nameFr: _nameFrController.text,
      phone: _phoneController.text,
      emergencyPhone: _emergencyPhoneController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
      addressAr: _addressArController.text,
      addressFr: _addressFrController.text.isEmpty ? null : _addressFrController.text,
      studentIds: _studentIds,
    );

    context.read<ParentCubit>().updateParentFull(
      schoolId: widget.schoolId,
      parentId: widget.parent.id,
      updatedParent: updatedParent,
    );
    Navigator.pop(context);
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('تأكيد الحذف / Confirmer la suppression'),
          content: Text('هل أنت متأكد من حذف ولي الأمر ${widget.parent.nameAr} / ${widget.parent.nameFr ?? widget.parent.nameAr}؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء / Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _deleteParent(context);
              },
              child: const Text('حذف / Supprimer', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteParent(BuildContext context) async {
    try {
      context.read<ParentCubit>().deleteParent(widget.schoolId, widget.parent.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف ولي الأمر بنجاح / Parent supprimé avec succès'),
        ),
      );
      Navigator.pop(context); // العودة إلى القائمة
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في حذف ولي الأمر: $e / Échec de la suppression: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'تفاصيل ولي الأمر / Détails du tuteur',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent, Colors.blueAccent.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                  ),
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModernTextField(_nameArController, 'الاسم (عربي) / Nom (Arabe)', Icons.person),
                    _buildModernTextField(_nameFrController, 'الاسم (فرنسي) / Nom (Français)', Icons.person_outline),
                    _buildModernTextField(_phoneController, 'رقم الهاتف / Téléphone', Icons.phone),
                    _buildModernTextField(_emergencyPhoneController, 'رقم الطوارئ / Téléphone d\'urgence', Icons.phone_in_talk),
                    _buildModernTextField(_emailController, 'البريد الإلكتروني (اختياري) / Email (facultatif)', Icons.email, required: false),
                    _buildModernTextField(_addressArController, 'العنوان (عربي) / Adresse (Arabe)', Icons.location_on),
                    _buildModernTextField(_addressFrController, 'العنوان (فرنسي) (اختياري) / Adresse (Français) (facultatif)', Icons.location_city, required: false),
                    const SizedBox(height: 24),
                    Text(
                      'الطلاب المرتبطون / Étudiants liés',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent.shade700,
                        shadows: [Shadow(color: Colors.grey.shade300, blurRadius: 2)],
                      ),
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<StudentCubit, StudentState>(
                      builder: (context, studentState) {
                        if (studentState is StudentsLoaded) {
                          final students = studentState.students;
                          if (students.isEmpty) {
                            return _buildEmptyState('لا يوجد طلاب متاحون / Aucun étudiant disponible');
                          }
                          return Column(
                            children: students.map((student) => _buildModernCheckboxTile(student)).toList(),
                          );
                        } else if (studentState is StudentError) {
                          return _buildEmptyState('خطأ في جلب الطلاب: ${studentState.message} / Erreur lors du chargement des étudiants: ${studentState.message}');
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _updateParent,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 5,
                              shadowColor: Colors.black45,
                            ),
                            child: const Text(
                              'حفظ التغييرات / Sauvegarder',
                              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () => _confirmDelete(context),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 5,
                              shadowColor: Colors.black45,
                            ),
                            child: const Text(
                              'حذف / Supprimer',
                              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField(TextEditingController controller, String label, IconData icon, {bool required = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blueAccent.shade700, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          ),
          errorText: required && controller.text.isEmpty ? 'هذا الحقل مطلوب / Ce champ est requis' : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }

  Widget _buildModernCheckboxTile(Student student) {
    final isSelected = _studentIds.contains(student.id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _studentIds.remove(student.id);
            } else {
              _studentIds.add(student.id);
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.blueAccent : Colors.transparent,
                  border: Border.all(color: isSelected ? Colors.blueAccent : Colors.grey.shade400, width: 2),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${student.firstNameAr} ${student.lastNameAr}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الصف / Classe: ${student.gradeAr}',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Text(
        message,
        style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
      ),
    );
  }
}