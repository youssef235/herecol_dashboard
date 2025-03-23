class Parent {
  final String id;

  final String schoolId;
  final String nameAr;
  final String nameFr;
  final String phone;
  final String emergencyPhone;
  final String? email;
  final String addressAr;
  final String? addressFr;
  final List<String> studentIds;

  Parent({
    required this.id,
    required this.schoolId,
    required this.nameAr,
    required this.nameFr,
    required this.phone,
    required this.emergencyPhone,
    this.email,
    required this.addressAr,
    this.addressFr,
    required this.studentIds,
  });

  factory Parent.fromFirestore(Map<String, dynamic> data, String id) {
    return Parent(
      id: id,
      schoolId: data['schoolId'] ?? '',
      nameAr: data['nameAr'] ?? '',
      nameFr: data['nameFr'] ?? '',
      phone: data['phone'] ?? '',
      emergencyPhone: data['emergencyPhone'] ?? '',
      email: data['email'],
      addressAr: data['addressAr'] ?? '',
      addressFr: data['addressFr'],
      studentIds: List<String>.from(data['studentIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'schoolId': schoolId,
      'nameAr': nameAr,
      'nameFr': nameFr,
      'phone': phone,
      'emergencyPhone': emergencyPhone,
      'email': email,
      'addressAr': addressAr,
      'addressFr': addressFr,
      'studentIds': studentIds,
    };
  }
}