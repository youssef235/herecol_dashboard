import 'dart:math';

class Employee {
  final String id;
  final String fullNameAr;
  final String fullNameFr;
  final String genderAr;
  final String genderFr;
  final String birthDate;
  final String phone;
  final String? secondaryPhone;
  final String email;
  final String addressAr;
  final String addressFr;
  final String? profileImage;
  final String departmentAr;
  final String subDepartmentAr;
  final String departmentFr;
  final String subDepartmentFr;
  final String role;
  final List<String> permissions;
  final String? salaryCategoryId;
  final String schoolId;

  Employee({
    String? id,
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
    required this.schoolId,
  }) : id = id ?? _generateUniqueId();

  static String _generateUniqueId() {
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(6);
    String random = (Random().nextInt(9999)).toString().padLeft(4, '0');
    return timestamp + random;
  }

  factory Employee.fromMap(Map<String, dynamic> data, String id) {
    return Employee(
      id: data['id'] ?? id,
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
      schoolId: data['schoolId'] ?? '',
    );
  }

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
      'schoolId': schoolId,
    };
  }

  Employee copyWith({
    String? id,
    String? fullNameAr,
    String? fullNameFr,
    String? genderAr,
    String? genderFr,
    String? birthDate,
    String? phone,
    String? secondaryPhone,
    String? email,
    String? addressAr,
    String? addressFr,
    String? profileImage,
    String? departmentAr,
    String? subDepartmentAr,
    String? departmentFr,
    String? subDepartmentFr,
    String? role,
    List<String>? permissions,
    String? salaryCategoryId,
    String? schoolId,
  }) {
    return Employee(
      id: id ?? this.id,
      fullNameAr: fullNameAr ?? this.fullNameAr,
      fullNameFr: fullNameFr ?? this.fullNameFr,
      genderAr: genderAr ?? this.genderAr,
      genderFr: genderFr ?? this.genderFr,
      birthDate: birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      secondaryPhone: secondaryPhone ?? this.secondaryPhone,
      email: email ?? this.email,
      addressAr: addressAr ?? this.addressAr,
      addressFr: addressFr ?? this.addressFr,
      profileImage: profileImage ?? this.profileImage,
      departmentAr: departmentAr ?? this.departmentAr,
      subDepartmentAr: subDepartmentAr ?? this.subDepartmentAr,
      departmentFr: departmentFr ?? this.departmentFr,
      subDepartmentFr: subDepartmentFr ?? this.subDepartmentFr,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      salaryCategoryId: salaryCategoryId ?? this.salaryCategoryId,
      schoolId: schoolId ?? this.schoolId,
    );
  }
}