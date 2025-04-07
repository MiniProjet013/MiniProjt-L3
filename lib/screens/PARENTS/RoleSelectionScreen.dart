import 'package:flutter/material.dart';
import '../login_screen.dart';
import 'parent_home_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ✅ الجزء العلوي (تم تكبيره واستبدال الأيقونة)
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 250, // ✅ زيادة الارتفاع
                decoration: BoxDecoration(
                  color: Color.fromARGB(232, 2, 196, 34), // ✅ اللون الأخضر
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(100),
                    bottomRight: Radius.circular(100),
                  ),
                ),
              ),
              Icon(
                Icons.school, // ✅ أيقونة المدرسة
                size: 80,
                color: Colors.white,
              ),
            ],
          ),

          SizedBox(height: 40), // ✅ رفع الأزرار قليلاً للأعلى

          // ✅ نص "Choose your option"
          Text(
            "Choose your option",
            style: TextStyle(
              fontSize: 22, // ✅ تكبير الخط
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(213, 230, 122, 0), // ✅ اللون البرتقالي
            ),
          ),
          SizedBox(height: 20),

          // ✅ أزرار الأدوار (تم رفعها للأعلى قليلاً)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRoleButton(
                      context,
                      title: "Admin",
                      icon: Icons.admin_panel_settings,
                      role: "admin",
                    ),
                    _buildRoleButton(
                      context,
                      title: "Prof",
                      icon: Icons.person_outline,
                      role: "prof",
                    ),
                  ],
                ),
                SizedBox(height: 20),
                _buildRoleButton(
                  context,
                  title: "Parent",
                  icon: Icons.family_restroom,
                  role: "parent",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ دالة لإنشاء زر الدور
  Widget _buildRoleButton(BuildContext context, {required String title, required IconData icon, required String role}) {
    return GestureDetector(
      onTap: () {
        if (role == "parent") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ParentHomeScreen()));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen(role: role)));
        }
      },
      child: Container(
        width: 150, // ✅ تكبير الأزرار
        height: 130,
        decoration: BoxDecoration(
          color: Color.fromARGB(213, 230, 122, 0), // ✅ اللون البرتقالي
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 3))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 45), // ✅ تكبير الأيقونة
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), // ✅ تكبير النص
            ),
          ],
        ),
      ),
    );
  }
}
