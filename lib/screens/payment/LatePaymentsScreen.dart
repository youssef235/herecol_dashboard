import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_dashboard/screens/payment/StudentPaymentsScreen.dart';
import '../../cubit/auth/auth_cubit.dart';
import '../../cubit/auth/auth_state.dart';

class LatePaymentsScreen extends StatefulWidget {
  final String? schoolId; // قد يكون null للسوبر أدمن
  final String role; // دور المستخدم: 'admin' أو 'school' أو 'employee'

  const LatePaymentsScreen({required this.schoolId, required this.role});

  @override
  _LatePaymentsScreenState createState() => _LatePaymentsScreenState();
}

class _LatePaymentsScreenState extends State<LatePaymentsScreen> {
  String? selectedSchoolId;
  String _selectedLanguage = 'ar'; // اللغة الافتراضية: العربية

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      if (authState.role == 'school') {
        selectedSchoolId = widget.schoolId ?? authState.uid;
      } else if (authState.role == 'employee') {
        selectedSchoolId = authState.schoolId;
      }
      // للسوبر أدمن، يتم اختيار المدرسة يدويًا من القائمة المنسدلة
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return Scaffold(
        body: Center(
          child: Text(
            _selectedLanguage == 'ar' ? 'يرجى تسجيل الدخول' : 'Veuillez vous connecter',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedLanguage == 'ar'
              ? 'الطلاب المتأخرون عن الدفع'
              : 'Étudiants en retard de paiement',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: _selectedLanguage,
              icon: const Icon(Icons.language, color: Colors.white),
              dropdownColor: Colors.blueAccent,
              underline: const SizedBox(),
              items: [
                DropdownMenuItem(
                  value: 'ar',
                  child: Text('العربية', style: TextStyle(color: Colors.white)),
                ),
                DropdownMenuItem(
                  value: 'fr',
                  child: Text('Français', style: TextStyle(color: Colors.white)),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
              },
            ),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (authState.role == 'admin') ...[
                _buildSchoolDropdown(),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: _buildStudentsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('schools').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              _selectedLanguage == 'ar' ? 'لا توجد مدارس متاحة' : 'Aucune école disponible',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final schools = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'schoolName': data['schoolName'][_selectedLanguage] ?? (_selectedLanguage == 'ar' ? 'مدرسة بدون اسم' : 'École sans nom'),
          };
        }).toList();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 3,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            decoration: _buildInputDecoration(
              _selectedLanguage == 'ar' ? 'اختر المدرسة' : 'Choisir l’école',
            ),
            value: selectedSchoolId,
            items: schools.map<DropdownMenuItem<String>>((school) {
              return DropdownMenuItem<String>(
                value: school['id'],
                child: Text(school['schoolName']!, style: const TextStyle(color: Colors.blueAccent)),
              );
            }).toList(),
            onChanged: (schoolId) {
              setState(() {
                selectedSchoolId = schoolId;
              });
            },
            hint: Text(
              _selectedLanguage == 'ar' ? 'اختر مدرسة' : 'Choisir une école',
              style: const TextStyle(color: Colors.grey),
            ),
            style: const TextStyle(color: Colors.blueAccent),
            dropdownColor: Colors.white,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
          ),
        );
      },
    );
  }

  Widget _buildStudentsList() {
    if (selectedSchoolId == null) {
      return Center(
        child: Text(
          _selectedLanguage == 'ar' ? 'يرجى اختيار مدرسة' : 'Veuillez choisir une école',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(selectedSchoolId)
          .collection('students')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              _selectedLanguage == 'ar' ? 'لا يوجد طلاب في هذه المدرسة' : 'Aucun étudiant dans cette école',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final students = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'firstNameAr': data['firstNameAr'] ?? 'غير معروف',
            'firstNameFr': data['firstNameFr'] ?? 'Inconnu',
            'lastNameAr': data['lastNameAr'] ?? 'غير معروف',
            'lastNameFr': data['lastNameFr'] ?? 'Inconnu',
            'feesDue': (data['feesDue'] ?? 0.0).toDouble(),
            'feesPaid': (data['feesPaid'] ?? 0.0).toDouble(),
          };
        }).toList();

        final lateStudents = students.where((student) => student['feesDue'] > student['feesPaid']).toList();

        if (lateStudents.isEmpty) {
          return Center(
            child: Text(
              _selectedLanguage == 'ar' ? 'لا يوجد طلاب متأخرون عن الدفع' : 'Aucun étudiant en retard de paiement',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: lateStudents.length,
          itemBuilder: (context, index) {
            final student = lateStudents[index];
            final feesDue = student['feesDue'] as double;
            final feesPaid = student['feesPaid'] as double;

            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  _selectedLanguage == 'ar'
                      ? '${student['firstNameAr']} ${student['lastNameAr']}'
                      : '${student['firstNameFr']} ${student['lastNameFr']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _selectedLanguage == 'ar'
                        ? 'المستحق: $feesDue | المدفوع: $feesPaid'
                        : 'Dû: $feesDue | Payé: $feesPaid',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
                trailing: const Icon(Icons.warning, color: Colors.red),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentPaymentsScreen(
                        schoolId: selectedSchoolId!,
                        studentId: student['id'] as String,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.blueAccent),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.blueAccent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }
}