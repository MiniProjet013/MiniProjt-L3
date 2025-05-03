import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/RoleSelectionScreen.dart'; 
import 'screens/splash_screen.dart';
// ✅ إضافة استيراد واجهة اختيار الدور
//import 'screens/login_screen.dart';
import 'package:flutter/foundation.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
   if (kDebugMode) {
    DebugPrintCallback originalPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message?.contains('Ads') ?? false) return;
      originalPrint(message, wrapWidth: wrapWidth);
    };
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestion Scolaire',
      home:  SplashScreen(), // ✅ عرض واجهة اختيار الدور أولاً
    );
  }
}
