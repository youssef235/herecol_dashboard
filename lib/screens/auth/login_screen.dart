import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_dashboard/cubit/auth/auth_cubit.dart';
import 'package:school_management_dashboard/cubit/auth/auth_state.dart';
import 'package:school_management_dashboard/screens/stats/stats_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLogoVisible = false; // متغير للتحكم في التأثير الانتقالي

  @override
  void initState() {
    super.initState();
    // تشغيل التأثير الانتقالي بعد تحميل الصفحة مع التحقق من mounted
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) { // التحقق مما إذا كان الكائن لا يزال في الشجرة
        setState(() {
          _isLogoVisible = true;
        });
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent.shade700, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // الشعار مع شكل دائري بسيط
                    AnimatedOpacity(
                      opacity: _isLogoVisible ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 800),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6), // تعديل الحواف حسب الحاجة
                          child: Image.asset(
                            'assets/images/herecol_logo.jpeg',
                            height: 120,
                            width: 120,
                            fit: BoxFit.cover,
                          ),
                        ),

                      ),
                    ),
                    Text(
                      'Bienvenue',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 10)],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Connexion au tableau de bord',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 40),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            _buildTextField(
                              label: 'Adresse e-mail',
                              controller: _emailController,
                              icon: Icons.email,
                              validator: (value) =>
                              value!.isEmpty ? 'L’adresse e-mail est requise' : null,
                            ),
                            SizedBox(height: 20),
                            _buildTextField(
                              label: 'Mot de passe',
                              controller: _passwordController,
                              icon: Icons.lock,
                              obscureText: true,
                              validator: (value) =>
                              value!.isEmpty ? 'Le mot de passe est requis' : null,
                            ),
                            SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<AuthCubit>().login(
                                      _emailController.text.trim(),
                                      _passwordController.text.trim(),
                                    );
                                  }
                                },
                                child: Text(
                                  'Se connecter',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.blueAccent.shade400,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 5,
                                  shadowColor: Colors.blueAccent.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

void main() {
  runApp(MaterialApp(
    home: LoginScreen(),
  ));
}