/*import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  Color _appBarColor = Colors.purple; // ✅ اللون الافتراضي للـ AppBar
  Color _iconColor = Colors.purpleAccent; // ✅ اللون الافتراضي للأيقونات

  Color get appBarColor => _appBarColor;
  Color get iconColor => _iconColor;

  // ✅ تحميل الألوان المحفوظة عند بدء التطبيق
  Future<void> loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    int? savedAppBarColor = prefs.getInt('appBarColor');
    int? savedIconColor = prefs.getInt('iconColor');

    if (savedAppBarColor != null) {
      _appBarColor = Color(savedAppBarColor);
    }
    if (savedIconColor != null) {
      _iconColor = Color(savedIconColor);
    }

    notifyListeners();
  }

  // ✅ تحديث الألوان وحفظها في `SharedPreferences`
  Future<void> updateTheme(Color appBar, Color icon) async {
    _appBarColor = appBar;
    _iconColor = icon;
    notifyListeners();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('appBarColor', appBar.value);
    await prefs.setInt('iconColor', icon.value);
  }
}*/
