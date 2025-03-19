import 'package:equatable/equatable.dart';

class Stats extends Equatable {
  final int totalStudents;
  final int totalTeachers;
  final int totalAccountants;
  final int totalEmployees; // إضافة إجمالي الموظفين
  final int totalSchools;
  final Map<String, int> studentsPerGrade;
  final Map<String, int> studentsPerSchool;
  final Map<String, int> employeesPerSchool; // توزيع الموظفين حسب المدارس
  final Map<String, int> employeesPerDepartment; // توزيع الموظفين حسب الأقسام
  final Map<String, int> employeesPerSubDepartment; // توزيع الموظفين حسب الأقسام الفرعية
  final double studentToTeacherRatio;
  final int presentStudents;
  final int absentStudents;
  final double totalFeesDue;
  final int maleStudents;
  final int femaleStudents;
  final Map<String, Map<String, String>> schoolNames;

  Stats({
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalAccountants,
    required this.totalEmployees, // إضافة معلم
    required this.totalSchools,
    required this.studentsPerGrade,
    required this.studentsPerSchool,
    required this.employeesPerSchool, // إضافة معلم
    required this.employeesPerDepartment, // إضافة معلم
    required this.employeesPerSubDepartment, // إضافة معلم
    required this.presentStudents,
    required this.absentStudents,
    required this.totalFeesDue,
    required this.maleStudents,
    required this.femaleStudents,
    required this.schoolNames,
  }) : studentToTeacherRatio = totalTeachers > 0 ? totalStudents / totalTeachers : 0.0;

  Map<String, dynamic> toJson() => {
    'totalStudents': totalStudents,
    'totalTeachers': totalTeachers,
    'totalAccountants': totalAccountants,
    'totalEmployees': totalEmployees, // إضافة إلى JSON
    'totalSchools': totalSchools,
    'studentsPerGrade': studentsPerGrade,
    'studentsPerSchool': studentsPerSchool,
    'employeesPerSchool': employeesPerSchool, // إضافة إلى JSON
    'employeesPerDepartment': employeesPerDepartment, // إضافة إلى JSON
    'employeesPerSubDepartment': employeesPerSubDepartment, // إضافة إلى JSON
    'studentToTeacherRatio': studentToTeacherRatio,
    'presentStudents': presentStudents,
    'absentStudents': absentStudents,
    'totalFeesDue': totalFeesDue,
    'maleStudents': maleStudents,
    'femaleStudents': femaleStudents,
    'schoolNames': schoolNames,
  };

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
    totalStudents: json['totalStudents'] ?? 0,
    totalTeachers: json['totalTeachers'] ?? 0,
    totalAccountants: json['totalAccountants'] ?? 0,
    totalEmployees: json['totalEmployees'] ?? 0, // إضافة من JSON
    totalSchools: json['totalSchools'] ?? 0,
    studentsPerGrade: Map<String, int>.from(json['studentsPerGrade'] ?? {}),
    studentsPerSchool: Map<String, int>.from(json['studentsPerSchool'] ?? {}),
    employeesPerSchool: Map<String, int>.from(json['employeesPerSchool'] ?? {}), // إضافة من JSON
    employeesPerDepartment: Map<String, int>.from(json['employeesPerDepartment'] ?? {}), // إضافة من JSON
    employeesPerSubDepartment: Map<String, int>.from(json['employeesPerSubDepartment'] ?? {}), // إضافة من JSON
    presentStudents: json['presentStudents'] ?? 0,
    absentStudents: json['absentStudents'] ?? 0,
    totalFeesDue: json['totalFeesDue']?.toDouble() ?? 0.0,
    maleStudents: json['maleStudents'] ?? 0,
    femaleStudents: json['femaleStudents'] ?? 0,
    schoolNames: (json['schoolNames'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, Map<String, String>.from(value)),
    ) ?? {},
  );

  @override
  List<Object> get props => [
    totalStudents,
    totalTeachers,
    totalAccountants,
    totalEmployees, // إضافة إلى props
    totalSchools,
    studentsPerGrade,
    studentsPerSchool,
    employeesPerSchool, // إضافة إلى props
    employeesPerDepartment, // إضافة إلى props
    employeesPerSubDepartment, // إضافة إلى props
    studentToTeacherRatio,
    presentStudents,
    absentStudents,
    totalFeesDue,
    maleStudents,
    femaleStudents,
    schoolNames,
  ];
}