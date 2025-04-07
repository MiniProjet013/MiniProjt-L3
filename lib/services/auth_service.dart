import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> signInWithEmailAndRole(String email, String password) async {
    try {
      // ✅ تسجيل الدخول باستخدام Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
        // ✅ البحث في مجموعة `profs` (للأساتذة)
      QuerySnapshot profSnapshot = await _db
          .collection('profs')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (profSnapshot.docs.isNotEmpty) {
        print("✅ تسجيل دخول كأستاذ (Prof)");
        return "prof"; // ✅ إرجاع "prof"
      }
      // ✅ التأكد من أن المستخدم موجود في Firestore
      QuerySnapshot snapshot = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String role = snapshot.docs.first['role'];
        print("تم تسجيل الدخول بنجاح، الدور: $role");
        return role;
      } else {
        print("المستخدم غير مسجل في Firestore");
        return null;
      }
    } catch (e) {
      print("خطأ في تسجيل الدخول: $e");
      return null;
    }
  }
  }
