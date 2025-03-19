// تعريف الحالات الأساسية لـ AuthCubit مع دعم إدارة الصلاحيات ومعرف المدرسة
abstract class AuthState {}

// الحالة الافتراضية عند بدء تشغيل التطبيق
class AuthInitial extends AuthState {}

// الحالة أثناء تحميل البيانات (مثل تسجيل الدخول أو التسجيل)
class AuthLoading extends AuthState {}

// الحالة عندما يتم التحقق من هوية المستخدم بنجاح
class AuthAuthenticated extends AuthState {
  final String role; // دور المستخدم: admin, school, employee
  final String uid; // معرف المستخدم الفريد من Firebase Authentication
  final String? email; // البريد الإلكتروني للمستخدم (اختياري، لتتبع البريد)
  final String? schoolId; // معرف المدرسة المرتبطة بالمستخدم (للموظفين أو مدير المدرسة)
  final List<String> permissions; // قائمة الصلاحيات للموظفين

  AuthAuthenticated({
    required this.role,
    required this.uid,
    this.email,
    this.schoolId,
    this.permissions = const [], // قيمة افتراضية: قائمة فارغة إذا لم تُحدد صلاحيات
  });
}

// الحالة عند تسجيل الخروج أو عدم وجود مستخدم مسجل
class AuthUnauthenticated extends AuthState {}

// الحالة عند حدوث خطأ (مثل فشل تسجيل الدخول أو التسجيل)
class AuthError extends AuthState {
  final String message; // رسالة الخطأ لعرضها للمستخدم

  AuthError(this.message);
}