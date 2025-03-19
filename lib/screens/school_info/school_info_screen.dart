import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../cubit/school_info/school_info_cubit.dart';
import '../../cubit/school_info/school_info_state.dart';
import '../../cubit/auth/auth_cubit.dart';
import '../../cubit/auth/auth_state.dart';
import '../../models/school_info_model.dart';
import 'dart:developer' as developer;

class SchoolInfoScreen extends StatefulWidget {
  @override
  _SchoolInfoScreenState createState() => _SchoolInfoScreenState();
}

class _SchoolInfoScreenState extends State<SchoolInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedSchoolId;
  List<Schoolinfo> schools = [];
  Schoolinfo? selectedSchool;

  // Arabic controllers
  final TextEditingController _schoolNameArController = TextEditingController();
  final TextEditingController _cityArController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _currencyArController = TextEditingController();
  final TextEditingController _currencySymbolArController = TextEditingController();
  final TextEditingController _addressArController = TextEditingController();
  final TextEditingController _principalNameArController = TextEditingController();

  // French controllers
  final TextEditingController _schoolNameFrController = TextEditingController();
  final TextEditingController _cityFrController = TextEditingController();
  final TextEditingController _currencyFrController = TextEditingController();
  final TextEditingController _currencySymbolFrController = TextEditingController();
  final TextEditingController _addressFrController = TextEditingController();
  final TextEditingController _principalNameFrController = TextEditingController();

  // Controllers for user data update
  final TextEditingController _currentEmailController = TextEditingController();
  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  // Categories controllers and lists
  final TextEditingController _categoryControllerAr = TextEditingController();
  final TextEditingController _categoryControllerFr = TextEditingController();
  List<String> _categoriesAr = [];
  List<String> _categoriesFr = [];

  // Classes list
  final List<Map<String, dynamic>> _classes = [];

  // MainSections and SubSections list
  final List<Map<String, dynamic>> _mainSections = [];

  String? _logoUrl;
  String? _principalSignatureUrl;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      developer.log('InitState: Role=${authState.role}, UID=${authState.uid}, SchoolId=${authState.schoolId}');
      if (authState.role == 'school') {
        selectedSchoolId = authState.uid;
        context.read<SchoolCubit>().fetchSchools(authState.uid, authState.role);
      } else if (authState.role == 'employee') {
        selectedSchoolId = authState.schoolId;
        if (selectedSchoolId != null) {
          context.read<SchoolCubit>().fetchSchools(selectedSchoolId!, 'school');
        }
      } else if (authState.role == 'admin') {
        context.read<SchoolCubit>().fetchSchools(authState.uid, authState.role);
      }
      _currentEmailController.text = authState.email ?? '';
    } else {
      developer.log('InitState: No authenticated user');
    }
  }

  void _onSchoolSelected(String? schoolId) {
    if (schoolId == null || schools.isEmpty) return;

    setState(() {
      selectedSchoolId = schoolId;
      selectedSchool = schools.firstWhere((school) => school.schoolId == schoolId);

      developer.log('Selected school: ${selectedSchool!.schoolName}');
      _schoolNameArController.text = selectedSchool!.schoolName['ar'] ?? '';
      _schoolNameFrController.text = selectedSchool!.schoolName['fr'] ?? '';
      _cityArController.text = selectedSchool!.city['ar'] ?? '';
      _cityFrController.text = selectedSchool!.city['fr'] ?? '';
      _emailController.text = selectedSchool!.email;
      _phoneController.text = selectedSchool!.phone;
      _currencyArController.text = selectedSchool!.currency['ar'] ?? '';
      _currencyFrController.text = selectedSchool!.currency['fr'] ?? '';
      _currencySymbolArController.text = selectedSchool!.currencySymbol['ar'] ?? '';
      _currencySymbolFrController.text = selectedSchool!.currencySymbol['fr'] ?? '';
      _addressArController.text = selectedSchool!.address['ar'] ?? '';
      _addressFrController.text = selectedSchool!.address['fr'] ?? '';
      _principalNameArController.text = selectedSchool!.principalName['ar'] ?? '';
      _principalNameFrController.text = selectedSchool!.principalName['fr'] ?? '';
      _logoUrl = selectedSchool!.logoUrl;
      _principalSignatureUrl = selectedSchool!.principalSignatureUrl;

      _classes.clear();
      final arClasses = selectedSchool!.classes['ar'] ?? [];
      final frClasses = selectedSchool!.classes['fr'] ?? [];
      for (int i = 0; i < arClasses.length; i++) {
        _classes.add({
          'classNameAr': arClasses[i],
          'classNameFr': frClasses[i],
          'sectionControllerAr': TextEditingController(),
          'sectionControllerFr': TextEditingController(),
          'sectionsAr': List<String>.from(selectedSchool!.sections['ar']?[arClasses[i]] ?? []),
          'sectionsFr': List<String>.from(selectedSchool!.sections['fr']?[frClasses[i]] ?? []),
        });
      }

      _categoriesAr = List<String>.from(selectedSchool!.categories['ar'] ?? []);
      _categoriesFr = List<String>.from(selectedSchool!.categories['fr'] ?? []);

      _mainSections.clear();
      final arMainSections = selectedSchool!.mainSections['ar'] ?? [];
      final frMainSections = selectedSchool!.mainSections['fr'] ?? [];
      for (int i = 0; i < arMainSections.length; i++) {
        _mainSections.add({
          'mainSectionNameAr': arMainSections[i],
          'mainSectionNameFr': frMainSections[i],
          'subSectionControllerAr': TextEditingController(),
          'subSectionControllerFr': TextEditingController(),
          'subSectionsAr': List<String>.from(selectedSchool!.subSections['ar']?[arMainSections[i]] ?? []),
          'subSectionsFr': List<String>.from(selectedSchool!.subSections['fr']?[frMainSections[i]] ?? []),
        });
      }
    });
  }

  Future<void> _pickImage(String type) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final File file = File(image.path);
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference storageRef = FirebaseStorage.instance.ref().child('school_$type/$fileName.jpg');
      try {
        await storageRef.putFile(file);
        final String downloadURL = await storageRef.getDownloadURL();
        setState(() {
          if (type == 'logo') _logoUrl = downloadURL;
          else if (type == 'signature') _principalSignatureUrl = downloadURL;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec du téléchargement de l\'image : $e / فشل تحميل الصورة: $e')),
        );
      }
    }
  }

  void _addClass() {
    setState(() {
      _classes.add({
        'classNameAr': '',
        'classNameFr': '',
        'sectionControllerAr': TextEditingController(),
        'sectionControllerFr': TextEditingController(),
        'sectionsAr': <String>[],
        'sectionsFr': <String>[],
      });
    });
  }

  void _addSection(int classIndex, String lang) {
    final controller = lang == 'ar'
        ? _classes[classIndex]['sectionControllerAr']
        : _classes[classIndex]['sectionControllerFr'];
    final sections = lang == 'ar'
        ? _classes[classIndex]['sectionsAr']
        : _classes[classIndex]['sectionsFr'];
    final sectionText = controller.text.trim();
    if (sectionText.isNotEmpty && !sections.contains(sectionText)) {
      setState(() {
        sections.add(sectionText);
        controller.clear();
      });
    }
  }

  void _removeClass(int index) {
    setState(() {
      _classes.removeAt(index);
    });
  }

  void _removeSection(int classIndex, String section, String lang) {
    setState(() {
      if (lang == 'ar') {
        _classes[classIndex]['sectionsAr'].remove(section);
      } else {
        _classes[classIndex]['sectionsFr'].remove(section);
      }
    });
  }

  void _addCategory(String lang) {
    final controller = lang == 'ar' ? _categoryControllerAr : _categoryControllerFr;
    final categories = lang == 'ar' ? _categoriesAr : _categoriesFr;
    final categoryText = controller.text.trim();
    if (categoryText.isNotEmpty && !categories.contains(categoryText)) {
      setState(() {
        categories.add(categoryText);
        controller.clear();
      });
    }
  }

  void _removeCategory(String category, String lang) {
    setState(() {
      if (lang == 'ar') {
        _categoriesAr.remove(category);
      } else {
        _categoriesFr.remove(category);
      }
    });
  }

  void _addMainSection() {
    setState(() {
      _mainSections.add({
        'mainSectionNameAr': '',
        'mainSectionNameFr': '',
        'subSectionControllerAr': TextEditingController(),
        'subSectionControllerFr': TextEditingController(),
        'subSectionsAr': <String>[],
        'subSectionsFr': <String>[],
      });
    });
  }

  void _addSubSection(int sectionIndex, String lang) {
    final controller = lang == 'ar'
        ? _mainSections[sectionIndex]['subSectionControllerAr']
        : _mainSections[sectionIndex]['subSectionControllerFr'];
    final subSections = lang == 'ar'
        ? _mainSections[sectionIndex]['subSectionsAr']
        : _mainSections[sectionIndex]['subSectionsFr'];
    final subSectionText = controller.text.trim();
    if (subSectionText.isNotEmpty && !subSections.contains(subSectionText)) {
      setState(() {
        subSections.add(subSectionText);
        controller.clear();
      });
    }
  }

  void _removeMainSection(int index) {
    setState(() {
      _mainSections.removeAt(index);
    });
  }

  void _removeSubSection(int sectionIndex, String subSection, String lang) {
    setState(() {
      if (lang == 'ar') {
        _mainSections[sectionIndex]['subSectionsAr'].remove(subSection);
      } else {
        _mainSections[sectionIndex]['subSectionsFr'].remove(subSection);
      }
    });
  }

  void _saveSchool() {
    if (_formKey.currentState!.validate()) {
      if (_classes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Vous devez ajouter au moins une classe / يجب إضافة فصل واحد على الأقل")),
        );
        return;
      }

      for (var classData in _classes) {
        if (classData['classNameAr'].isEmpty || classData['classNameFr'].isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Vous devez entrer un nom pour chaque classe dans les deux langues / يجب إدخال اسم لكل فصل باللغتين")),
          );
          return;
        }
        if (classData['sectionsAr'].isEmpty || classData['sectionsFr'].isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Chaque classe doit contenir au moins une section dans les deux langues / يجب أن يحتوي كل فصل على قسم واحد على الأقل باللغتين")),
          );
          return;
        }
      }

      for (var sectionData in _mainSections) {
        if (sectionData['mainSectionNameAr'].isEmpty || sectionData['mainSectionNameFr'].isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Vous devez entrer un nom pour chaque section principale dans les deux langues / يجب إدخال اسم لكل قسم رئيسي باللغتين")),
          );
          return;
        }
      }

      final authState = context.read<AuthCubit>().state;
      if (selectedSchool == null || authState is! AuthAuthenticated) return;

      final updatedSchool = Schoolinfo(
        schoolId: selectedSchoolId!,
        schoolName: {
          'ar': _schoolNameArController.text,
          'fr': _schoolNameFrController.text,
        },
        city: {
          'ar': _cityArController.text,
          'fr': _cityFrController.text,
        },
        email: _emailController.text,
        phone: _phoneController.text,
        currency: {
          'ar': _currencyArController.text,
          'fr': _currencyFrController.text,
        },
        currencySymbol: {
          'ar': _currencySymbolArController.text,
          'fr': _currencySymbolFrController.text,
        },
        address: {
          'ar': _addressArController.text,
          'fr': _addressFrController.text,
        },
        classes: {
          'ar': _classes.map((c) => c['classNameAr'] as String).toList(),
          'fr': _classes.map((c) => c['classNameFr'] as String).toList(),
        },
        sections: {
          'ar': {for (var c in _classes) c['classNameAr']: c['sectionsAr']},
          'fr': {for (var c in _classes) c['classNameFr']: c['sectionsFr']},
        },
        categories: {
          'ar': _categoriesAr,
          'fr': _categoriesFr,
        },
        mainSections: {
          'ar': _mainSections.map((m) => m['mainSectionNameAr'] as String).toList(),
          'fr': _mainSections.map((m) => m['mainSectionNameFr'] as String).toList(),
        },
        subSections: {
          'ar': {for (var m in _mainSections) m['mainSectionNameAr']: m['subSectionsAr']},
          'fr': {for (var m in _mainSections) m['mainSectionNameFr']: m['subSectionsFr']},
        },
        logoUrl: _logoUrl,
        principalName: {
          'ar': _principalNameArController.text,
          'fr': _principalNameFrController.text,
        },
        principalSignatureUrl: _principalSignatureUrl,
        ownerId: selectedSchool!.ownerId,
      );

      context.read<SchoolCubit>().addSchool(updatedSchool, authState.uid, authState.role);
    }
  }

  void _showUpdateUserDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تحديث بيانات المستخدم / Update User Data'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentEmailController,
                decoration: InputDecoration(labelText: 'البريد الإلكتروني الحالي / Current Email'),
                enabled: false,
              ),
              TextField(
                controller: _newEmailController,
                decoration: InputDecoration(labelText: 'البريد الإلكتروني الجديد / New Email'),
              ),
              TextField(
                controller: _currentPasswordController,
                decoration: InputDecoration(labelText: 'كلمة المرور الحالية / Current Password'),
                obscureText: true,
              ),
              TextField(
                controller: _newPasswordController,
                decoration: InputDecoration(labelText: 'كلمة المرور الجديدة / New Password'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء / Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final authState = context.read<AuthCubit>().state as AuthAuthenticated;
              if (_newEmailController.text.isNotEmpty) {
                await context.read<AuthCubit>().updateEmail(
                  currentEmail: _currentEmailController.text,
                  currentPassword: _currentPasswordController.text,
                  newEmail: _newEmailController.text,
                );
                _currentEmailController.text = _newEmailController.text;
                _newEmailController.clear();
              }
              if (_newPasswordController.text.isNotEmpty) {
                await context.read<AuthCubit>().updatePassword(
                  currentPassword: _currentPasswordController.text,
                  newPassword: _newPasswordController.text,
                );
                _newPasswordController.clear();
              }
              _currentPasswordController.clear();
              Navigator.pop(context);
            },
            child: Text('تحديث / Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isAdmin = authState is AuthAuthenticated && authState.role == 'admin';

    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: Colors.blueAccent,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'إدارة معلومات المدرسة / Gestion des informations de l\'école',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blueAccent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.person, color: Colors.white),
              onPressed: _showUpdateUserDataDialog,
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
          child: BlocListener<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              } else if (state is AuthAuthenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم التحديث بنجاح / Updated successfully')),
                );
                _currentEmailController.text = state.email ?? '';
              }
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: BlocListener<SchoolCubit, SchoolState>(
                listener: (context, state) {
                  if (state is SchoolsLoaded) {
                    setState(() {
                      schools = state.schools;
                      developer.log('Schools loaded: ${schools.length}');
                      if (authState is AuthAuthenticated && schools.isNotEmpty) {
                        // استدعاء _onSchoolSelected دائمًا لضمان تحديث الواجهة
                        if (authState.role == 'school') {
                          _onSchoolSelected(authState.uid);
                        } else if (authState.role == 'employee') {
                          _onSchoolSelected(authState.schoolId);
                        } else if (authState.role == 'admin' && selectedSchoolId == null) {
                          _onSchoolSelected(schools.first.schoolId);
                        }
                      }
                    });
                  } else if (state is SchoolAdded) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("تم حفظ معلومات المدرسة / Les informations de l'école ont été enregistrées")),
                    );
                  } else if (state is SchoolError) {
                    developer.log('School error: ${state.message}');
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                  }
                },
                child: BlocBuilder<SchoolCubit, SchoolState>(
                  builder: (context, state) {
                    developer.log('BlocBuilder state: ${state.runtimeType}');
                    if (state is SchoolLoading || state is SchoolsLoading) {
                      return Center(child: CircularProgressIndicator());
                    } else if (state is SchoolsLoaded) {
                      schools = state.schools;
                      if (schools.isEmpty) {
                        return Center(child: Text("لا توجد بيانات للمدارس / Aucune donnée pour les écoles"));
                      }
                      return Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isAdmin) ...[
                              Center(child: _buildSectionTitle('اختيار مدرسة / Choisir une école')),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.blueAccent, width: 2),
                                      ),
                                      child: DropdownButton<String>(
                                        value: selectedSchoolId,
                                        hint: Center(
                                          child: Text(
                                            "اختيار مدرسة / Choisir une école",
                                            style: TextStyle(color: Colors.blueAccent),
                                          ),
                                        ),
                                        onChanged: _onSchoolSelected,
                                        items: schools.map((school) {
                                          return DropdownMenuItem(
                                            value: school.schoolId,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  "${school.schoolName['fr'] ?? ''} - ${school.schoolName['ar'] ?? ''}",
                                                  style: TextStyle(color: Colors.blueAccent),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        style: TextStyle(color: Colors.blueAccent),
                                        dropdownColor: Colors.white,
                                        isExpanded: true,
                                        underline: SizedBox(),
                                        icon: Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),
                            ] else if (selectedSchoolId != null && schools.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'المدرسة: ${schools.firstWhere((s) => s.schoolId == selectedSchoolId).schoolName['ar']} / ${schools.firstWhere((s) => s.schoolId == selectedSchoolId).schoolName['fr']}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                ),
                              ),
                              SizedBox(height: 16),
                            ],
                            if (selectedSchoolId != null && schools.isNotEmpty) ...[
                              Container(
                                padding: EdgeInsets.all(16),
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
                                    _buildSectionTitle('معلومات مشتركة / Informations communes'),
                                    _buildTextField(label: 'E-mail / البريد الإلكتروني', controller: _emailController),
                                    SizedBox(height: 12),
                                    _buildTextField(label: 'Numéro de téléphone / رقم الهاتف', controller: _phoneController),
                                    SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildImagePicker(label: 'Logo / الشعار', imageUrl: _logoUrl, onTap: () => _pickImage('logo'), size: 120),
                                        _buildImagePicker(label: 'Signature / التوقيع', imageUrl: _principalSignatureUrl, onTap: () => _pickImage('signature'), size: 120),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 24),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(16),
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
                                          _buildSectionTitle('Informations en français'),
                                          _buildTextField(label: 'Nom de l’école', controller: _schoolNameFrController),
                                          SizedBox(height: 12),
                                          _buildTextField(label: 'Ville', controller: _cityFrController),
                                          SizedBox(height: 12),
                                          _buildTextField(label: 'Devise utilisée', controller: _currencyFrController),
                                          SizedBox(height: 12),
                                          _buildTextField(label: 'Symbole de la devise', controller: _currencySymbolFrController),
                                          SizedBox(height: 12),
                                          _buildTextField(label: 'Adresse', controller: _addressFrController),
                                          SizedBox(height: 12),
                                          _buildTextField(label: 'Nom du directeur', controller: _principalNameFrController),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(16),
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
                                          _buildSectionTitle('معلومات بالعربية'),
                                          _buildTextField(label: 'اسم المدرسة', controller: _schoolNameArController, textDirection: TextDirection.rtl),
                                          SizedBox(height: 12),
                                          _buildTextField(label: 'المدينة', controller: _cityArController, textDirection: TextDirection.rtl),
                                          SizedBox(height: 12),
                                          _buildTextField(label: 'العملة المستخدمة', controller: _currencyArController, textDirection: TextDirection.rtl),
                                          SizedBox(height: 12),
                                          _buildTextField(label: 'رمز العملة', controller: _currencySymbolArController, textDirection: TextDirection.rtl),
                                          SizedBox(height: 12),
                                          _buildTextField(label: 'العنوان', controller: _addressArController, textDirection: TextDirection.rtl),
                                          SizedBox(height: 12),
                                          _buildTextField(label: 'اسم المدير', controller: _principalNameArController, textDirection: TextDirection.rtl),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),
                              Container(
                                padding: EdgeInsets.all(16),
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
                                    _buildSectionTitle('Classes et sections / الصفوف والأقسام'),
                                    ElevatedButton(
                                      onPressed: _addClass,
                                      child: Text('Ajouter une classe / إضافة صف', style: TextStyle(fontSize: 16)),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.blueAccent,
                                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: _classes.length,
                                      itemBuilder: (context, index) {
                                        var classData = _classes[index];
                                        return Card(
                                          elevation: 4,
                                          color: Colors.white,
                                          margin: EdgeInsets.symmetric(vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          child: Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextFormField(
                                                        decoration: InputDecoration(
                                                          labelText: 'Nom de la classe / اسم الصف',
                                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                          filled: true,
                                                          fillColor: Colors.white,
                                                        ),
                                                        initialValue: classData['classNameFr'],
                                                        onChanged: (value) => setState(() => _classes[index]['classNameFr'] = value),
                                                        validator: (value) => value!.isEmpty ? 'Requis / مطلوب' : null,
                                                      ),
                                                    ),
                                                    SizedBox(width: 16),
                                                    Expanded(
                                                      child: TextFormField(
                                                        decoration: InputDecoration(
                                                          labelText: 'اسم الصف / Nom de la classe',
                                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                          filled: true,
                                                          fillColor: Colors.white,
                                                        ),
                                                        initialValue: classData['classNameAr'],
                                                        textDirection: TextDirection.rtl,
                                                        onChanged: (value) => setState(() => _classes[index]['classNameAr'] = value),
                                                        validator: (value) => value!.isEmpty ? 'مطلوب / Requis' : null,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.delete, color: Colors.red),
                                                      onPressed: () => _removeClass(index),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 16),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: TextFormField(
                                                              controller: classData['sectionControllerFr'],
                                                              decoration: InputDecoration(
                                                                labelText: 'Ajouter une section / إضافة قسم',
                                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                                filled: true,
                                                                fillColor: Colors.white,
                                                              ),
                                                              onFieldSubmitted: (value) => _addSection(index, 'fr'),
                                                            ),
                                                          ),
                                                          IconButton(
                                                            icon: Icon(Icons.add, color: Colors.blueAccent),
                                                            onPressed: () => _addSection(index, 'fr'),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(width: 16),
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: TextFormField(
                                                              controller: classData['sectionControllerAr'],
                                                              decoration: InputDecoration(
                                                                labelText: 'إضافة قسم / Ajouter une section',
                                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                                filled: true,
                                                                fillColor: Colors.white,
                                                              ),
                                                              textDirection: TextDirection.rtl,
                                                              onFieldSubmitted: (value) => _addSection(index, 'ar'),
                                                            ),
                                                          ),
                                                          IconButton(
                                                            icon: Icon(Icons.add, color: Colors.blueAccent),
                                                            onPressed: () => _addSection(index, 'ar'),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 12),
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Wrap(
                                                        spacing: 8,
                                                        children: (classData['sectionsFr'] as List<String>).map((section) {
                                                          return Chip(
                                                            label: Text(section),
                                                            deleteIcon: Icon(Icons.close, size: 18),
                                                            onDeleted: () => _removeSection(index, section, 'fr'),
                                                            backgroundColor: Colors.blueAccent.withOpacity(0.2),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),
                                                    SizedBox(width: 16),
                                                    Expanded(
                                                      child: Wrap(
                                                        spacing: 8,
                                                        children: (classData['sectionsAr'] as List<String>).map((section) {
                                                          return Chip(
                                                            label: Text(section),
                                                            deleteIcon: Icon(Icons.close, size: 18),
                                                            onDeleted: () => _removeSection(index, section, 'ar'),
                                                            backgroundColor: Colors.blueAccent.withOpacity(0.2),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),
                                                  ],
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
                              SizedBox(height: 24),
                              Container(
                                padding: EdgeInsets.all(16),
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
                                    _buildSectionTitle('Sections principales / الأقسام الرئيسية'),
                                    ElevatedButton(
                                      onPressed: _addMainSection,
                                      child: Text('Ajouter une section / إضافة قسم رئيسي', style: TextStyle(fontSize: 16)),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.blueAccent,
                                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: _mainSections.length,
                                      itemBuilder: (context, index) {
                                        var sectionData = _mainSections[index];
                                        return Card(
                                          elevation: 4,
                                          color: Colors.white,
                                          margin: EdgeInsets.symmetric(vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          child: Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextFormField(
                                                        decoration: InputDecoration(
                                                          labelText: 'Nom de la section / اسم القسم',
                                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                          filled: true,
                                                          fillColor: Colors.white,
                                                        ),
                                                        initialValue: sectionData['mainSectionNameFr'],
                                                        onChanged: (value) => setState(() => _mainSections[index]['mainSectionNameFr'] = value),
                                                        validator: (value) => value!.isEmpty ? 'Requis / مطلوب' : null,
                                                      ),
                                                    ),
                                                    SizedBox(width: 16),
                                                    Expanded(
                                                      child: TextFormField(
                                                        decoration: InputDecoration(
                                                          labelText: 'اسم القسم / Nom de la section',
                                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                          filled: true,
                                                          fillColor: Colors.white,
                                                        ),
                                                        initialValue: sectionData['mainSectionNameAr'],
                                                        textDirection: TextDirection.rtl,
                                                        onChanged: (value) => setState(() => _mainSections[index]['mainSectionNameAr'] = value),
                                                        validator: (value) => value!.isEmpty ? 'مطلوب / Requis' : null,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.delete, color: Colors.red),
                                                      onPressed: () => _removeMainSection(index),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 16),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: TextFormField(
                                                              controller: sectionData['subSectionControllerFr'],
                                                              decoration: InputDecoration(
                                                                labelText: 'Ajouter une sous-section / إضافة قسم فرعي',
                                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                                filled: true,
                                                                fillColor: Colors.white,
                                                              ),
                                                              onFieldSubmitted: (value) => _addSubSection(index, 'fr'),
                                                            ),
                                                          ),
                                                          IconButton(
                                                            icon: Icon(Icons.add, color: Colors.blueAccent),
                                                            onPressed: () => _addSubSection(index, 'fr'),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(width: 16),
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: TextFormField(
                                                              controller: sectionData['subSectionControllerAr'],
                                                              decoration: InputDecoration(
                                                                labelText: 'إضافة قسم فرعي / Ajouter une sous-section',
                                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                                filled: true,
                                                                fillColor: Colors.white,
                                                              ),
                                                              textDirection: TextDirection.rtl,
                                                              onFieldSubmitted: (value) => _addSubSection(index, 'ar'),
                                                            ),
                                                          ),
                                                          IconButton(
                                                            icon: Icon(Icons.add, color: Colors.blueAccent),
                                                            onPressed: () => _addSubSection(index, 'ar'),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 12),
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Wrap(
                                                        spacing: 8,
                                                        children: (sectionData['subSectionsFr'] as List<String>).map((subSection) {
                                                          return Chip(
                                                            label: Text(subSection),
                                                            deleteIcon: Icon(Icons.close, size: 18),
                                                            onDeleted: () => _removeSubSection(index, subSection, 'fr'),
                                                            backgroundColor: Colors.blueAccent.withOpacity(0.2),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),
                                                    SizedBox(width: 16),
                                                    Expanded(
                                                      child: Wrap(
                                                        spacing: 8,
                                                        children: (sectionData['subSectionsAr'] as List<String>).map((subSection) {
                                                          return Chip(
                                                            label: Text(subSection),
                                                            deleteIcon: Icon(Icons.close, size: 18),
                                                            onDeleted: () => _removeSubSection(index, subSection, 'ar'),
                                                            backgroundColor: Colors.blueAccent.withOpacity(0.2),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),
                                                  ],
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
                              SizedBox(height: 24),
                              Container(
                                padding: EdgeInsets.all(16),
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
                                    _buildSectionTitle('Catégories / الفئات'),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextFormField(
                                                      controller: _categoryControllerFr,
                                                      decoration: InputDecoration(
                                                        labelText: 'Ajouter une catégorie / إضافة فئة',
                                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                        filled: true,
                                                        fillColor: Colors.white,
                                                      ),
                                                      onFieldSubmitted: (value) => _addCategory('fr'),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.add, color: Colors.blueAccent),
                                                    onPressed: () => _addCategory('fr'),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 12),
                                              Wrap(
                                                spacing: 8,
                                                children: _categoriesFr.map((category) {
                                                  return Chip(
                                                    label: Text(category),
                                                    deleteIcon: Icon(Icons.close, size: 18),
                                                    onDeleted: () => _removeCategory(category, 'fr'),
                                                    backgroundColor: Colors.blueAccent.withOpacity(0.2),
                                                  );
                                                }).toList(),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextFormField(
                                                      controller: _categoryControllerAr,
                                                      decoration: InputDecoration(
                                                        labelText: 'إضافة فئة / Ajouter une catégorie',
                                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                        filled: true,
                                                        fillColor: Colors.white,
                                                      ),
                                                      textDirection: TextDirection.rtl,
                                                      onFieldSubmitted: (value) => _addCategory('ar'),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.add, color: Colors.blueAccent),
                                                    onPressed: () => _addCategory('ar'),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 12),
                                              Wrap(
                                                spacing: 8,
                                                children: _categoriesAr.map((category) {
                                                  return Chip(
                                                    label: Text(category),
                                                    deleteIcon: Icon(Icons.close, size: 18),
                                                    onDeleted: () => _removeCategory(category, 'ar'),
                                                    backgroundColor: Colors.blueAccent.withOpacity(0.2),
                                                  );
                                                }).toList(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _saveSchool,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text('Enregistrer / حفظ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.blueAccent,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    elevation: 5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    } else if (state is SchoolError) {
                      return Center(child: Text(state.message));
                    } else {
                      return Center(child: Text("لم يتم العثور على مدرسة / Aucune école trouvée"));
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    TextEditingController? controller,
    bool obscureText = false,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textDirection: textDirection,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      validator: (value) => value!.isEmpty ? (textDirection == TextDirection.rtl ? 'مطلوب' : 'Requis') : null,
    );
  }

  Widget _buildImagePicker({required String label, String? imageUrl, required VoidCallback onTap, double size = 200}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blueAccent, width: 2),
            ),
            child: imageUrl != null
                ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(imageUrl, fit: BoxFit.cover))
                : Icon(Icons.camera_alt, size: 40, color: Colors.grey[500]),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _schoolNameArController.dispose();
    _cityArController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currencyArController.dispose();
    _currencySymbolArController.dispose();
    _addressArController.dispose();
    _principalNameArController.dispose();
    _schoolNameFrController.dispose();
    _cityFrController.dispose();
    _currencyFrController.dispose();
    _currencySymbolFrController.dispose();
    _addressFrController.dispose();
    _principalNameFrController.dispose();
    _currentEmailController.dispose();
    _newEmailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _categoryControllerAr.dispose();
    _categoryControllerFr.dispose();
    for (var classData in _classes) {
      classData['sectionControllerAr'].dispose();
      classData['sectionControllerFr'].dispose();
    }
    for (var sectionData in _mainSections) {
      sectionData['subSectionControllerAr'].dispose();
      sectionData['subSectionControllerFr'].dispose();
    }
    super.dispose();
  }
}