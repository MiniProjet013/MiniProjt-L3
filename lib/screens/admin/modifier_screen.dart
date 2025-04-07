import 'package:flutter/material.dart';
import '../../widgets/category_card.dart';
import '../../utils/constants.dart';
import 'modifier_classes_screen.dart'; // ✅ استيراد شاشة تعديل الأقسام
import 'ModifierProfsScreen.dart';  // ✅ استيراد شاشة تعديل الأساتذة

class ModifierScreen extends StatelessWidget {
  final List<Map<String, dynamic>> options = [
    {
      "title": "CLASSES",
      "icon": Icons.class_,
      "route": ModifierClassesScreen() // ✅ توجيه إلى شاشة تعديل الأقسام
    },
    {
      "title": "PROFS",
      "icon": Icons.person,
      "route": ModifierProfsScreen() // ✅ توجيه إلى شاشة تعديل الأساتذة
    },
    {
      "title": "ELEVES",
      "icon": Icons.school,
      "route": null
    },
    {
      "title": "EVENEMENTS",
      "icon": Icons.event,
      "route": null
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text("Modifier"),
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.2,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                if (options[index]["route"] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => options[index]["route"],
                    ),
                  );
                } else {
                  print("${options[index]['title']} Modifier action executed");
                }
              },
              child: CategoryCard(
                title: options[index]['title'],
                icon: options[index]['icon'],
              ),
            );
          },
        ),
      ),
    );
  }
}
