/*import 'package:flutter/material.dart';
//import '../widgets/custom_button.dart';
import '../services/auth_service.dart';
import 'profs/home_screen.dart';
import 'admin/admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  LoginScreen({required this.role});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  void _login() async {
    setState(() => isLoading = true);

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("⚠️ الرجاء إدخال البريد الإلكتروني وكلمة المرور!");
      setState(() => isLoading = false);
      return;
    }

    print("🔄 محاولة تسجيل الدخول بالبريد: $email");

    String? roleFromFirebase = await _authService.signInWithEmailAndRole(email, password);

    setState(() => isLoading = false);

    if (roleFromFirebase != null) {
      if (roleFromFirebase == widget.role) {
        print("✅ تم التحقق من الدور، توجيه المستخدم...");

        Widget nextScreen;
        if (widget.role == "admin") {
          nextScreen = AdminHomeScreen();
        } else if (widget.role == "prof") {
          nextScreen = HomeScreen();
        } else {
          _showError("⚠️ دور غير مدعوم!");
          return;
        }

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => nextScreen));
      } else {
        _showError("⚠️ لا يمكنك تسجيل الدخول بهذا الدور!");
      }
    } else {
      _showError("⚠️ فشل تسجيل الدخول. تحقق من البيانات!");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2E335A), // خلفية داكنة
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40),
                // عنوان الصفحة
                Center(
                  child: Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // أيقونة الدور
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: _getRoleColor(),
                    child: Icon(
                      _getRoleIcon(),
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 40),
                // حقل البريد
                _buildLoginField(
                  controller: emailController,
                  hint: "Email",
                  icon: Icons.email_outlined,
                ),
                SizedBox(height: 15),
                // حقل كلمة المرور
                _buildLoginField(
                  controller: passwordController,
                  hint: "Password",
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                SizedBox(height: 15),
                // زر نسيت كلمة المرور
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Color.fromARGB(232, 2, 196, 34), // اللون الأخضر
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                // زر تسجيل الدخول
                isLoading
                    ? Center(child: CircularProgressIndicator(color: Colors.white))
                    : Container(
                        height: 55,
                        decoration: BoxDecoration(
                          color: Color.fromARGB(213, 230, 122, 0), // البرتقالي
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextButton(
                          onPressed: _login,
                          child: Text(
                            "LOGIN",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                SizedBox(height: 30),
                // رابط إنشاء حساب
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "Sign up",
                        style: TextStyle(
                          color: Color.fromARGB(232, 2, 196, 34), // اللون الأخضر
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // لون الدور المحدد
  Color _getRoleColor() {
    switch (widget.role) {
      case "admin":
        return Color.fromARGB(213, 230, 122, 0); // البرتقالي
      case "prof":
        return Color.fromARGB(255, 33, 150, 243); // الأزرق
      case "parent":
        return Color.fromARGB(255, 255, 193, 7); // الأصفر
      default:
        return Color.fromARGB(232, 2, 196, 34); // الأخضر
    }
  }

  // أيقونة الدور المحدد
  IconData _getRoleIcon() {
    switch (widget.role) {
      case "admin":
        return Icons.admin_panel_settings;
      case "prof":
        return Icons.school;
      case "parent":
        return Icons.family_restroom;
      default:
        return Icons.person;
    }
  }

  // حقل إدخال مخصص
  Widget _buildLoginField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            SizedBox(width: 15),
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: isPassword,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/