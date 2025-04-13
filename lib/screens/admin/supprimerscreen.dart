import 'package:flutter/material.dart';
import '../../widgets/category_card.dart';
import '../../utils/constants.dart';
import'supprimer_classe_screen.dart';
class SupprimerScreen extends StatelessWidget {
  final List<Map<String, dynamic>> options = [
    {
      "title": "CLASSES",
      "icon": Icons.class_,
      "route": SupprimerClasseScreen() // إضافة شاشة حذف الأقسام لاحقًا
    },
    {
      "title": "PROFS",
      "icon": Icons.person,
      "route": null // إضافة شاشة حذف الأساتذة لاحقًا
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
        title: Text("Supprimer"),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => options[index]["route"]),
                );
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
