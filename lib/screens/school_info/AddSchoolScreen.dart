import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../cubit/school_info/school_info_cubit.dart';
import '../../cubit/school_info/school_info_state.dart';
import '../../cubit/auth/auth_cubit.dart';
import '../../cubit/auth/auth_state.dart';
import '../../models/school_info_model.dart';

class AddSchoolScreen extends StatefulWidget {
  @override
  _AddSchoolScreenState createState() => _AddSchoolScreenState();
}

class _AddSchoolScreenState extends State<AddSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  // Arabic controllers
  final _schoolNameArController = TextEditingController();
  final _cityArController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currencyArController = TextEditingController();
  final _currencySymbolArController = TextEditingController();
  final _addressArController = TextEditingController();
  final _principalNameArController = TextEditingController();
  final _passwordController = TextEditingController();

  // French controllers
  final _schoolNameFrController = TextEditingController();
  final _cityFrController = TextEditingController();
  final _currencyFrController = TextEditingController();
  final _currencySymbolFrController = TextEditingController();
  final _addressFrController = TextEditingController();
  final _principalNameFrController = TextEditingController();

  // Categories controllers and lists
  final _categoryControllerAr = TextEditingController();
  final _categoryControllerFr = TextEditingController();
  final List<String> _categoriesAr = [];
  final List<String> _categoriesFr = [];

  // Classes lists
  final List<Map<String, dynamic>> _classes = [];

  // Main Sections and Subsections
  final List<Map<String, dynamic>> _mainSections = []; // قائمة الأقسام الرئيسية مع الأقسام الفرعية

  String? _logoUrl;
  String? _principalSignatureUrl;

  Future<void> _pickImage(String type) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final File file = File(image.path);
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference storageRef =
      FirebaseStorage.instance.ref().child('school_$type/$fileName.jpg');
      try {
        await storageRef.putFile(file);
        final String downloadURL = await storageRef.getDownloadURL();
        setState(() {
          if (type == 'logo') _logoUrl = downloadURL;
          else if (type == 'signature') _principalSignatureUrl = downloadURL;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec du téléchargement de l’image : $e')),
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

  // Main Section and Subsection Logic
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

  void _addSubSection(int mainSectionIndex, String lang) {
    final controller = lang == 'ar'
        ? _mainSections[mainSectionIndex]['subSectionControllerAr']
        : _mainSections[mainSectionIndex]['subSectionControllerFr'];
    final subSections = lang == 'ar'
        ? _mainSections[mainSectionIndex]['subSectionsAr']
        : _mainSections[mainSectionIndex]['subSectionsFr'];
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

  void _removeSubSection(int mainSectionIndex, String subSection, String lang) {
    setState(() {
      if (lang == 'ar') {
        _mainSections[mainSectionIndex]['subSectionsAr'].remove(subSection);
      } else {
        _mainSections[mainSectionIndex]['subSectionsFr'].remove(subSection);
      }
    });
  }

  Future<void> _saveSchool() async {
    if (_formKey.currentState!.validate()) {
      if (_classes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Vous devez ajouter au moins une classe / يجب إضافة فصل واحد على الأقل")),
        );
        return;
      }

      if (_mainSections.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Vous devez ajouter au moins une section principale / يجب إضافة قسم رئيسي واحد على الأقل")),
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

      for (var mainSection in _mainSections) {
        if (mainSection['mainSectionNameAr'].isEmpty || mainSection['mainSectionNameFr'].isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Vous devez entrer un nom pour chaque section principale dans les deux langues / يجب إدخال اسم لكل قسم رئيسي باللغتين")),
          );
          return;
        }
        if (mainSection['subSectionsAr'].isEmpty || mainSection['subSectionsFr'].isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Chaque section principale doit contenir au moins une sous-section dans les deux langues / يجب أن يحتوي كل قسم رئيسي على قسم فرعي واحد على الأقل باللغتين")),
          );
          return;
        }
      }

      setState(() {
        isLoading = true;
      });

      try {
        final schoolInfo = Schoolinfo(
          schoolId: '',
          schoolName: {'ar': _schoolNameArController.text, 'fr': _schoolNameFrController.text},
          city: {'ar': _cityArController.text, 'fr': _cityFrController.text},
          email: _emailController.text,
          phone: _phoneController.text,
          currency: {'ar': _currencyArController.text, 'fr': _currencyFrController.text},
          currencySymbol: {'ar': _currencySymbolArController.text, 'fr': _currencySymbolFrController.text},
          address: {'ar': _addressArController.text, 'fr': _addressFrController.text},
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
          principalName: {'ar': _principalNameArController.text, 'fr': _principalNameFrController.text},
          principalSignatureUrl: _principalSignatureUrl,
        );

        final authCubit = context.read<AuthCubit>();
        await authCubit.addSchoolWithoutLogin(_emailController.text, _passwordController.text, schoolInfo);

        setState(() {
          isLoading = false;
        });
        _clearForm();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("L'école a été ajoutée avec succès / تمت إضافة المدرسة بنجاح")),
        );
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de l'ajout de l'école / خطأ أثناء إضافة المدرسة: $e")),
        );
      }
    }
  }
  void _clearForm() {
    _schoolNameArController.clear();
    _schoolNameFrController.clear();
    _cityArController.clear();
    _cityFrController.clear();
    _emailController.clear();
    _phoneController.clear();
    _currencyArController.clear();
    _currencyFrController.clear();
    _currencySymbolArController.clear();
    _currencySymbolFrController.clear();
    _addressArController.clear();
    _principalNameArController.clear();
    _principalNameFrController.clear();
    _passwordController.clear();
    setState(() {
      _logoUrl = null;
      _principalSignatureUrl = null;
      _classes.clear();
      _categoriesAr.clear();
      _categoriesFr.clear();
      _mainSections.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إضافة مدرسة جديدة / Ajouter une nouvelle école', style: TextStyle(color: Colors.white)),
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
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              setState(() {
                isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        _buildTextField(label: 'Mot de passe / كلمة المرور', controller: _passwordController, obscureText: true),
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
                        _buildSectionTitle('Sections principales et secondaires / الأقسام الرئيسية والفرعية'),
                        ElevatedButton(
                          onPressed: _addMainSection,
                          child: Text('Ajouter une section principale / إضافة قسم رئيسي', style: TextStyle(fontSize: 16)),
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
                            var mainSectionData = _mainSections[index];
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
                                              labelText: 'Nom de la section principale / اسم القسم الرئيسي',
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                              filled: true,
                                              fillColor: Colors.white,
                                            ),
                                            initialValue: mainSectionData['mainSectionNameFr'],
                                            onChanged: (value) => setState(() => _mainSections[index]['mainSectionNameFr'] = value),
                                            validator: (value) => value!.isEmpty ? 'Requis / مطلوب' : null,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: TextFormField(
                                            decoration: InputDecoration(
                                              labelText: 'اسم القسم الرئيسي / Nom de la section principale',
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                              filled: true,
                                              fillColor: Colors.white,
                                            ),
                                            initialValue: mainSectionData['mainSectionNameAr'],
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
                                                  controller: mainSectionData['subSectionControllerFr'],
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
                                                  controller: mainSectionData['subSectionControllerAr'],
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
                                            children: (mainSectionData['subSectionsFr'] as List<String>).map((subSection) {
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
                                            children: (mainSectionData['subSectionsAr'] as List<String>).map((subSection) {
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _saveSchool,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Enregistrer / حفظ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
}