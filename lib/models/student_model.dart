class Student {
  final String id;
  final String firstNameAr;
  final String firstNameFr;
  final String lastNameAr;
  final String lastNameFr;
  final String gradeAr; // الصف بالعربية
  final String gradeFr; // الصف بالفرنسية
  final String sectionAr; // الشعبة بالعربية
  final String sectionFr; // الشعبة بالفرنسية
  final String? categoryAr; // الفئة بالعربية
  final String? categoryFr; // الفئة بالفرنسية
  final String birthDate;
  final String phone;
  final String? email;
  final String addressAr; // العنوان بالعربية
  final String? addressFr; // العنوان بالفرنسية
  final String academicYear; // سنة الالتحاق كاملة (مثل 2025-2026)
  final String schoolId;
  final String admissionDate;
  final String birthPlaceAr; // مكان الميلاد بالعربية
  final String? birthPlaceFr; // مكان الميلاد بالفرنسية
  final String? profileImage;
  final String? ministryFileNumber;
  final String? genderAr; // الجنس بالعربية
  final String? genderFr; // الجنس بالفرنسية
  final Map<String, String>? attendanceHistory;
  final double? feesDue;
  final double? feesPaid;

  Student({
    required this.id,
    required this.firstNameAr,
    required this.firstNameFr,
    required this.lastNameAr,
    required this.lastNameFr,
    required this.gradeAr,
    required this.gradeFr,
    required this.sectionAr,
    required this.sectionFr,
    this.categoryAr,
    this.categoryFr,
    required this.birthDate,
    required this.phone,
    this.email,
    required this.addressAr,
    this.addressFr,
    required this.academicYear,
    required this.schoolId,
    required this.admissionDate,
    required this.birthPlaceAr,
    this.birthPlaceFr,
    this.profileImage,
    this.ministryFileNumber,
    this.genderAr,
    this.genderFr,
    this.attendanceHistory,
    this.feesDue,
    this.feesPaid,
  });

  factory Student.fromFirestore(Map<String, dynamic> data, String id) {
    return Student(
      id: id,
      firstNameAr: data['firstNameAr'] ?? '',
      firstNameFr: data['firstNameFr'] ?? '',
      lastNameAr: data['lastNameAr'] ?? '',
      lastNameFr: data['lastNameFr'] ?? '',
      gradeAr: data['gradeAr'] ?? '',
      gradeFr: data['gradeFr'] ?? '',
      sectionAr: data['sectionAr'] ?? '',
      sectionFr: data['sectionFr'] ?? '',
      categoryAr: data['categoryAr'],
      categoryFr: data['categoryFr'],
      birthDate: data['birthDate'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      addressAr: data['addressAr'] ?? '',
      addressFr: data['addressFr'],
      academicYear: data['academicYear'] ?? '',
      schoolId: data['schoolId'] ?? '',
      admissionDate: data['admissionDate'] ?? '',
      birthPlaceAr: data['birthPlaceAr'] ?? '',
      birthPlaceFr: data['birthPlaceFr'],
      profileImage: data['profileImage'],
      ministryFileNumber: data['ministryFileNumber'],
      genderAr: data['genderAr'],
      genderFr: data['genderFr'],
      attendanceHistory: (data['attendanceHistory'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as String),
      ),
      feesDue: (data['feesDue'] as num?)?.toDouble(),
      feesPaid: (data['feesPaid'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'firstNameAr': firstNameAr,
      'firstNameFr': firstNameFr,
      'lastNameAr': lastNameAr,
      'lastNameFr': lastNameFr,
      'gradeAr': gradeAr,
      'gradeFr': gradeFr,
      'sectionAr': sectionAr,
      'sectionFr': sectionFr,
      'categoryAr': categoryAr,
      'categoryFr': categoryFr,
      'birthDate': birthDate,
      'phone': phone,
      'email': email,
      'addressAr': addressAr,
      'addressFr': addressFr,
      'academicYear': academicYear,
      'schoolId': schoolId,
      'admissionDate': admissionDate,
      'birthPlaceAr': birthPlaceAr,
      'birthPlaceFr': birthPlaceFr,
      'profileImage': profileImage,
      'ministryFileNumber': ministryFileNumber,
      'genderAr': genderAr,
      'genderFr': genderFr,
      'attendanceHistory': attendanceHistory ?? {},
      'feesDue': feesDue,
      'feesPaid': feesPaid,
    };
  }
}