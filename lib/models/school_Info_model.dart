class Schoolinfo {
  String schoolId;
  Map<String, String> schoolName;
  Map<String, String> city;
  String email;
  String phone;
  Map<String, String> currency;
  Map<String, String> currencySymbol;
  Map<String, String> address;
  Map<String, List<String>> classes;
  Map<String, Map<String, List<String>>> sections;
  Map<String, List<String>> categories;
  Map<String, List<String>> mainSections; // الأقسام الرئيسية
  Map<String, Map<String, List<String>>> subSections; // الأقسام الفرعية مربوطة بالرئيسية
  String? logoUrl;
  Map<String, String> principalName;
  String? principalSignatureUrl;
  String? ownerId;

  Schoolinfo({
    required this.schoolId,
    required this.schoolName,
    required this.city,
    required this.email,
    required this.phone,
    required this.currency,
    required this.currencySymbol,
    required this.address,
    required this.classes,
    required this.sections,
    required this.categories,
    required this.mainSections,
    required this.subSections,
    this.logoUrl,
    this.principalName = const {'ar': '', 'fr': ''},
    this.principalSignatureUrl,
    this.ownerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'schoolName': schoolName,
      'city': city,
      'email': email,
      'phone': phone,
      'currency': currency,
      'currencySymbol': currencySymbol,
      'address': address,
      'classes': classes,
      'sections': sections.map(
            (lang, classMap) => MapEntry(
          lang,
          classMap.map((key, value) => MapEntry(key, value)),
        ),
      ),
      'categories': categories.map((key, value) => MapEntry(key, value)),
      'mainSections': mainSections,
      'subSections': subSections.map(
            (lang, sectionMap) => MapEntry(
          lang,
          sectionMap.map((key, value) => MapEntry(key, value)),
        ),
      ),
      'logoUrl': logoUrl,
      'principalName': principalName,
      'principalSignatureUrl': principalSignatureUrl,
      'ownerId': ownerId,
    };
  }

  factory Schoolinfo.fromMap(Map<String, dynamic> map) {
    return Schoolinfo(
      schoolId: map['schoolId'] ?? '',
      schoolName: Map<String, String>.from(map['schoolName'] ?? {'ar': '', 'fr': ''}),
      city: Map<String, String>.from(map['city'] ?? {'ar': '', 'fr': ''}),
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      currency: Map<String, String>.from(map['currency'] ?? {'ar': '', 'fr': ''}),
      currencySymbol: Map<String, String>.from(map['currencySymbol'] ?? {'ar': '', 'fr': ''}),
      address: Map<String, String>.from(map['address'] ?? {'ar': '', 'fr': ''}),
      classes: (map['classes'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, List<String>.from(value ?? [])),
      ) ?? {'ar': [], 'fr': []},
      sections: (map['sections'] as Map<String, dynamic>?)?.map(
            (lang, classMap) => MapEntry(
          lang,
          (classMap as Map<String, dynamic>).map(
                (key, value) => MapEntry(key, List<String>.from(value ?? [])),
          ),
        ),
      ) ?? {'ar': {}, 'fr': {}},
      categories: (map['categories'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, List<String>.from(value ?? [])),
      ) ?? {'ar': [], 'fr': []},
      mainSections: (map['mainSections'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, List<String>.from(value ?? [])),
      ) ?? {'ar': [], 'fr': []},
      subSections: (map['subSections'] as Map<String, dynamic>?)?.map(
            (lang, sectionMap) => MapEntry(
          lang,
          (sectionMap as Map<String, dynamic>).map(
                (key, value) => MapEntry(key, List<String>.from(value ?? [])),
          ),
        ),
      ) ?? {'ar': {}, 'fr': {}},
      logoUrl: map['logoUrl'],
      principalName: Map<String, String>.from(map['principalName'] ?? {'ar': '', 'fr': ''}),
      principalSignatureUrl: map['principalSignatureUrl'],
      ownerId: map['ownerId'],
    );
  }
}