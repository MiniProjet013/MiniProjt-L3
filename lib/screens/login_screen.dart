import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';
import 'profs/home_screen.dart'; // ✅ واجهة الأستاذ
import 'admin/admin_home_screen.dart'; // ✅ واجهة الإدارة

class LoginScreen extends StatefulWidget {
  final String role; // ✅ تحديد الدور القادم من شاشة اختيار الدور

  LoginScreen({required this.role});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  /// ✅ التحقق من بيانات تسجيل الدخول
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

        // ✅ تحديد الصفحة بناءً على الدور
        Widget nextScreen;
        if (widget.role == "admin") {
          nextScreen = AdminHomeScreen(); // ✅ توجيه للإدارة
        } else if (widget.role == "prof") {
          nextScreen = HomeScreen(); // ✅ توجيه للأستاذ
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

  /// ✅ عرض رسالة خطأ
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ✅ الجزء العلوي (تصميم ثابت)
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(232, 2, 196, 34), // ✅ اللون الأخضر
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(100),
                      bottomRight: Radius.circular(100),
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 50, color: Color.fromARGB(232, 2, 196, 34)),
                ),
              ],
            ),
            SizedBox(height: 40),

            // ✅ إدخال البريد وكلمة المرور مع الحفاظ على التصميم الأصلي
            CustomTextField(
              label: "Email",
              icon: Icons.person,
              controller: emailController,
            ),
            SizedBox(height: 15),
            CustomTextField(
              label: "Mot de passe",
              icon: Icons.lock,
              isPassword: true,
              controller: passwordController,
            ),
            SizedBox(height: 25),

            isLoading
                ? CircularProgressIndicator()
                : CustomButton(
                    text: "SE CONNECTER",
                    onPressed: _login,
                  ),

            SizedBox(height: 10),

            TextButton(
              onPressed: () {},
              child: Text("Mot de passe oublié?", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
