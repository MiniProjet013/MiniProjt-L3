import 'package:flutter/material.dart';
import '../../widgets/category_card.dart'; // ✅ استخدام نفس تصميم الأيقونات
import 'ajouter_eleve_screen.dart';
import 'ajouter_classe_screen.dart';
import 'ajouter_prof_screen.dart';

class AjouterUtilisateurScreen extends StatelessWidget {
  final List<Map<String, dynamic>> options = [
    {
      "title": "Ajouter un élève",
      "icon": Icons.person_add, // 🔹 أيقونة تلميذ
      "route": AjouterEleveScreen()
    },
    {
      "title": "Ajouter une classe",
      "icon": Icons.class_, // 🔹 أيقونة قسم
      "route": AjouterClasseScreen()
    },
    {
      "title": "Ajouter un professeur",
      "icon": Icons.school, // 🔹 أيقونة أستاذ
      "route": AjouterProfScreen()
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Text("Ajouter un utilisateur")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // ✅ عرض عنصرين في كل صف
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
