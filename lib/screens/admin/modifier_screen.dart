import 'package:flutter/material.dart';
import '../../widgets/category_card.dart';
import '../../utils/constants.dart';
import 'modifier_classes_screen.dart'; // ✅ importación de pantalla de modificación de clases
import 'ModifierProfsScreen.dart';  // ✅ importación de pantalla de modificación de profesores
import 'eleve_modifier_screen.dart'; // ✅ importación de pantalla de modificación de alumnos
import 'modifier_event.dart';
class ModifierScreen extends StatelessWidget {
  final List<Map<String, dynamic>> options = [
    {
      "title": "CLASSES",
      "icon": Icons.class_,
      "route": ModifierClassesScreen() // ✅ redirección a pantalla de modificación de clases
    },
    {
      "title": "PROFS",
      "icon": Icons.person,
      "route": ModifierProfsScreen() // ✅ redirección a pantalla de modificación de profesores
    },
    {
      "title": "ELEVES",
      "icon": Icons.school,
      "route": EleveModifierScreen() // ✅ redirección a pantalla de modificación de alumnos
    },
    {
      "title": "EVENEMENTS",
      "icon": Icons.event,
      "route": ModifierEvenementsScreen()
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