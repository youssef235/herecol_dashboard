class Employee {
  final String id;
  final String fullNameAr; // الاسم الكامل بالعربية
  final String fullNameFr; // الاسم الكامل بالفرنسية
  final String genderAr; // الجنس بالعربية
  final String genderFr; // الجنس بالفرنسية
  final String birthDate; // تاريخ الميلاد
  final String phone; // رقم الهاتف
  final String? secondaryPhone; // رقم الهاتف الاحتياطي (اختياري)
  final String email; // البريد الإلكتروني
  final String addressAr; // العنوان بالعربية
  final String addressFr; // العنوان بالفرنسية
  final String? profileImage; // رابط صورة الملف الشخصي (اختياري)
  final String departmentAr; // القسم الرئيسي بالعربية
  final String subDepartmentAr; // القسم الفرعي بالعربية
  final String departmentFr; // القسم الرئيسي بالفرنسية
  final String subDepartmentFr; // القسم الفرعي بالفرنسية
  final String role; // دور الموظف (مثل accounting, teacher)
  final List<String> permissions; // الصلاحيات
  final String? salaryCategoryId;
  final String schoolId; // إضافة حقل schoolId

  Employee({
    required this.id,
    required this.fullNameAr,
    required this.fullNameFr,
    required this.genderAr,
    required this.genderFr,
    required this.birthDate,
    required this.phone,
    this.secondaryPhone,
    this.salaryCategoryId,
    required this.email,
    required this.addressAr,
    required this.addressFr,
    this.profileImage,
    required this.departmentAr,
    required this.subDepartmentAr,
    required this.departmentFr,
    required this.subDepartmentFr,
    required this.role,
    required this.permissions,
    required this.schoolId, // إضافة schoolId كمعلم مطلوب
  });

  // تحويل البيانات من Firestore إلى كائن Employee
  factory Employee.fromMap(Map<String, dynamic> data, String id) {
    return Employee(
      id: id,
      fullNameAr: data['fullNameAr'] ?? '',
      fullNameFr: data['fullNameFr'] ?? '',
      genderAr: data['genderAr'] ?? '',
      genderFr: data['genderFr'] ?? '',
      birthDate: data['birthDate'] ?? '',
      phone: data['phone'] ?? '',
      secondaryPhone: data['secondaryPhone'],
      email: data['email'] ?? '',
      salaryCategoryId: data['salaryCategoryId'],
      addressAr: data['addressAr'] ?? '',
      addressFr: data['addressFr'] ?? '',
      profileImage: data['profileImage'],
      departmentAr: data['departmentAr'] ?? '',
      subDepartmentAr: data['subDepartmentAr'] ?? '',
      departmentFr: data['departmentFr'] ?? '',
      subDepartmentFr: data['subDepartmentFr'] ?? '',
      role: data['role'] ?? '',
      permissions: List<String>.from(data['permissions'] ?? []),
      schoolId: data['schoolId'] ?? '', // إضافة schoolId من البيانات
    );
  }

  // تحويل كائن Employee إلى بيانات لـ Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullNameAr': fullNameAr,
      'fullNameFr': fullNameFr,
      'genderAr': genderAr,
      'genderFr': genderFr,
      'birthDate': birthDate,
      'phone': phone,
      'secondaryPhone': secondaryPhone,
      'email': email,
      'salaryCategoryId': salaryCategoryId,
      'addressAr': addressAr,
      'addressFr': addressFr,
      'profileImage': profileImage,
      'departmentAr': departmentAr,
      'subDepartmentAr': subDepartmentAr,
      'departmentFr': departmentFr,
      'subDepartmentFr': subDepartmentFr,
      'role': role,
      'permissions': permissions,
      'schoolId': schoolId, // إضافة schoolId إلى الخريطة
    };
  }
}